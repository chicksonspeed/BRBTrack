import Foundation

/// Rule-based BRB intent detector.
///
/// Uses a small score table — threshold ≥ 3 means BRB intent.
/// Permanent-exit phrases subtract points to suppress false positives on
/// messages like "gotta go, brb tomorrow".
enum BRBDetector {

    // MARK: - Public API

    /// Returns `true` if the raw message text expresses BRB intent.
    static func isBRBIntent(_ raw: String) -> Bool {
        score(normalize(raw)) >= 3
    }

    /// Returns `true` if the message is an explicit "I'm back" signal.
    /// Does NOT treat "back in 10" or "be back soon" as return signals.
    static func isReturnSignal(_ raw: String) -> Bool {
        let text = normalize(raw)
        // Explicit return phrases — anchored or word-bounded.
        let signals: [String] = [
            #"\bim back\b"#,
            #"\bi'm back\b"#,
            #"\bi am back\b"#,
            #"\bback now\b"#,
            #"\bim here\b"#,
            #"\bi'm here\b"#,
            #"\bi am here\b"#,
            #"^here[!.]*$"#,
            #"^back[!.]*$"#,
        ]
        return signals.contains { matches(text, $0) }
    }

    /// Lowercase, trim, collapse whitespace, reduce ≥3 repeated chars to 2.
    static func normalize(_ raw: String) -> String {
        var s = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        // Collapse whitespace runs.
        s = s.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        // sooon → soon  /  brrrb → brrb (keep max 2 of any char in a row).
        s = reduceRepeats(s)
        return s
    }

    // MARK: - Scoring

    private static func score(_ text: String) -> Int {
        var pts = 0

        // ── Strong BRB signals (+3, counted once) ────────────────────────────
        // These are reliable temporary-absence indicators even without "brb".
        let strongBRB: [String] = [
            #"\bbrb\b"#,                    // brb / BRB / Brb
            "be right back",
            "be back",                       // "be back in 5", "be back soon"
            "back soon",
            #"back in \d"#,                  // "back in 10", "back in 5 mins"
            "back in a ",                    // "back in a bit", "back in a sec"
            "back in sec",
            "back in min",
            "wait for me",
            // Specific standalone-absence phrases listed in spec:
            "quick shower",
            "just reload",                   // "just reloading", "just reload"
            "gotta clean",                   // "gotta clean out my glass"
            "need to grab",                  // "need to grab my pipe"
        ]
        var gotBRB = false
        for pattern in strongBRB where !gotBRB {
            if matches(text, pattern) {
                pts += 3
                gotBRB = true
            }
        }

        // ── Temporary-absence context (+1, only one bonus) ────────────────────
        // These alone don't cross the threshold but boost borderline phrases.
        let tempContext: [String] = [
            "grabbing", "bathroom", "restroom", "toilet",
            #"\bshower\b"#, "reloading", "reload",
            "cleaning", "need to grab", "bio break",
            #"\bafk\b"#, "step away", "stepping away",
            "making coffee", "making tea", "quick",
            "just a sec", "one sec", "one moment",
            "hold on", "hold up",
        ]
        for pattern in tempContext {
            if matches(text, pattern) { pts += 1; break }
        }

        // ── Permanent-exit signals (−3, once) ────────────────────────────────
        let exits: [String] = [
            #"\bg2g\b"#, #"\bgtg\b"#,
            "gotta go", "got to go", "have to go", "i have to go",
            "signing off", "sign off", "signed off",
            #"\bbye\b"#, "goodbye", "good bye",
            "goodnight", "good night",
            "catch you later", "catch ya later",
            "talk later", "talk tomorrow",
            "logging off", "log off", "logged off",
            "see you later", "see ya later",
            #"\bttyl\b"#, #"\bcya\b"#,
        ]
        for pattern in exits {
            if matches(text, pattern) { pts -= 3; break }
        }

        return pts
    }

    // MARK: - Helpers

    private static func matches(_ text: String, _ pattern: String) -> Bool {
        // Try regex first (handles \b anchors).
        if let re = try? NSRegularExpression(pattern: pattern, options: []) {
            let r = NSRange(text.startIndex..., in: text)
            return re.firstMatch(in: text, options: [], range: r) != nil
        }
        // Fallback: plain substring search.
        return text.contains(pattern)
    }

    private static func reduceRepeats(_ s: String) -> String {
        // Replace runs of 3+ identical chars with 2.
        guard let re = try? NSRegularExpression(pattern: #"(.)\1{2,}"#) else { return s }
        let r = NSRange(s.startIndex..., in: s)
        return re.stringByReplacingMatches(in: s, options: [], range: r, withTemplate: "$1$1")
    }
}
