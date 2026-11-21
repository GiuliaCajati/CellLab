import AVFAudio
import XCTest
@testable import CellLab

@MainActor private final class RespirationTestPlayback: NarrationPlayback {
    var onCompletion: ((UUID, Bool) -> Void)?
    var starts: [(String, UUID)] = []
    func play(url: URL, token: UUID) throws { starts.append((url.lastPathComponent, token)) }
    func stop() {}
    func finish(_ index: Int? = nil) { onCompletion?(starts[index ?? starts.count - 1].1, true) }
}

@MainActor final class RespirationNarrationTests: XCTestCase {
    func testEveryDescriptionDefinitionAndReferenceHasPlayableOfflineAudio() throws {
        let library = try NarrationLibrary.load(resource: "respiration-narration")
        XCTAssertEqual(library.recordings.count, 27)
        XCTAssertEqual(Set(library.recordings.map(\.id)).count, 27)
        XCTAssertEqual(library["lesson.overview"]?.text, RespirationNarration.overview)
        XCTAssertEqual(library["players.introduction"]?.text, RespirationNarration.playersIntroduction)
        XCTAssertEqual(library["reference.equation"]?.text, RespirationNarration.equation)
        for step in RespirationStep.allCases {
            let cue = try XCTUnwrap(library[step.narrationID])
            XCTAssertEqual(cue.text, step.narrationText)
            XCTAssertTrue(cue.text.hasSuffix(RespirationNarration.plain(step.content.bullets.joined(separator: " "))))
        }
        for player in RespirationPlayer.all {
            XCTAssertEqual(library[player.narrationID]?.text, player.narrationText)
        }
        for cue in library.recordings {
            XCTAssertFalse(cue.text.contains("**"), cue.id)
            let resource = cue.resource as NSString
            let url = try XCTUnwrap(Bundle.main.url(forResource: resource.deletingPathExtension,
                                                   withExtension: resource.pathExtension), cue.id)
            let audio = try AVAudioPlayer(contentsOf: url)
            XCTAssertGreaterThan(audio.duration, 0.5, cue.id)
            XCTAssertEqual(audio.numberOfChannels, 1, cue.id)
        }
    }

    private func makeNarrator(overview: String = "lesson.overview", phase: String = "lesson.glycolysis") throws
        -> (LessonNarrator, RespirationTestPlayback) {
        let playback = RespirationTestPlayback()
        let narrator = LessonNarrator(library: try NarrationLibrary.load(resource: "respiration-narration"),
                                     playback: playback, overviewCueID: overview, initialPhaseID: phase,
                                     phaseDelay: 0.01, overviewDelay: 0.01,
                                     resolveURL: { URL(fileURLWithPath: "/test/" + $0.resource) })
        return (narrator, playback)
    }
    private func settle() async { try? await Task.sleep(for: .milliseconds(70)) }

    func testOverviewContinuesToVisibleStepThenWaitsForSwipe() async throws {
        let (narrator, playback) = try makeNarrator()
        narrator.selectPhase("lesson.transition")
        narrator.playOverview()
        XCTAssertEqual(narrator.currentCueID, "lesson.overview")
        playback.finish()
        await settle()
        XCTAssertEqual(narrator.currentCueID, "lesson.transition")
        playback.finish()
        await settle()
        XCTAssertFalse(narrator.isPlaying)
        XCTAssertEqual(playback.starts.count, 2)
        narrator.selectPhase("lesson.krebs")
        await settle()
        XCTAssertEqual(narrator.currentCueID, "lesson.krebs")
        narrator.stop()
    }

    func testStopCancelsQueuedSpeechAndStandaloneReferencesCannotResumeLesson() async throws {
        let (narrator, playback) = try makeNarrator()
        narrator.playOverview()
        playback.finish()
        narrator.stop()
        await settle()
        XCTAssertEqual(playback.starts.count, 1)
        narrator.selectPhase("lesson.chemiosmosis")
        await settle()
        XCTAssertEqual(playback.starts.count, 1)
        narrator.playStandalone("reference.equation")
        playback.finish()
        await settle()
        XCTAssertEqual(playback.starts.count, 2)
        XCTAssertFalse(narrator.isScheduled)
        XCTAssertFalse(narrator.isPlaying)
        narrator.stop()
    }

    func testKeyPlayerIntroductionFollowsSelectionAndRejectsStaleCompletion() async throws {
        let (narrator, playback) = try makeNarrator(overview: "players.introduction", phase: "player.cytosol")
        narrator.playOverview()
        narrator.selectPhase("player.nad")
        narrator.selectPhase("player.synthase")
        playback.finish(0)
        await settle()
        XCTAssertEqual(narrator.currentCueID, "player.synthase")
        XCTAssertEqual(playback.starts.count, 2)
        narrator.stop()
        playback.finish(1)
        await settle()
        XCTAssertFalse(narrator.isScheduled)
        XCTAssertFalse(narrator.isPlaying)
    }
}
