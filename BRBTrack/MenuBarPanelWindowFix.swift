import AppKit

/// `MenuBarExtra` (`.window` style) often hides or orders out the panel when another app becomes active,
/// which breaks drag-and-drop from Finder. Re-apply these settings whenever the SwiftUI hierarchy updates.
enum MenuBarPanelWindowFix {

    static func applyRetentionFixes(to window: NSWindow?) {
        guard let window, shouldPatch(window) else { return }
        window.hidesOnDeactivate = false
        if let panel = window as? NSPanel {
            panel.becomesKeyOnlyIfNeeded = false
        }
    }

    /// If the runtime ordered the panel out anyway, bring it back without activating the app (Finder stays focused).
    static func reviveIfOrderedOut(_ window: NSWindow?) {
        guard let window, shouldPatch(window) else { return }
        applyRetentionFixes(to: window)
        if !window.isVisible {
            window.setIsVisible(true)
            window.orderFrontRegardless()
        }
    }

    private static func shouldPatch(_ window: NSWindow) -> Bool {
        if window is NSOpenPanel || window is NSSavePanel { return false }
        return true
    }
}
