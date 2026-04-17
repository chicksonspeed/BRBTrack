import Foundation

/// Processes a sorted list of chat messages and returns the deduplicated set
/// of people who are currently BRB within the chosen time window.
enum PresenceTracker {

    /// - Parameters:
    ///   - messages: All parsed messages, in chronological order.
    ///   - windowMinutes: How many minutes before `latestTime` to consider.
    /// - Returns: BRBEntry values sorted oldest → newest (by BRB message time).
    ///
    /// Reference "now" is the timestamp of the last message in the file —
    /// not the machine clock — so replaying old logs works correctly.
    static func track(messages: [ChatMessage], windowMinutes: Int) -> [BRBEntry] {
        guard !messages.isEmpty else { return [] }

        // Use the last message's time as our reference "now".
        let nowSeconds    = messages.map(\.timeSeconds).max()!
        let windowSeconds = windowMinutes * 60
        let cutoff        = nowSeconds - windowSeconds

        // Walk all messages in order, maintaining per-sender BRB state.
        // We consider the full file (not just the window) so that return signals
        // outside the window correctly clear people who went BRB inside it.
        var latestBRB: [String: ChatMessage] = [:]

        for msg in messages {
            let norm = BRBDetector.normalize(msg.body)

            if BRBDetector.isReturnSignal(norm) {
                latestBRB.removeValue(forKey: msg.sender)
            } else if BRBDetector.isBRBIntent(norm) {
                // Always overwrite with the latest BRB message from this sender.
                latestBRB[msg.sender] = msg
            }
        }

        // Filter to the time window and build result list.
        return latestBRB.values
            .filter { $0.timeSeconds >= cutoff }
            .map    { BRBEntry(sender: $0.sender, message: $0) }
            .sorted { $0.message.timeSeconds < $1.message.timeSeconds }
    }

    /// Human-readable relative time string.
    /// - Parameters:
    ///   - messageSeconds: The BRB message's time (seconds since midnight).
    ///   - nowSeconds: Reference "now" (latest message time in the file).
    static func relativeLabel(messageSeconds: Int, nowSeconds: Int) -> String {
        let elapsed = max(0, nowSeconds - messageSeconds)
        let minutes = elapsed / 60
        if minutes == 0 { return "now" }
        return "~\(minutes)m"
    }
}
