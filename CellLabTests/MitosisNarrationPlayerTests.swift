import AVFAudio
import Combine
import XCTest
import UIKit
@testable import CellLab

@MainActor
private final class TestNarrationPlayback: NarrationPlayback {
    var onCompletion: ((UUID, Bool) -> Void)?
    var starts: [(id: String, token: UUID)] = []
    var fail = false
    func play(url: URL, token: UUID) throws {
        if fail { throw CocoaError(.fileReadUnknown) }
        starts.append((url.deletingPathExtension().lastPathComponent, token))
    }
    func stop() {}
    func finish(_ index: Int? = nil) { onCompletion?(starts[index ?? starts.count - 1].token, true) }
}

@MainActor
final class MitosisNarrationPlayerTests: XCTestCase {
    private func makeNarrator() throws -> (LessonNarrator, TestNarrationPlayback) {
        let playback = TestNarrationPlayback()
        let library = try NarrationLibrary.load(resource: "mitosis-narration")
        let narrator = LessonNarrator(library: library, playback: playback,
                                     phaseDelay: 0.02, overviewDelay: 0.02) {
            URL(fileURLWithPath: "/test/" + $0.resource)
        }
        return (narrator, playback)
    }
    private func settle() async { try? await Task.sleep(nanoseconds: 80_000_000) }

    func testEveryScriptCueIsBundledAndDecodable() throws {
        let library = try NarrationLibrary.load(resource: "mitosis-narration")
        XCTAssertEqual(library.recordings.count, 32)
        XCTAssertEqual(Set(library.recordings.map(\.id)).count, 32)
        for recording in library.recordings {
            let resource = recording.resource as NSString
            let url = try XCTUnwrap(Bundle.main.url(forResource: resource.deletingPathExtension, withExtension: "wav"))
            let audio = try AVAudioPlayer(contentsOf: url)
            XCTAssertGreaterThan(audio.duration, 1, recording.id)
            XCTAssertEqual(audio.numberOfChannels, 1, recording.id)
            XCTAssertFalse(recording.text.contains("RECORD "))
        }
    }

    func testEntryIsQuietAndOverviewHandsOffThenWaits() async throws {
        let (narrator, playback) = try makeNarrator()
        XCTAssertFalse(narrator.isPlaying)
        XCTAssertEqual(narrator.lessonButtonTitle, "Hear overview")
        XCTAssertTrue(playback.starts.isEmpty)
        narrator.toggleLesson()
        XCTAssertEqual(playback.starts.map(\.id), ["lesson.overview"])
        playback.finish()
        XCTAssertFalse(narrator.isPlaying)
        XCTAssertTrue(narrator.isScheduled)
        await settle()
        XCTAssertEqual(playback.starts.map(\.id), ["lesson.overview", "lesson.prophase"])
        playback.finish()
        await settle()
        XCTAssertEqual(playback.starts.count, 2)
        XCTAssertEqual(narrator.lessonButtonTitle, "Replay Prophase")
        XCTAssertEqual(narrator.mode, .lesson)
    }

    func testRapidSelectionsInterruptOverviewAndOnlyStartFinalPhase() async throws {
        let (narrator, playback) = try makeNarrator()
        narrator.playOverview()
        narrator.selectPhase("lesson.prometaphase")
        narrator.selectPhase("lesson.metaphase")
        narrator.selectPhase("lesson.anaphase")
        XCTAssertFalse(narrator.isPlaying)
        playback.finish(0) // Stale completion must not schedule Prophase.
        await settle()
        XCTAssertEqual(playback.starts.map(\.id), ["lesson.overview", "lesson.anaphase"])
        narrator.selectPhase("lesson.anaphase") // Same dot is not a new selection.
        await settle()
        XCTAssertEqual(playback.starts.count, 2)
        XCTAssertTrue(narrator.isPlaying)
    }

    func testStopDuringOverviewBreathCancelsFutureSwipes() async throws {
        let (narrator, playback) = try makeNarrator()
        narrator.playOverview()
        playback.finish()
        XCTAssertTrue(narrator.isScheduled)
        narrator.stop()
        narrator.selectPhase("lesson.metaphase")
        await settle()
        XCTAssertEqual(playback.starts.count, 1)
        XCTAssertEqual(narrator.mode, .quiet)
        XCTAssertFalse(narrator.isScheduled)
        XCTAssertEqual(narrator.lessonButtonTitle, "Hear Metaphase")
        narrator.toggleLesson()
        XCTAssertEqual(playback.starts.last?.id, "lesson.metaphase")
    }

    func testStopDuringSettlingAndLeavingCancelDelayedWork() async throws {
        let (narrator, playback) = try makeNarrator()
        narrator.playPhase()
        narrator.selectPhase("lesson.telophase")
        narrator.stop()
        playback.finish(0)
        await settle()
        XCTAssertEqual(playback.starts.count, 1)
        XCTAssertFalse(narrator.isPlaying)
        XCTAssertFalse(narrator.isScheduled)
    }

    func testOptionalSectionExitsSwipeNarrationAndIgnoresOldCompletion() async throws {
        let (narrator, playback) = try makeNarrator()
        narrator.playOverview()
        narrator.playStandalone("reference.human-count")
        playback.finish(0)
        narrator.selectPhase("lesson.anaphase")
        await settle()
        XCTAssertEqual(playback.starts.map(\.id), ["lesson.overview", "reference.human-count"])
        XCTAssertEqual(narrator.currentCueID, "reference.human-count")
        XCTAssertEqual(narrator.mode, .quiet)
        XCTAssertTrue(narrator.isPlaying)
        narrator.toggleStandalone("reference.human-count")
        XCTAssertFalse(narrator.isPlaying)
    }

    func testGameEventsAreOncePerRunAndManualReplayIsAlwaysAllowed() throws {
        let (narrator, playback) = try makeNarrator()
        narrator.startGameGuidance("game.prophase.start")
        playback.finish()
        narrator.gameEventChanged("game.prophase.start")
        XCTAssertEqual(playback.starts.count, 1)
        narrator.startGameGuidance("game.prophase.start")
        narrator.gameEventChanged("game.prophase.packed")
        narrator.gameEventChanged("game.prophase.result")
        playback.finish(2)
        XCTAssertEqual(narrator.currentCueID, "game.prophase.result")
        XCTAssertTrue(narrator.isPlaying)
        narrator.gameEventChanged(nil) // Dismiss/advance interrupts the pop-up.
        XCTAssertFalse(narrator.isPlaying)
        narrator.gameEventChanged("game.prometaphase.start")
        XCTAssertEqual(playback.starts.last?.id, "game.prometaphase.start")
        narrator.resetGameGuidance()
        narrator.gameEventChanged("game.prophase.start")
        XCTAssertEqual(playback.starts.filter { $0.id == "game.prophase.start" }.count, 3)
    }

    func testGameCueChangesFollowActualAvailableActions() {
        var game = MitosisSession()
        XCTAssertEqual(game.instructionNarrationID, "game.prophase.start")
        for id in 0..<4 { game.send(.condense(id)) }
        XCTAssertEqual(game.instructionNarrationID, "game.prophase.packed")
        game.send(.movePole(.left)); game.send(.movePole(.right))
        XCTAssertEqual(game.completionNarrationID, "game.prophase.result")
        game.send(.advance)
        XCTAssertEqual(game.instructionNarrationID, "game.prometaphase.start")
        game.send(.openEnvelope)
        XCTAssertEqual(game.instructionNarrationID, "game.prometaphase.envelope-open")
        for pole in MitosisSession.Pole.allCases {
            game.send(.choosePole(pole))
            for id in 0..<4 { game.send(.attach(id)) }
        }
        game.send(.advance)
        XCTAssertEqual(game.instructionNarrationID, "game.metaphase.start")
        for id in 0..<4 { game.send(.align(id, nearEquator: true)) }
        XCTAssertEqual(game.instructionNarrationID, "game.metaphase.aligned")
        game.send(.inspectCheckpoint); game.send(.advance)
        XCTAssertEqual(game.instructionNarrationID, "game.anaphase.start")
        game.send(.separate); game.send(.advance)
        XCTAssertEqual(game.instructionNarrationID, "game.telophase.start")
        game.send(.rebuildNucleus(.left)); game.send(.rebuildNucleus(.right)); game.send(.advance)
        XCTAssertEqual(game.instructionNarrationID, "game.complete")
    }

    func testFailedPlaybackReturnsToQuiet() throws {
        let (narrator, playback) = try makeNarrator()
        playback.fail = true
        narrator.playOverview()
        XCTAssertFalse(narrator.isPlaying)
        XCTAssertFalse(narrator.isScheduled)
        XCTAssertEqual(narrator.mode, .quiet)
        XCTAssertNotNil(narrator.errorMessage)
    }

    func testActualLocalPlayerCompletionResetsState() async throws {
        let narrator = LessonNarrator.mitosis()
        defer { narrator.stop() }
        narrator.playStandalone("game.anaphase.start")
        XCTAssertTrue(narrator.isPlaying)
        let finished = expectation(description: "Bundled audio completes locally")
        let observation = narrator.$isPlaying.dropFirst().filter { !$0 }.sink { _ in finished.fulfill() }
        await fulfillment(of: [finished], timeout: 20)
        withExtendedLifetime(observation) {}
        XCTAssertFalse(narrator.isPlaying)
    }

    func testPlaybackRejectsNetworkResources() throws {
        let playback = LocalNarrationPlayback()
        let remote = try XCTUnwrap(URL(string: "https://example.com/recording.wav"))
        XCTAssertThrowsError(try playback.play(url: remote, token: UUID()))
    }

    func testSystemInterruptionAndBackgroundCancelQueuedWork() async throws {
        let (narrator, playback) = try makeNarrator()
        narrator.playOverview()
        playback.finish()
        NotificationCenter.default.post(name: AVAudioSession.interruptionNotification, object: nil,
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue])
        await settle()
        XCTAssertEqual(narrator.mode, .quiet)
        XCTAssertFalse(narrator.isScheduled)
        XCTAssertEqual(playback.starts.count, 1)
        NotificationCenter.default.post(name: AVAudioSession.interruptionNotification, object: nil,
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue])
        await settle()
        XCTAssertEqual(playback.starts.count, 1)
        narrator.startGameGuidance("game.prophase.start")
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        await settle()
        XCTAssertEqual(narrator.mode, .quiet)
        XCTAssertFalse(narrator.isPlaying)
    }
}
