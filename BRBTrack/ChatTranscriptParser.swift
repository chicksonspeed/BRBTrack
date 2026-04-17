import Foundation

/// Parses Zoom-style saved chat transcripts.
///
/// Expected line format:
///   `HH:MM:SS From <sender> to <recipient>: <body>`
///
/// Continuation lines (no timestamp header) are appended to the previous
/// message's body. Malformed lines that don't match and have no prior message
/// are silently dropped.
enum ChatTranscriptParser {

    // Greedy sender capture: (.+) backtracks to the rightmost " to " before
    // a colon-free recipient segment, which is how Zoom formats names.
    private static let headerRegex: NSRegularExpression = {
        let pattern = #"^(\d{2}):(\d{2}):(\d{2}) From (.+) to ([^:]+): ?(.*)"#
        return try! NSRegularExpression(pattern: pattern, options: [])
    }()

    static func parse(_ text: String) -> [ChatMessage] {
        var messages: [ChatMessage] = []

        // Accumulated state for the current in-progress message.
        var curTime     = 0
        var curSender   = ""
        var curRecip    = ""
        var curLines:  [String] = []
        var inMsg       = false

        func flush() {
            guard inMsg else { return }
            let body = curLines
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            messages.append(ChatMessage(
                timeSeconds: curTime,
                sender:      curSender,
                recipient:   curRecip,
                body:        body
            ))
        }

        for raw in text.components(separatedBy: "\n") {
            // Normalize Windows line endings.
            let line = raw.hasSuffix("\r") ? String(raw.dropLast()) : raw
            let ns   = line as NSString
            let full = NSRange(location: 0, length: ns.length)

            if let m = headerRegex.firstMatch(in: line, options: [], range: full) {
                flush()

                let h = Int(ns.substring(with: m.range(at: 1))) ?? 0
                let mn = Int(ns.substring(with: m.range(at: 2))) ?? 0
                let s = Int(ns.substring(with: m.range(at: 3))) ?? 0

                curTime   = h * 3600 + mn * 60 + s
                curSender = ns.substring(with: m.range(at: 4))
                    .trimmingCharacters(in: .whitespaces)
                curRecip  = ns.substring(with: m.range(at: 5))
                    .trimmingCharacters(in: .whitespaces)
                // First body line from the header itself.
                curLines  = [ns.substring(with: m.range(at: 6))]
                inMsg     = true

            } else if inMsg {
                // Continuation line — append to current message body.
                curLines.append(line)
            }
            // else: orphaned line before any header — skip silently.
        }

        flush()
        return messages
    }
}
