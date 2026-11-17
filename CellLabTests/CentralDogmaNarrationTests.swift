import AVFAudio
import XCTest
@testable import CellLab

@MainActor private final class CentralDogmaTestPlayback: NarrationPlayback {
    var onCompletion: ((UUID, Bool) -> Void)?
    var starts: [(String, UUID)] = []
    func play(url: URL, token: UUID) throws { starts.append((url.deletingPathExtension().lastPathComponent, token)) }
    func stop() {}
    func finish(_ index: Int? = nil) { onCompletion?(starts[index ?? starts.count - 1].1, true) }
}

@MainActor final class CentralDogmaNarrationTests: XCTestCase {
    func testAllClipsAreBundledOfflineAndMatchTheLessonAndVocabulary() throws {
        let library = try NarrationLibrary.load(resource: "central-dogma-narration")
        XCTAssertEqual(library.lessonTitle, "Central Dogma")
        XCTAssertEqual(Set(library.recordings.map(\.id)).count, library.recordings.count)
        XCTAssertGreaterThan(library.recordings.count, 50)
        for cue in library.recordings {
            XCTAssertTrue(cue.resource.hasPrefix("central-dogma."), cue.id)
            let path = cue.resource as NSString
            let url = try XCTUnwrap(Bundle.main.url(forResource: path.deletingPathExtension, withExtension: path.pathExtension), cue.id)
            let audio = try AVAudioPlayer(contentsOf: url)
            XCTAssertGreaterThan(audio.duration, 0.5, cue.id)
            XCTAssertEqual(audio.numberOfChannels, 1, cue.id)
        }
        XCTAssertEqual(library["lesson.overview"]?.text, CentralDogmaNarrationText.overview)
        for step in CentralDogmaStep.allCases {
            XCTAssertEqual(library[step.narrationID]?.text, step.narrationText)
            XCTAssertEqual(step.narrationText.components(separatedBy: "\n\n").last, step.narrationDescription)
        }
        for player in CentralDogmaPlayer.all {
            XCTAssertEqual(library[player.narrationID]?.text, player.narrationText)
        }
    }

    func testEveryMissionInstructionAndCheckpointUsesItsDisplayedWords() throws {
        let library = try NarrationLibrary.load(resource: "central-dogma-narration")
        let game = CentralDogmaGameSession()
        for _ in CentralDogmaGameData.shared.missions {
            while let step = game.step {
                if let milestone = game.pending {
                    XCTAssertEqual(library[milestone.narrationID]?.text, milestone.narrationText)
                    game.continueAfterCheckpoint()
                }
                XCTAssertEqual(library[step.narrationID]?.text, step.instruction)
                let payload = step.uniqueGroup == nil ? step.payload
                    : try XCTUnwrap(step.options.first { !game.usedPieces.contains($0.payload) }).payload
                let target = step.uniqueGroup == nil ? step.target
                    : try XCTUnwrap((0..<4).map { "hemoglobin:\($0)" }.first { !game.usedSlots.contains($0) })
                XCTAssertTrue(game.submit(payload, target: target, stepID: step.id), step.id)
            }
            let checkpoint = try XCTUnwrap(game.pending)
            XCTAssertEqual(library[checkpoint.narrationID]?.text, checkpoint.narrationText)
            game.continueAfterCheckpoint()
            XCTAssertTrue(game.isComplete)
            game.restart()
        }
    }

    private func makeNarrator() throws -> (LessonNarrator, CentralDogmaTestPlayback) {
        let playback = CentralDogmaTestPlayback()
        let narrator = LessonNarrator(library: try NarrationLibrary.load(resource: "central-dogma-narration"),
                                     playback: playback, initialPhaseID: CentralDogmaStep.transcriptionStart.narrationID,
                                     phaseDelay: 0.01, overviewDelay: 0.01,
                                     resolveURL: { URL(fileURLWithPath: "/test/" + $0.resource) })
        return (narrator, playback)
    }
    private func settle() async { try? await Task.sleep(for: .milliseconds(60)) }

    func testOverviewHandsOffToFindTheGeneAndThenWaitsForASwipe() async throws {
        XCTAssertEqual(LessonNarrator.centralDogma().visiblePhase, CentralDogmaStep.transcriptionStart.narrationID)
        let (narrator, playback) = try makeNarrator()
        XCTAssertFalse(narrator.isPlaying)
        narrator.toggleLesson()
        XCTAssertEqual(narrator.currentCueID, "lesson.overview")
        playback.finish()
        await settle()
        XCTAssertEqual(narrator.currentCueID, CentralDogmaStep.transcriptionStart.narrationID)
        playback.finish()
        await settle()
        XCTAssertEqual(playback.starts.count, 2)
        XCTAssertFalse(narrator.isPlaying)
        narrator.stop()
    }

    func testSwipeCancelsOldClipAndStopCancelsPendingSpeech() async throws {
        let (narrator, playback) = try makeNarrator()
        narrator.playOverview()
        narrator.selectPhase(CentralDogmaStep.transcriptionBuild.narrationID)
        narrator.selectPhase(CentralDogmaStep.processing.narrationID)
        playback.finish(0)
        await settle()
        XCTAssertEqual(narrator.currentCueID, CentralDogmaStep.processing.narrationID)
        XCTAssertEqual(playback.starts.count, 2)
        narrator.selectPhase(CentralDogmaStep.translationStart.narrationID)
        narrator.stop()
        await settle()
        XCTAssertEqual(playback.starts.count, 2)
        narrator.selectPhase(CentralDogmaStep.translationEnd.narrationID)
        await settle()
        XCTAssertFalse(narrator.isPlaying)
        XCTAssertEqual(playback.starts.count, 2)
    }

    func testVocabularyAndGameKeepTheirAudioSeparateFromLessonPlayback() async throws {
        let (narrator, playback) = try makeNarrator()
        narrator.playStandalone(CentralDogmaPlayer.all[0].narrationID)
        playback.finish()
        await settle()
        XCTAssertEqual(playback.starts.count, 1)
        let steps = CentralDogmaGameData.shared.missions[0].steps
        narrator.startGameGuidance(steps[0].narrationID)
        narrator.gameEventChanged(steps[1].narrationID)
        playback.finish(1) // A stale completion must never restart the overview.
        XCTAssertEqual(narrator.currentCueID, steps[1].narrationID)
        narrator.stop()
        narrator.gameEventChanged(steps[2].narrationID)
        XCTAssertFalse(narrator.isPlaying)
        XCTAssertEqual(playback.starts.count, 3)
    }
}
