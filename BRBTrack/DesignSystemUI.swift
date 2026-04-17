import SwiftUI

// MARK: - Main panel card

struct MainPanelCardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    AppDesignSystem.Gradients.panelVertical
                    AppDesignSystem.Gradients.panelInnerGlow
                        .blendMode(.plusLighter)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.Radius.panelCard, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppDesignSystem.Radius.panelCard, style: .continuous)
                    .strokeBorder(
                        AppDesignSystem.Gradients.cardBorder,
                        lineWidth: AppDesignSystem.Stroke.hairline
                    )
            }
            .shadow(color: AppDesignSystem.Colors.shadowKey, radius: AppDesignSystem.Shadow.keyRadius, y: AppDesignSystem.Shadow.keyY)
            .shadow(
                color: AppDesignSystem.Colors.shadowAccentGlow,
                radius: AppDesignSystem.Shadow.accentRadius,
                y: AppDesignSystem.Shadow.accentY
            )
    }
}

extension View {
    func dsMainPanelCard() -> some View {
        modifier(MainPanelCardSurface())
    }
}

// MARK: - Inset well (results list bed)

struct InsetWellSurface: ViewModifier {
    var horizontalInset: CGFloat = AppDesignSystem.Spacing.md
    var verticalInset: CGFloat = AppDesignSystem.Spacing.sm

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: AppDesignSystem.Radius.section, style: .continuous)
                    .fill(AppDesignSystem.Colors.surfaceInset.opacity(0.65))
                    .padding(.horizontal, horizontalInset)
                    .padding(.vertical, verticalInset)
            }
    }
}

extension View {
    func dsInsetWell(
        horizontal: CGFloat = AppDesignSystem.Spacing.md,
        vertical: CGFloat = AppDesignSystem.Spacing.sm
    ) -> some View {
        modifier(InsetWellSurface(horizontalInset: horizontal, verticalInset: vertical))
    }
}

// MARK: - Icon tile (drop zone / empty state)

struct IconTileSurface: ViewModifier {
    let side: CGFloat
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(width: side, height: side)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppDesignSystem.Colors.surfaceInset)
            }
    }
}

extension View {
    func dsIconTile(side: CGFloat, cornerRadius: CGFloat = AppDesignSystem.Radius.tileMD) -> some View {
        modifier(IconTileSurface(side: side, cornerRadius: cornerRadius))
    }
}

// MARK: - Bordered elevated tile (empty state hero icon)

struct ElevatedIconTile: View {
    let systemName: String
    let iconSize: CGFloat
    let side: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppDesignSystem.Colors.surfaceElevated)
                .frame(width: side, height: side)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            AppDesignSystem.Colors.borderSubtle.opacity(0.8),
                            lineWidth: AppDesignSystem.Stroke.hairline
                        )
                }
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(AppDesignSystem.Colors.textOnElevatedIcon)
        }
    }
}

// MARK: - Subtle horizontal rule

struct DSSeparator: View {
    var horizontalPadding: CGFloat = AppDesignSystem.Spacing.lg

    var body: some View {
        Rectangle()
            .fill(AppDesignSystem.Colors.divider)
            .frame(height: AppDesignSystem.Stroke.hairline)
            .padding(.horizontal, horizontalPadding)
    }
}

// MARK: - Link button (accent)

struct DSLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(
                configuration.isPressed
                    ? AppDesignSystem.Colors.accentPressed
                    : AppDesignSystem.Colors.accent
            )
    }
}

// MARK: - Utility segmented picker (animated pill)

struct UtilitySegmentedPicker<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    var label: (Value) -> String
    var accessibilitySummary: String = "Options"

    var body: some View {
        GeometryReader { geo in
            let segmentW = geo.size.width / CGFloat(max(options.count, 1))
            let idx = CGFloat(max(0, options.firstIndex(of: selection) ?? 0))

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppDesignSystem.Radius.controlTrack, style: .continuous)
                    .fill(AppDesignSystem.Colors.surfaceControlTrack)
                RoundedRectangle(cornerRadius: AppDesignSystem.Radius.controlTrack, style: .continuous)
                    .strokeBorder(AppDesignSystem.Colors.borderMuted, lineWidth: AppDesignSystem.Stroke.hairline)

                RoundedRectangle(cornerRadius: AppDesignSystem.Radius.controlPill, style: .continuous)
                    .fill(AppDesignSystem.Gradients.segmentSelection)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppDesignSystem.Radius.controlPill, style: .continuous)
                            .strokeBorder(AppDesignSystem.Colors.accentBorder, lineWidth: AppDesignSystem.Stroke.hairline)
                    }
                    .frame(
                        width: max(0, segmentW - AppDesignSystem.Layout.segmentPillWidthTrim),
                        height: geo.size.height - AppDesignSystem.Layout.segmentPillVerticalTrim
                    )
                    .offset(x: AppDesignSystem.Layout.segmentPillHorizontalInset + idx * segmentW)
                    .animation(AppDesignSystem.Motion.springSegment, value: selection)

                HStack(spacing: 0) {
                    ForEach(options, id: \.self) { value in
                        UtilitySegmentCell(
                            title: label(value),
                            isSelected: selection == value,
                            segmentWidth: segmentW,
                            height: geo.size.height
                        ) {
                            selection = value
                        }
                    }
                }
            }
        }
        .frame(height: AppDesignSystem.Layout.segmentControlHeight)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilitySummary)
    }
}

private struct UtilitySegmentCell: View {
    let title: String
    let isSelected: Bool
    let segmentWidth: CGFloat
    let height: CGFloat
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(
                    AppDesignSystem.Typography.spaceGrotesk(
                        size: AppDesignSystem.TypeSize.control,
                        weight: isSelected ? .semibold : .medium
                    )
                )
                .foregroundStyle(foreground)
                .frame(width: segmentWidth, height: height)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var foreground: Color {
        if isSelected { return AppDesignSystem.Colors.textPrimary }
        if isHovering { return AppDesignSystem.Colors.textSecondaryHover }
        return AppDesignSystem.Colors.textSecondary
    }
}

// MARK: - Drop zone chrome (styling only)

struct UtilityDropZoneChrome<Content: View>: View {
    var isTargeted: Bool
    var isHovering: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppDesignSystem.Radius.dropZone, style: .continuous)
                .fill(fillStyle)
            RoundedRectangle(cornerRadius: AppDesignSystem.Radius.dropZone, style: .continuous)
                .strokeBorder(
                    borderColor,
                    lineWidth: isHovering || isTargeted
                        ? AppDesignSystem.Stroke.dropZoneBorderEmphasis
                        : AppDesignSystem.Stroke.hairline
                )
            if isTargeted {
                RoundedRectangle(cornerRadius: AppDesignSystem.Radius.dropZone, style: .continuous)
                    .strokeBorder(
                        AppDesignSystem.Colors.accentRingStrong,
                        lineWidth: AppDesignSystem.Stroke.emphasis
                    )
            }
            content()
        }
        .animation(AppDesignSystem.Motion.easeDropState, value: isTargeted)
        .animation(AppDesignSystem.Motion.easeHover, value: isHovering)
    }

    private var fillStyle: AnyShapeStyle {
        if isTargeted {
            return AnyShapeStyle(AppDesignSystem.Colors.accentDragFill)
        }
        if isHovering {
            return AnyShapeStyle(AppDesignSystem.Gradients.dropZoneHover)
        }
        return AnyShapeStyle(AppDesignSystem.Colors.surfaceElevated.opacity(0.85))
    }

    private var borderColor: Color {
        if isTargeted { return AppDesignSystem.Colors.accent.opacity(0.55) }
        return AppDesignSystem.Colors.borderSubtle.opacity(isHovering ? 0.95 : 0.72)
    }
}

// MARK: - Empty state (reusable)

struct UtilityEmptyState: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: AppDesignSystem.Spacing.md + AppDesignSystem.Spacing.xs) {
            ElevatedIconTile(
                systemName: systemImage,
                iconSize: 24,
                side: AppDesignSystem.Layout.iconTileLG,
                cornerRadius: AppDesignSystem.Radius.tileLG
            )
            VStack(spacing: AppDesignSystem.Spacing.xs) {
                Text(title)
                    .dsEmptyStateTitle()
                Text(subtitle)
                    .dsEmptyStateSubtitle()
                    .frame(maxWidth: AppDesignSystem.Layout.emptyStateSubtitleMaxWidth)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppDesignSystem.Spacing.xl + AppDesignSystem.Spacing.sm)
        .padding(.vertical, AppDesignSystem.Spacing.xl)
    }
}
