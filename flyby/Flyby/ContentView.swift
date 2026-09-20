import EventKit
import SwiftUI

/// Content of the menu bar dropdown.
struct ContentView: View {
    let monitor: CalendarMonitor

    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Text(monitor.statusMessage)

        if let next = monitor.upcoming.first {
            Text("Next: \(next.title ?? "Untitled") — \(next.startDate.formatted(date: .abbreviated, time: .shortened))")
        }

        Divider()

        Button("Test Flyby") {
            BirdFlyby.show(message: "This is your reminder — in 5 minutes")
        }

        Button("Settings…") {
            // Accessory (menu bar only) apps need explicit activation
            // so the settings window comes to the front.
            NSApplication.shared.activate(ignoringOtherApps: true)
            openSettings()
        }
        .keyboardShortcut(",")

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
