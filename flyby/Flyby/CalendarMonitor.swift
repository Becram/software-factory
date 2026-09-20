import AppKit
import EventKit
import Observation

/// Watches the calendar (including Google accounts synced via macOS Calendar)
/// and triggers a bird flyby 5 minutes before each event starts.
@MainActor
@Observable
final class CalendarMonitor {
    enum Status {
        case starting
        case denied
        case active
    }

    /// How long before an event's start the reminder fires.
    static let leadTime: TimeInterval = 5 * 60

    private static let excludedCalendarsDefaultsKey = "excludedCalendarIDs"

    private let store = EKEventStore()
    private var flybyTimers: [String: Timer] = [:]
    private var refreshTimer: Timer?
    private(set) var status: Status = .starting
    private(set) var upcoming: [EKEvent] = []
    private(set) var availableCalendars: [EKCalendar] = []

    /// Calendars the user switched off in Settings; everything else is watched.
    private var excludedCalendarIDs: Set<String> = Set(
        UserDefaults.standard.stringArray(forKey: CalendarMonitor.excludedCalendarsDefaultsKey) ?? []
    )

    var statusMessage: String {
        switch status {
        case .starting: "Requesting calendar access…"
        case .denied: "Calendar access denied — enable in System Settings → Privacy & Security → Calendars"
        case .active: "Watching your calendar"
        }
    }

    func start() async {
        let granted = (try? await store.requestFullAccessToEvents()) ?? false
        guard granted else {
            status = .denied
            return
        }
        status = .active
        refresh()

        // Reschedule whenever the calendar database changes (new/edited/deleted events).
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: store, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }

        // Safety net: refresh periodically so the 24h lookahead window rolls forward.
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
    }

    func refresh() {
        availableCalendars = store.calendars(for: .event)
        let activeCalendars = availableCalendars.filter { isEnabled($0) }

        let now = Date()
        let windowEnd = now.addingTimeInterval(24 * 60 * 60)
        let events: [EKEvent]
        if activeCalendars.isEmpty {
            events = []
        } else {
            let predicate = store.predicateForEvents(withStart: now, end: windowEnd, calendars: activeCalendars)
            events = store.events(matching: predicate)
                .filter { !$0.isAllDay }
                .sorted { $0.startDate < $1.startDate }
        }
        upcoming = events

        // Drop timers for events that were removed or moved.
        let validKeys = Set(events.map { Self.occurrenceKey(for: $0) })
        for (key, timer) in flybyTimers where !validKeys.contains(key) {
            timer.invalidate()
            flybyTimers[key] = nil
        }

        // Schedule a flyby at (start − leadTime) for each new occurrence.
        for event in events {
            let key = Self.occurrenceKey(for: event)
            guard flybyTimers[key] == nil else { continue }
            let fireDate = event.startDate.addingTimeInterval(-Self.leadTime)
            guard fireDate > now else { continue }

            let title = event.title ?? "Upcoming event"
            let timer = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    BirdFlyby.show(message: "\(title) — in 5 minutes")
                    self?.flybyTimers[key] = nil
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            flybyTimers[key] = timer
        }
    }

    // MARK: Calendar selection

    func isEnabled(_ calendar: EKCalendar) -> Bool {
        !excludedCalendarIDs.contains(calendar.calendarIdentifier)
    }

    func setEnabled(_ enabled: Bool, for calendar: EKCalendar) {
        if enabled {
            excludedCalendarIDs.remove(calendar.calendarIdentifier)
        } else {
            excludedCalendarIDs.insert(calendar.calendarIdentifier)
        }
        UserDefaults.standard.set(
            Array(excludedCalendarIDs), forKey: Self.excludedCalendarsDefaultsKey
        )
        refresh()
    }

    /// Unique per occurrence: recurring events share an identifier, so include the start date.
    private static func occurrenceKey(for event: EKEvent) -> String {
        "\(event.eventIdentifier ?? "unknown")-\(event.startDate.timeIntervalSince1970)"
    }
}
