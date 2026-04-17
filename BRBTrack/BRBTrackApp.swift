import AppKit
import SwiftUI

// MARK: - App entry point (pure SwiftUI, no AppDelegate needed)

@main
struct BRBTrackApp: App {
    init() {
        BundledFontRegistration.register()
    }

    var body: some Scene {
        // MenuBarExtra is the modern macOS 13+ API for menu-bar–only apps.
        // The .window style drops a panel below the icon, similar to NSPopover.
        MenuBarExtra {
            ContentView()
        } label: {
            Image(systemName: "door.left.hand.open")
                .font(.system(size: 17, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .accessibilityLabel("BRB Track")
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Quit BRB Track") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
    }
}
