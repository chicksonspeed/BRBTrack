import AppKit
import SwiftUI

// MARK: - Design system (Zoom Nuke–family utility aesthetic)

/// Central tokens for BRBTrack and future menu-bar panels. Avoid ad-hoc color/spacing literals in views.
enum AppDesignSystem {

    // MARK: Colors

    enum Colors {
        /// Window area behind the floating card.
        static let windowBackdrop = Color(red: 0.05, green: 0.07, blue: 0.11)

        // Panel gradient stops
        static let panelTop = Color(red: 0.05, green: 0.07, blue: 0.11)
        static let panelMid = Color(red: 0.07, green: 0.09, blue: 0.14)
        static let panelBottom = Color(red: 0.09, green: 0.11, blue: 0.17)

        /// Slightly lifted surfaces (cards, drop zone idle).
        static let surfaceElevated = Color.white.opacity(0.04)
        static let surfaceElevatedStrong = Color.white.opacity(0.07)

        /// Inset wells (results area, icon tiles).
        static let surfaceInset = Color.black.opacity(0.22)

        /// Segmented track / dark control bed.
        static let surfaceControlTrack = Color.white.opacity(0.06)

        // Accent
        static let accent = Color(red: 0.22, green: 0.58, blue: 0.98)
        static let accentPressed = Color(red: 0.12, green: 0.42, blue: 0.88)
        static let accentSubtleFill = accent.opacity(0.22)
        static let accentGlowFill = accent.opacity(0.14)
        static let accentBorder = accent.opacity(0.35)
        static let accentRingStrong = accent.opacity(0.85)
        static let accentDragFill = accent.opacity(0.12)
        static let accentRowHighlight = accent.opacity(0.08)

        // Text
        static let textPrimary = Color.white.opacity(0.96)
        static let textPrimarySoft = Color.white.opacity(0.92)
        static let textSecondary = Color.white.opacity(0.52)
        static let textSecondaryHover = Color.white.opacity(0.62)
        static let textTertiary = Color.white.opacity(0.35)

        // Borders & dividers
        static let borderSubtle = Color.white.opacity(0.10)
        static let borderMuted = Color.white.opacity(0.12)
        static let borderBevelTop = Color.white.opacity(0.18)
        static let borderBevelBottom = Color.white.opacity(0.06)
        static let divider = Color.white.opacity(0.08)

        // Overlays / states
        static let overlayHover = Color.white.opacity(0.04)
        static let innerGlow = Color.white.opacity(0.06)
        static let shadowKey = Color.black.opacity(0.45)
        /// Soft accent halo under main panel (matches Zoom Nuke action glow).
        static let shadowAccentGlow = accent.opacity(0.08)
        /// Large glyphs on elevated tiles (empty state, etc.).
        static let textOnElevatedIcon = textSecondary.opacity(0.9)
    }

    // MARK: Gradients

    enum Gradients {
        static var panelVertical: LinearGradient {
            LinearGradient(
                colors: [Colors.panelTop, Colors.panelMid, Colors.panelBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        static var panelInnerGlow: RadialGradient {
            RadialGradient(
                colors: [Colors.innerGlow, .clear],
                center: .top,
                startRadius: 40,
                endRadius: 420
            )
        }

        static var cardBorder: LinearGradient {
            LinearGradient(
                colors: [Colors.borderBevelTop, Colors.borderBevelBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var dropZoneHover: LinearGradient {
            LinearGradient(
                colors: [Colors.surfaceElevatedStrong, Colors.surfaceElevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var segmentSelection: LinearGradient {
            LinearGradient(
                colors: [Colors.accentSubtleFill, Colors.accentGlowFill],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: Corner radius

    enum Radius {
        static let panelCard: CGFloat = 14
        static let section: CGFloat = 10
        static let dropZone: CGFloat = 12
        static let controlTrack: CGFloat = 9
        static let controlPill: CGFloat = 7
        static let tileMD: CGFloat = 8
        static let tileLG: CGFloat = 12
        static let rowHighlight: CGFloat = 8
    }

    // MARK: Spacing scale

    enum Spacing {
        /// Tight stacks (e.g. title + subtitle).
        static let xxs: CGFloat = 3
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }

    // MARK: Border / stroke

    enum Stroke {
        static let hairline: CGFloat = 1
        static let emphasis: CGFloat = 1.5
        /// Slightly thicker solid border on drop zone hover / drag-over.
        static let dropZoneBorderEmphasis: CGFloat = 1.25
    }

    // MARK: Shadows (main card)

    enum Shadow {
        static let keyRadius: CGFloat = 18
        static let keyY: CGFloat = 10
        static let accentRadius: CGFloat = 24
        static let accentY: CGFloat = 12
    }

    // MARK: Layout (panel chrome)

    enum Layout {
        static let panelContentInset: CGFloat = 9
        static let panelMaxWidth: CGFloat = 400
        /// Minimum window height (empty / compact states).
        static let panelMinHeight: CGFloat = 340
        /// Upper cap for panel height (~fraction of visible desktop for the window’s screen).
        /// - Parameter hostingWindow: Menu bar panel window; uses its screen when non-`nil`, else key window, else main display.
        static func panelMaxHeightLimit(for hostingWindow: NSWindow? = nil) -> CGFloat {
            let screen = hostingWindow?.screen
                ?? NSApplication.shared.keyWindow?.screen
                ?? NSScreen.main
            guard let screen else { return 720 }
            return min(max(screen.visibleFrame.height * 0.88, panelMinHeight), 920)
        }

        /// Approximate combined height of header, drop zone, time picker, separators, and card insets (everything above the results well).
        /// Includes drop zone, header, time picker, separators, insets (keep in sync with `dropZoneHeight`).
        static let panelChromeHeight: CGFloat = 328
        /// Minimum height of the results list / empty-state well.
        static let resultsListMinHeight: CGFloat = 132
        /// Space below the results scroll view for the copy control (when the list is shown).
        static let copyListRowAreaHeight: CGFloat = 36
        /// Max height for the results list for a given panel host window (previews: pass `nil`).
        static func maxResultsListHeight(for hostingWindow: NSWindow? = nil) -> CGFloat {
            max(resultsListMinHeight, panelMaxHeightLimit(for: hostingWindow) - panelChromeHeight)
        }
        static let sectionHorizontal: CGFloat = 20
        static let sectionVertical: CGFloat = 14
        static let headerTop: CGFloat = 16
        static let headerBottom: CGFloat = 12
        static let dropZoneHeight: CGFloat = 108
        static let segmentControlHeight: CGFloat = 30
        static let iconTileSM: CGFloat = 40
        static let iconTileMD: CGFloat = 44
        static let iconTileLG: CGFloat = 56
        static let emptyStateSubtitleMaxWidth: CGFloat = 240
        static let listRowHorizontal: CGFloat = 18
        static let listRowVertical: CGFloat = 10
        static let listSeparatorLeading: CGFloat = 20
        static let listBlockVertical: CGFloat = 4
        static let expandedRowHorizontalInset: CGFloat = 8
        /// Horizontal inset of sliding pill inside segmented track.
        static let segmentPillHorizontalInset: CGFloat = 3
        /// Total horizontal margin subtracted from segment width for pill.
        static let segmentPillWidthTrim: CGFloat = 6
        static let segmentPillVerticalTrim: CGFloat = 6
    }

    // MARK: Motion

    enum Motion {
        static let springSegment = Animation.spring(response: 0.34, dampingFraction: 0.82)
        static let easeDropState = Animation.easeInOut(duration: 0.18)
        static let easeHover = Animation.easeInOut(duration: 0.15)
        static let easeRowExpand = Animation.easeInOut(duration: 0.14)
    }

    /// Point sizes shared by role modifiers and custom controls (segment cells, icons).
    enum TypeSize {
        static let panelTitle: CGFloat = 17
        static let panelSubtitle: CGFloat = 11
        static let sectionLabel: CGFloat = 10
        static let body: CGFloat = 13
        static let bodyEmphasis: CGFloat = 12
        static let helperCaption: CGFloat = 10
        static let linkCaption: CGFloat = 11
        static let control: CGFloat = 12
        static let emptyTitle: CGFloat = 14
        static let emptySubtitle: CGFloat = 11
        static let listPrimary: CGFloat = 13
        static let listMeta: CGFloat = 11
        static let listDetail: CGFloat = 11
        static let dropZoneIconMD: CGFloat = 20
        static let dropZoneIconSM: CGFloat = 17
    }

    // MARK: Typography (Space Grotesk + JetBrains Mono)

    enum Typography {
        /// Headings, UI chrome, and body copy.
        static func spaceGrotesk(size: CGFloat, weight: Font.Weight) -> Font {
            Font.custom("Space Grotesk", size: size).weight(weight)
        }

        /// Usernames, timestamps, labels, log lines, metadata.
        static func jetBrainsMono(size: CGFloat, weight: Font.Weight) -> Font {
            Font.custom("JetBrains Mono", size: size).weight(weight)
        }
    }
}

// MARK: - Typography roles

extension View {

    func dsPanelTitle() -> some View {
        font(AppDesignSystem.Typography.spaceGrotesk(size: AppDesignSystem.TypeSize.panelTitle, weight: .bold))
            .foregroundStyle(AppDesignSystem.Colors.textPrimary)
            .tracking(0.3)
    }

    func dsPanelSubtitle() -> some View {
        font(AppDesignSystem.Typography.spaceGrotesk(size: AppDesignSystem.TypeSize.panelSubtitle, weight: .regular))
            .foregroundStyle(AppDesignSystem.Colors.textSecondary)
    }

    func dsSectionLabel() -> some View {
        font(AppDesignSystem.Typography.jetBrainsMono(size: AppDesignSystem.TypeSize.sectionLabel, weight: .semibold))
            .foregroundStyle(AppDesignSystem.Colors.textTertiary)
            .tracking(0.8)
    }

    func dsBody() -> some View {
        font(AppDesignSystem.Typography.spaceGrotesk(size: AppDesignSystem.TypeSize.body, weight: .medium))
            .foregroundStyle(AppDesignSystem.Colors.textSecondary)
    }

    func dsBodyEmphasis() -> some View {
        font(AppDesignSystem.Typography.spaceGrotesk(size: AppDesignSystem.TypeSize.bodyEmphasis, weight: .semibold))
            .foregroundStyle(AppDesignSystem.Colors.textPrimary)
    }

    func dsHelperCaption() -> some View {
        font(AppDesignSystem.Typography.jetBrainsMono(size: AppDesignSystem.TypeSize.helperCaption, weight: .medium))
            .foregroundStyle(AppDesignSystem.Colors.textTertiary)
    }

    func dsLinkCaption() -> some View {
        font(AppDesignSystem.Typography.spaceGrotesk(size: AppDesignSystem.TypeSize.linkCaption, weight: .medium))
    }

    func dsControlSelected() -> some View {
        font(AppDesignSystem.Typography.spaceGrotesk(size: AppDesignSystem.TypeSize.control, weight: .semibold))
            .foregroundStyle(AppDesignSystem.Colors.textPrimary)
    }

    func dsControlUnselected() -> some View {
        font(AppDesignSystem.Typography.spaceGrotesk(size: AppDesignSystem.TypeSize.control, weight: .medium))
            .foregroundStyle(AppDesignSystem.Colors.textSecondary)
    }

    func dsEmptyStateTitle() -> some View {
        font(AppDesignSystem.Typography.spaceGrotesk(size: AppDesignSystem.TypeSize.emptyTitle, weight: .semibold))
            .foregroundStyle(AppDesignSystem.Colors.textPrimarySoft)
            .multilineTextAlignment(.center)
    }

    func dsEmptyStateSubtitle() -> some View {
        font(AppDesignSystem.Typography.spaceGrotesk(size: AppDesignSystem.TypeSize.emptySubtitle, weight: .regular))
            .foregroundStyle(AppDesignSystem.Colors.textTertiary)
            .multilineTextAlignment(.center)
    }

    func dsListPrimary() -> some View {
        font(AppDesignSystem.Typography.jetBrainsMono(size: AppDesignSystem.TypeSize.listPrimary, weight: .semibold))
            .foregroundStyle(AppDesignSystem.Colors.textPrimary)
    }

    func dsListMeta() -> some View {
        font(AppDesignSystem.Typography.jetBrainsMono(size: AppDesignSystem.TypeSize.listMeta, weight: .medium))
            .foregroundStyle(AppDesignSystem.Colors.textSecondary)
    }

    func dsListDetail() -> some View {
        font(AppDesignSystem.Typography.jetBrainsMono(size: AppDesignSystem.TypeSize.listDetail, weight: .regular))
            .foregroundStyle(AppDesignSystem.Colors.textSecondary)
    }
}
