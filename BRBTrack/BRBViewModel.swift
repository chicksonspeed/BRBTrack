import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class BRBViewModel: ObservableObject {

    // MARK: - Published state

    @Published var entries:      [BRBEntry] = []
    @Published var fileName:     String?    = nil
    @Published var isTargeted:   Bool       = false   // drag-over highlight

    @Published var windowMinutes: Int = 45 {
        didSet { refresh() }
    }

    // MARK: - Private

    private var allMessages: [ChatMessage] = []
    private var nowSeconds:  Int           = 0

    // Which sender rows are currently expanded to show their message body.
    @Published var expandedSenders: Set<String> = []

    // MARK: - File loading

    func loadFile(url: URL) {
        guard url.isFileURL else { return }
        // Read with a UTF-8 attempt, fall back to Latin-1 for legacy chat exports.
        let text: String
        if let t = try? String(contentsOf: url, encoding: .utf8) {
            text = t
        } else if let t = try? String(contentsOf: url, encoding: .isoLatin1) {
            text = t
        } else {
            return
        }

        allMessages  = ChatTranscriptParser.parse(text)
        nowSeconds   = allMessages.map(\.timeSeconds).max() ?? 0
        fileName     = url.lastPathComponent
        expandedSenders.removeAll()
        refresh()
    }

    func openFilePicker() {
        let panel                     = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories    = false
        panel.canChooseFiles          = true
        panel.allowedContentTypes     = [.text, .plainText]
        panel.title                   = "Open Zoom Chat Log"
        panel.message                 = "Choose a Zoom saved-chat .txt file"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        loadFile(url: url)
    }

    // MARK: - Results

    func refresh() {
        entries = PresenceTracker.track(messages: allMessages, windowMinutes: windowMinutes)
    }

    // MARK: - Row helpers

    func relativeTime(for entry: BRBEntry) -> String {
        PresenceTracker.relativeLabel(
            messageSeconds: entry.message.timeSeconds,
            nowSeconds:     nowSeconds
        )
    }

    func isExpanded(_ entry: BRBEntry) -> Bool {
        expandedSenders.contains(entry.sender)
    }

    func toggleExpanded(for entry: BRBEntry) {
        if expandedSenders.contains(entry.sender) {
            expandedSenders.remove(entry.sender)
        } else {
            expandedSenders.insert(entry.sender)
        }
    }

    /// Plain-text lines matching the on-screen list (`Name (~12m)`).
    func copyEntriesListToPasteboard() {
        guard !entries.isEmpty else { return }
        let lines = entries.map { entry in
            "\(entry.sender) (\(relativeTime(for: entry)))"
        }
        let text = lines.joined(separator: "\n")
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }
}
