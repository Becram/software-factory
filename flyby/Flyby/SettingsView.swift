import EventKit
import SwiftUI

/// Settings window: choose which calendars trigger bird reminders.
struct SettingsView: View {
    let monitor: CalendarMonitor

    var body: some View {
        Form {
            if monitor.availableCalendars.isEmpty {
                Text("No calendars found. Grant calendar access, then add accounts in System Settings → Internet Accounts.")
            } else {
                ForEach(groupedCalendars, id: \.source) { group in
                    Section(group.source) {
                        ForEach(group.calendars, id: \.calendarIdentifier) { calendar in
                            Toggle(isOn: binding(for: calendar)) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(cgColor: calendar.cgColor ?? CGColor(gray: 0.5, alpha: 1)))
                                        .frame(width: 10, height: 10)
                                    Text(calendar.title)
                                }
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 380)
        .onAppear { monitor.refresh() }
    }

    /// Calendars grouped by account (Google, iCloud, …), sorted for stable display.
    private var groupedCalendars: [(source: String, calendars: [EKCalendar])] {
        Dictionary(grouping: monitor.availableCalendars) { $0.source?.title ?? "Other" }
            .map { (source: $0.key, calendars: $0.value.sorted { $0.title < $1.title }) }
            .sorted { $0.source < $1.source }
    }

    private func binding(for calendar: EKCalendar) -> Binding<Bool> {
        Binding(
            get: { monitor.isEnabled(calendar) },
            set: { monitor.setEnabled($0, for: calendar) }
        )
    }
}
