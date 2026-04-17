import XCTest
@testable import BRBTrack

final class ChatTranscriptParserTests: XCTestCase {

    // MARK: - Basic parsing

    func testSingleMessage() {
        let log = "18:21:17 From Alice to Everyone: brb grabbing water\n"
        let msgs = ChatTranscriptParser.parse(log)
        XCTAssertEqual(msgs.count, 1)
        XCTAssertEqual(msgs[0].sender,      "Alice")
        XCTAssertEqual(msgs[0].recipient,   "Everyone")
        XCTAssertEqual(msgs[0].body,        "brb grabbing water")
        XCTAssertEqual(msgs[0].timeSeconds, 18 * 3600 + 21 * 60 + 17)
    }

    func testTimestampConversion() {
        let log = "20:53:18 From Tony bottom nyc to Everyone: Brb bathroom break\n"
        let msgs = ChatTranscriptParser.parse(log)
        XCTAssertEqual(msgs[0].timeSeconds, 20 * 3600 + 53 * 60 + 18)
    }

    func testSenderWithColon() {
        // Sender contains "tele: cloudydayzzny" — colon in the name.
        let log = "18:21:17 From tele: cloudydayzzny to Everyone: brb grabbing water\n"
        let msgs = ChatTranscriptParser.parse(log)
        XCTAssertEqual(msgs.count, 1)
        XCTAssertEqual(msgs[0].sender, "tele: cloudydayzzny")
        XCTAssertEqual(msgs[0].body,   "brb grabbing water")
    }

    func testMultipleMessages() {
        let log = """
        18:00:00 From Alice to Everyone: hello
        18:05:00 From Bob to Everyone: brb
        18:10:00 From Alice to Everyone: back now
        """
        let msgs = ChatTranscriptParser.parse(log)
        XCTAssertEqual(msgs.count, 3)
        XCTAssertEqual(msgs[0].sender, "Alice")
        XCTAssertEqual(msgs[1].sender, "Bob")
        XCTAssertEqual(msgs[2].sender, "Alice")
    }

    func testMultilineBody() {
        let log = """
        18:00:00 From Alice to Everyone: first line
        second line
        third line
        18:05:00 From Bob to Everyone: hi
        """
        let msgs = ChatTranscriptParser.parse(log)
        XCTAssertEqual(msgs.count, 2)
        XCTAssertTrue(msgs[0].body.contains("first line"))
        XCTAssertTrue(msgs[0].body.contains("second line"))
        XCTAssertTrue(msgs[0].body.contains("third line"))
        XCTAssertEqual(msgs[1].body, "hi")
    }

    func testEmptyBody() {
        // Body is empty — no crash, empty string body.
        let log = "18:00:00 From Alice to Everyone: \n"
        let msgs = ChatTranscriptParser.parse(log)
        XCTAssertEqual(msgs.count, 1)
        XCTAssertEqual(msgs[0].body, "")
    }

    func testEmptyInput() {
        XCTAssertTrue(ChatTranscriptParser.parse("").isEmpty)
        XCTAssertTrue(ChatTranscriptParser.parse("   \n\n  ").isEmpty)
    }

    func testMalformedLinesIgnored() {
        // Lines that don't match the header format (and have no prior message)
        // are silently dropped.
        let log = """
        This is not a valid header
        Also bad
        18:00:00 From Alice to Everyone: valid
        """
        let msgs = ChatTranscriptParser.parse(log)
        XCTAssertEqual(msgs.count, 1)
        XCTAssertEqual(msgs[0].sender, "Alice")
    }

    func testWindowsLineEndings() {
        let log = "18:00:00 From Alice to Everyone: brb\r\n18:01:00 From Bob to Everyone: hi\r\n"
        let msgs = ChatTranscriptParser.parse(log)
        XCTAssertEqual(msgs.count, 2)
        XCTAssertEqual(msgs[0].body, "brb")
    }

    // MARK: - PresenceTracker integration

    func testPresenceTrackerBasic() {
        let log = """
        18:00:00 From Alice to Everyone: brb
        18:10:00 From Bob to Everyone: be right back
        18:30:00 From Alice to Everyone: im back
        18:45:00 From Carol to Everyone: brb grabbing water
        19:00:00 From Dave to Everyone: hello there
        """
        let msgs    = ChatTranscriptParser.parse(log)
        let entries = PresenceTracker.track(messages: msgs, windowMinutes: 60)

        // Alice returned, Dave never BRB'd — only Bob and Carol should appear.
        let senders = Set(entries.map(\.sender))
        XCTAssertFalse(senders.contains("Alice"))
        XCTAssertTrue(senders.contains("Bob"))
        XCTAssertTrue(senders.contains("Carol"))
        XCTAssertFalse(senders.contains("Dave"))
    }

    func testPresenceTrackerTimeWindow() {
        // Bob BRB'd 90 min before now — outside a 45-min window.
        let log = """
        17:00:00 From Bob to Everyone: brb
        18:30:00 From Alice to Everyone: brb
        18:31:00 From Filler to Everyone: hi
        """
        let msgs    = ChatTranscriptParser.parse(log)
        // now = 18:31:00; 45 min window → cutoff = 17:46:00
        let entries = PresenceTracker.track(messages: msgs, windowMinutes: 45)
        let senders = Set(entries.map(\.sender))
        XCTAssertFalse(senders.contains("Bob"))
        XCTAssertTrue(senders.contains("Alice"))
    }

    func testPresenceTrackerLatestBRBWins() {
        // Alice BRBs twice — only the latest message should appear.
        let log = """
        18:00:00 From Alice to Everyone: brb bathroom
        18:10:00 From Alice to Everyone: brb again, one more min
        18:20:00 From Filler to Everyone: ok
        """
        let msgs    = ChatTranscriptParser.parse(log)
        let entries = PresenceTracker.track(messages: msgs, windowMinutes: 60)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].message.body, "brb again, one more min")
    }

    func testPresenceTrackerSortOrder() {
        let log = """
        18:00:00 From Charlie to Everyone: brb
        18:05:00 From Alice to Everyone: brb soon
        18:03:00 From Bob to Everyone: be right back
        18:10:00 From Filler to Everyone: hi
        """
        let msgs    = ChatTranscriptParser.parse(log)
        let entries = PresenceTracker.track(messages: msgs, windowMinutes: 60)
        // Should be Charlie, Bob, Alice (ascending timestamp).
        XCTAssertEqual(entries.map(\.sender), ["Charlie", "Bob", "Alice"])
    }
}
