import AVFAudio
import Combine
import XCTest
@testable import CellLab

@MainActor
final class MitosisNarrationPlayerTests: XCTestCase {
    func testOpeningIsBundledAndDecodable() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "mitosis-opening", withExtension: "wav"))
        let recording = try AVAudioPlayer(contentsOf: url)
        XCTAssertGreaterThan(recording.duration, 15)
        XCTAssertEqual(recording.numberOfChannels, 1)
    }

    func testStopResetsPlaybackAndAllowsListeningAgain() {
        let narration = MitosisNarrationPlayer()
        defer { narration.stop() }

        narration.toggle()
        XCTAssertTrue(narration.isPlaying)
        XCTAssertNil(narration.errorMessage)
        narration.toggle()
        XCTAssertFalse(narration.isPlaying)
        narration.toggle()
        XCTAssertTrue(narration.isPlaying)
        narration.stop()
        XCTAssertFalse(narration.isPlaying)
    }

    func testNaturalCompletionResetsPlayback() async {
        let narration = MitosisNarrationPlayer()
        defer { narration.stop() }
        narration.toggle()
        XCTAssertTrue(narration.isPlaying)

        let finished = expectation(description: "Bundled opening finishes playing")
        let observation = narration.$isPlaying.dropFirst().filter { !$0 }.sink { _ in
            finished.fulfill()
        }
        await fulfillment(of: [finished], timeout: 22)
        withExtendedLifetime(observation) {}
        XCTAssertFalse(narration.isPlaying)
    }

    func testMissingRecordingKeepsPlaybackStopped() {
        let narration = MitosisNarrationPlayer(recordingURL: nil)
        narration.toggle()
        XCTAssertFalse(narration.isPlaying)
        XCTAssertNotNil(narration.errorMessage)
    }
}
