import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Root panel

struct BRBTrackPanelView: View {
    @ObservedObject var vm: BRBViewModel
    /// Panel `NSWindow`; drives list height cap from that display. `nil` in previews.
    var hostingWindow: NSWindow? = nil

    var body: some View {
        VStack(spacing: 0) {
            BRBTrackHeader()
            DSSeparator(horizontalPadding: AppDesignSystem.Spacing.lg)
            ChatLogDropZone(vm: vm)
                .padding(.horizontal, AppDesignSystem.Layout.sectionHorizontal)
                .padding(.vertical, AppDesignSystem.Layout.sectionVertical)
            DSSeparator(horizontalPadding: AppDesignSystem.Spacing.lg)
            TimeRangePicker(selection: $vm.windowMinutes)
                .padding(.horizontal, AppDesignSystem.Layout.sectionHorizontal)
                .padding(.vertical, AppDesignSystem.Layout.sectionVertical)
            DSSeparator(horizontalPadding: AppDesignSystem.Spacing.lg)
            ResultsPane(
                vm: vm,
                maxListHeight: AppDesignSystem.Layout.maxResultsListHeight(for: hostingWindow)
            )
        }
        .padding(AppDesignSystem.Layout.panelContentInset)
        .dsMainPanelCard()
    }
}

// MARK: - Header

struct BRBTrackHeader: View {
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: AppDesignSystem.Spacing.xxs) {
                HStack(alignment: .center, spacing: AppDesignSystem.Spacing.sm) {
                    Image(systemName: "door.left.hand.open")
                        .font(.system(size: 17, weight: .semibold))
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .accessibilityHidden(true)
                    Text("BRB // TRACK")
                        .dsPanelTitle()
                }
                Text("Who said they'd be right back")
                    .dsPanelSubtitle()
            }
            Spacer(minLength: 0)
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Quit BRB Track")
            .accessibilityLabel("Quit BRB Track")
        }
        .padding(.horizontal, AppDesignSystem.Layout.sectionHorizontal)
        .padding(.top, AppDesignSystem.Layout.headerTop)
        .padding(.bottom, AppDesignSystem.Layout.headerBottom)
    }
}

// MARK: - Drop zone (file logic + design-system chrome)

struct ChatLogDropZone: View {
    @ObservedObject var vm: BRBViewModel
    @State private var isHovering = false

    var body: some View {
        UtilityDropZoneChrome(isTargeted: vm.isTargeted, isHovering: isHovering) {
            Group {
                if let name = vm.fileName {
                    dropZoneLoaded(fileName: name)
                } else {
                    dropZoneEmpty
                }
            }
        }
        .frame(height: AppDesignSystem.Layout.dropZoneHeight)
        .contentShape(RoundedRectangle(cornerRadius: AppDesignSystem.Radius.dropZone, style: .continuous))
        .onTapGesture { if vm.fileName == nil { vm.openFilePicker() } }
        .onDrop(of: [.fileURL], isTargeted: $vm.isTargeted, perform: handleDrop)
        .onHover { isHovering = $0 }
    }

    private var dropZoneEmpty: some View {
        VStack(spacing: 0) {
            Spacer(minLength: AppDesignSystem.Spacing.xs)
            VStack(spacing: AppDesignSystem.Spacing.sm) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: AppDesignSystem.TypeSize.dropZoneIconMD, weight: .medium))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .dsIconTile(side: AppDesignSystem.Layout.iconTileMD, cornerRadius: AppDesignSystem.Radius.tileMD)
                Text("Drop chat log or click to open")
                    .dsBody()
                    .multilineTextAlignment(.center)
                Text("Zoom saved chat (.txt)")
                    .dsHelperCaption()
                    .multilineTextAlignment(.center)
                    .padding(.top, AppDesignSystem.Spacing.xxs)
            }
            Spacer(minLength: AppDesignSystem.Spacing.xs)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, AppDesignSystem.Spacing.sm)
        .padding(.vertical, AppDesignSystem.Spacing.sm)
    }

    private func dropZoneLoaded(fileName: String) -> some View {
        HStack(spacing: AppDesignSystem.Spacing.md) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: AppDesignSystem.TypeSize.dropZoneIconSM, weight: .medium))
                .foregroundStyle(AppDesignSystem.Colors.accent)
                .dsIconTile(side: AppDesignSystem.Layout.iconTileSM, cornerRadius: AppDesignSystem.Radius.tileMD)
            VStack(alignment: .leading, spacing: AppDesignSystem.Spacing.xs) {
                Text(fileName)
                    .dsBodyEmphasis()
                    .lineLimit(1)
                    .truncationMode(.middle)
                Button("Change file…") { vm.openFilePicker() }
                    .buttonStyle(DSLinkButtonStyle())
                    .dsLinkCaption()
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppDesignSystem.Spacing.lg)
        .padding(.vertical, AppDesignSystem.Spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            var resolved: URL?
            if let data = item as? Data {
                resolved = URL(dataRepresentation: data, relativeTo: nil)
            } else if let url = item as? URL {
                resolved = url
            }
            guard let url = resolved else { return }
            DispatchQueue.main.async { vm.loadFile(url: url) }
        }
        return true
    }
}

// MARK: - Time window

struct TimeRangePicker: View {
    @Binding var selection: Int

    private let options = [15, 30, 45, 60, 90]

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Spacing.sm) {
            Text("SHOW BRB FROM LAST")
                .dsSectionLabel()
            UtilitySegmentedPicker(
                options: options,
                selection: $selection,
                label: { "\($0)" },
                accessibilitySummary: "Time window"
            )
        }
    }
}

// MARK: - Results

private struct ResultsPane: View {
    @ObservedObject var vm: BRBViewModel
    var maxListHeight: CGFloat

    /// Leave room under the scroll view for the copy control when the list is visible.
    private var listHeightCap: CGFloat {
        let reserve = vm.entries.isEmpty ? 0 : AppDesignSystem.Layout.copyListRowAreaHeight
        return max(AppDesignSystem.Layout.resultsListMinHeight, maxListHeight - reserve)
    }

    private var listScrollHeight: CGFloat {
        max(
            AppDesignSystem.Layout.resultsListMinHeight,
            min(estimatedListContentHeightValue, listHeightCap)
        )
    }

    private var estimatedListContentHeightValue: CGFloat {
        var total = AppDesignSystem.Layout.listBlockVertical * 2
        for entry in vm.entries {
            total += AppDesignSystem.Layout.listRowVertical * 2 + 20
            total += AppDesignSystem.Stroke.hairline
            if vm.isExpanded(entry) {
                let body = entry.message.body
                if body.isEmpty {
                    total += 22
                } else {
                    let approxLines = max(1, CGFloat(body.count) / 52)
                    total += min(approxLines * 17 + 12, 200)
                }
            }
        }
        return total
    }

    var body: some View {
        Group {
            if vm.fileName == nil {
                UtilityEmptyState(
                    systemImage: "text.bubble",
                    title: "Load a chat log to begin",
                    subtitle: "Drop a Zoom export above or choose a file"
                )
                .frame(maxWidth: .infinity, minHeight: AppDesignSystem.Layout.resultsListMinHeight)
            } else if vm.entries.isEmpty {
                UtilityEmptyState(
                    systemImage: "checkmark.circle",
                    title: "No BRBs in the last \(vm.windowMinutes) min",
                    subtitle: "Adjust the window or load a different log"
                )
                .frame(maxWidth: .infinity, minHeight: AppDesignSystem.Layout.resultsListMinHeight)
            } else {
                VStack(alignment: .trailing, spacing: AppDesignSystem.Spacing.xs) {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(vm.entries) { entry in
                                EntryRowView(entry: entry, vm: vm)
                                rowSeparator
                            }
                        }
                        .padding(.vertical, AppDesignSystem.Layout.listBlockVertical)
                    }
                    .frame(height: listScrollHeight)

                    HStack {
                        Spacer(minLength: 0)
                        Button {
                            vm.copyEntriesListToPasteboard()
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(AppDesignSystem.Colors.accent)
                                .frame(width: AppDesignSystem.Layout.iconTileSM, height: AppDesignSystem.Layout.iconTileSM)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("Copy list as text")
                        .accessibilityLabel("Copy list")
                    }
                    .padding(.trailing, AppDesignSystem.Layout.listRowHorizontal)
                    .padding(.bottom, AppDesignSystem.Spacing.xxs)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .dsInsetWell()
    }

    private var rowSeparator: some View {
        Rectangle()
            .fill(AppDesignSystem.Colors.divider)
            .frame(height: AppDesignSystem.Stroke.hairline)
            .padding(.leading, AppDesignSystem.Layout.listSeparatorLeading)
    }
}

// MARK: - Entry row

private struct EntryRowView: View {
    let entry: BRBEntry
    @ObservedObject var vm: BRBViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(AppDesignSystem.Motion.easeRowExpand) {
                    vm.toggleExpanded(for: entry)
                }
            } label: {
                HStack(alignment: .center) {
                    Text(entry.sender)
                        .dsListPrimary()
                        .lineLimit(1)
                    Spacer(minLength: AppDesignSystem.Spacing.sm)
                    Text("(\(vm.relativeTime(for: entry)))")
                        .dsListMeta()
                }
                .padding(.horizontal, AppDesignSystem.Layout.listRowHorizontal)
                .padding(.vertical, AppDesignSystem.Layout.listRowVertical)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if vm.isExpanded(entry) {
                Text(entry.message.body.isEmpty ? "(empty message)" : entry.message.body)
                    .dsListDetail()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppDesignSystem.Layout.listRowHorizontal)
                    .padding(.bottom, AppDesignSystem.Layout.listRowVertical)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background {
            if vm.isExpanded(entry) {
                RoundedRectangle(cornerRadius: AppDesignSystem.Radius.rowHighlight, style: .continuous)
                    .fill(AppDesignSystem.Colors.accentRowHighlight)
                    .padding(.horizontal, AppDesignSystem.Layout.expandedRowHorizontalInset)
            }
        }
    }
}
