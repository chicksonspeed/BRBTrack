import AppKit
import SwiftUI

struct ContentView: View {
    @StateObject private var vm = BRBViewModel()
    @State private var panelHostWindow: NSWindow?
    /// Bumps when display configuration or the panel’s screen changes so layout limits recompute.
    @State private var displayLayoutGeneration = 0

    private var panelMaxHeightForCurrentDisplay: CGFloat {
        _ = displayLayoutGeneration
        return AppDesignSystem.Layout.panelMaxHeightLimit(for: panelHostWindow)
    }

    var body: some View {
        ZStack {
            AppDesignSystem.Colors.windowBackdrop
                .opacity(0.98)
            BRBTrackPanelView(vm: vm, hostingWindow: panelHostWindow)
        }
        .frame(width: AppDesignSystem.Layout.panelMaxWidth)
        .fixedSize(horizontal: true, vertical: true)
        .frame(maxHeight: panelMaxHeightForCurrentDisplay)
        .background(
            PanelDisplayLayoutObserver(
                layoutGeneration: $displayLayoutGeneration,
                panelHostWindow: $panelHostWindow
            )
        )
    }
}

// MARK: - Recompute layout when the panel window moves displays or screen parameters change

private struct PanelDisplayLayoutObserver: NSViewRepresentable {
    @Binding var layoutGeneration: Int
    @Binding var panelHostWindow: NSWindow?

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.sync(
            window: nsView.window,
            bumpLayout: { layoutGeneration += 1 },
            setHostWindow: { panelHostWindow = $0 }
        )
        // SwiftUI can reset AppKit window flags; re-apply every layout pass.
        MenuBarPanelWindowFix.applyRetentionFixes(to: nsView.window)
    }

    final class Coordinator {
        private var tokens: [NSObjectProtocol] = []
        private weak var observedWindow: NSWindow?
        private var bumpLayout: () -> Void = {}
        private var setHostWindow: (NSWindow?) -> Void = { _ in }
        private var pendingRevive: DispatchWorkItem?

        func sync(
            window: NSWindow?,
            bumpLayout: @escaping () -> Void,
            setHostWindow: @escaping (NSWindow?) -> Void
        ) {
            self.bumpLayout = bumpLayout
            self.setHostWindow = setHostWindow
            setHostWindow(window)

            guard window !== observedWindow else { return }

            tokens.forEach { NotificationCenter.default.removeObserver($0) }
            tokens.removeAll()
            pendingRevive?.cancel()
            pendingRevive = nil
            observedWindow = window

            guard let w = window else { return }

            let tScreen = NotificationCenter.default.addObserver(
                forName: NSWindow.didChangeScreenNotification,
                object: w,
                queue: .main
            ) { [weak self] _ in
                self?.bumpLayout()
            }
            let tParams = NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.bumpLayout()
            }
            let tKey = NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: w,
                queue: .main
            ) { [weak w] _ in
                MenuBarPanelWindowFix.applyRetentionFixes(to: w)
            }
            let tResignApp = NotificationCenter.default.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.scheduleReviveAfterResignActive()
            }
            tokens = [tScreen, tParams, tKey, tResignApp]
        }

        private func scheduleReviveAfterResignActive() {
            guard let w = observedWindow else { return }
            MenuBarPanelWindowFix.applyRetentionFixes(to: w)
            pendingRevive?.cancel()
            let item = DispatchWorkItem { [weak self] in
                guard let self, let w = self.observedWindow else { return }
                MenuBarPanelWindowFix.reviveIfOrderedOut(w)
            }
            pendingRevive = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: item)
        }

        deinit {
            pendingRevive?.cancel()
            tokens.forEach { NotificationCenter.default.removeObserver($0) }
        }
    }
}

#Preview {
    ContentView()
}
