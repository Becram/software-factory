import AppKit
import SwiftUI

/// Presents a full-screen, transparent, click-through overlay window
/// and flies the bird banner across it.
@MainActor
enum BirdFlyby {
    private static var activePanels: [NSPanel] = []

    static func show(message: String) {
        // screens.first is always the primary display (the one with the menu bar
        // in System Settings → Displays), unlike .main which follows keyboard focus.
        guard let screen = NSScreen.screens.first else { return }

        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .screenSaver
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        let banner = BirdBannerView(message: message) {
            panel.orderOut(nil)
            activePanels.removeAll { $0 === panel }
        }
        panel.contentView = NSHostingView(rootView: banner)
        panel.orderFrontRegardless()
        activePanels.append(panel)
    }
}
