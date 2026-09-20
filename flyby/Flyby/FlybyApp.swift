import SwiftUI

@main struct FlybyApp: App {
    @State private var monitor: CalendarMonitor

    init() {
        let monitor = CalendarMonitor()
        _monitor = State(initialValue: monitor)
        Task { await monitor.start() }
    }

    var body: some Scene {
        // Menu bar only — no Dock icon, no main window (LSUIElement is set in Info.plist).
        MenuBarExtra("Bird Reminders", systemImage: "bird.fill") {
            ContentView(monitor: monitor)
        }

        Settings {
            SettingsView(monitor: monitor)
        }
    }
}
