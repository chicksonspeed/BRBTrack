import XCTest
@testable import BRBTrack

final class BRBDetectorTests: XCTestCase {

    // MARK: - isBRBIntent — should match

    func testBRBKeyword() {
        XCTAssertTrue(BRBDetector.isBRBIntent("brb"))
        XCTAssertTrue(BRBDetector.isBRBIntent("BRB"))
        XCTAssertTrue(BRBDetector.isBRBIntent("Brb"))
        XCTAssertTrue(BRBDetector.isBRBIntent("brb!"))
        XCTAssertTrue(BRBDetector.isBRBIntent("lol brb"))
    }

    func testBRBPhrases() {
        XCTAssertTrue(BRBDetector.isBRBIntent("be right back"))
        XCTAssertTrue(BRBDetector.isBRBIntent("Be Right Back"))
        XCTAssertTrue(BRBDetector.isBRBIntent("be back soon"))
        XCTAssertTrue(BRBDetector.isBRBIntent("back soon"))
        XCTAssertTrue(BRBDetector.isBRBIntent("back in 5"))
        XCTAssertTrue(BRBDetector.isBRBIntent("back in 10 mins"))
        XCTAssertTrue(BRBDetector.isBRBIntent("back in a sec"))
        XCTAssertTrue(BRBDetector.isBRBIntent("back in a bit"))
        XCTAssertTrue(BRBDetector.isBRBIntent("wait for me"))
    }

    func testBRBWithContext() {
        XCTAssertTrue(BRBDetector.isBRBIntent("brb grabbing water"))
        XCTAssertTrue(BRBDetector.isBRBIntent("brb bathroom break"))
        XCTAssertTrue(BRBDetector.isBRBIntent("brb real quick"))
        XCTAssertTrue(BRBDetector.isBRBIntent("brb in 10"))
        XCTAssertTrue(BRBDetector.isBRBIntent("brb soon"))
        XCTAssertTrue(BRBDetector.isBRBIntent("Brb grabbing water"))
        XCTAssertTrue(BRBDetector.isBRBIntent("brb bio break"))
    }

    func testBRBNormalization() {
        // Repeated letters should normalize: sooon -> soon
        XCTAssertTrue(BRBDetector.isBRBIntent("back sooon"))
    }

    func testSpecListedStandaloneMessages() {
        // Per spec: these standalone phrases must be detected as BRB intent.
        XCTAssertTrue(BRBDetector.isBRBIntent("gotta clean out my glass"))
        XCTAssertTrue(BRBDetector.isBRBIntent("need to grab my pipe"))
        XCTAssertTrue(BRBDetector.isBRBIntent("quick shower"))
        XCTAssertTrue(BRBDetector.isBRBIntent("just reloading"))
        XCTAssertTrue(BRBDetector.isBRBIntent("wait for me"))
    }

    // MARK: - isBRBIntent — should NOT match

    func testPermanentExit() {
        XCTAssertFalse(BRBDetector.isBRBIntent("g2g"))
        XCTAssertFalse(BRBDetector.isBRBIntent("gotta go"))
        XCTAssertFalse(BRBDetector.isBRBIntent("bye"))
        XCTAssertFalse(BRBDetector.isBRBIntent("goodnight"))
        XCTAssertFalse(BRBDetector.isBRBIntent("good night"))
        XCTAssertFalse(BRBDetector.isBRBIntent("signing off"))
        XCTAssertFalse(BRBDetector.isBRBIntent("logging off"))
        XCTAssertFalse(BRBDetector.isBRBIntent("catch you later"))
        XCTAssertFalse(BRBDetector.isBRBIntent("ttyl"))
        XCTAssertFalse(BRBDetector.isBRBIntent("cya"))
        XCTAssertFalse(BRBDetector.isBRBIntent("gtg"))
    }

    func testRandomChat() {
        XCTAssertFalse(BRBDetector.isBRBIntent("lol that's funny"))
        XCTAssertFalse(BRBDetector.isBRBIntent("agreed"))
        XCTAssertFalse(BRBDetector.isBRBIntent(""))
        XCTAssertFalse(BRBDetector.isBRBIntent("   "))
        XCTAssertFalse(BRBDetector.isBRBIntent("what time is the call?"))
    }

    // MARK: - isReturnSignal — should match

    func testReturnSignals() {
        XCTAssertTrue(BRBDetector.isReturnSignal("im back"))
        XCTAssertTrue(BRBDetector.isReturnSignal("I'm back"))
        XCTAssertTrue(BRBDetector.isReturnSignal("i am back"))
        XCTAssertTrue(BRBDetector.isReturnSignal("back now"))
        XCTAssertTrue(BRBDetector.isReturnSignal("im here"))
        XCTAssertTrue(BRBDetector.isReturnSignal("i'm here"))
        XCTAssertTrue(BRBDetector.isReturnSignal("here"))
        XCTAssertTrue(BRBDetector.isReturnSignal("back"))
        XCTAssertTrue(BRBDetector.isReturnSignal("here!"))
        XCTAssertTrue(BRBDetector.isReturnSignal("back."))
    }

    // MARK: - isReturnSignal — should NOT match

    func testNotReturnSignals() {
        XCTAssertFalse(BRBDetector.isReturnSignal("back in 10"))
        XCTAssertFalse(BRBDetector.isReturnSignal("be back"))
        XCTAssertFalse(BRBDetector.isReturnSignal("back soon"))
        XCTAssertFalse(BRBDetector.isReturnSignal("brb"))
        XCTAssertFalse(BRBDetector.isReturnSignal("be right back"))
        XCTAssertFalse(BRBDetector.isReturnSignal("lol"))
        XCTAssertFalse(BRBDetector.isReturnSignal(""))
    }

    // MARK: - normalize

    func testNormalize() {
        XCTAssertEqual(BRBDetector.normalize("  BRB  "), "brb")
        XCTAssertEqual(BRBDetector.normalize("sooon"),   "soon")
        XCTAssertEqual(BRBDetector.normalize("BACK  IN"), "back in")
    }
}
