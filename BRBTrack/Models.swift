import Foundation

// A single parsed line (or multi-line block) from a Zoom chat transcript.
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    /// Seconds since midnight, derived from the HH:MM:SS timestamp.
    let timeSeconds: Int
    let sender: String
    let recipient: String
    let body: String
}

// One person who is currently "BRB" within the chosen window.
struct BRBEntry: Identifiable {
    let id: UUID
    let sender: String
    let message: ChatMessage   // the latest BRB-intent message from this sender

    init(sender: String, message: ChatMessage) {
        self.id = UUID()
        self.sender = sender
        self.message = message
    }
}
