import AVFAudio
import XCTest
@testable import CellLab

@MainActor private final class CycleNarrationPlayback: NarrationPlayback {
    var onCompletion: ((UUID, Bool) -> Void)?
    var starts: [(String, UUID)] = []
    func play(url: URL, token: UUID) throws { starts.append((url.lastPathComponent, token)) }
    func stop() {}
    func finish(_ index: Int? = nil) { onCompletion?(starts[index ?? starts.count - 1].1, true) }
}

@MainActor final class CellCycleNarrationTests: XCTestCase {
    func testAllDisplayedPhaseVariantsAndKeyPlayersHaveOfflineRecordings() throws {
        let library = try NarrationLibrary.load(resource: "cell-cycle-narration")
        XCTAssertEqual(library.lessonTitle, "Cell Life Cycle")
        XCTAssertEqual(library.recordings.count, 18)
        XCTAssertEqual(Set(library.recordings.map(\.id)).count, library.recordings.count)
        XCTAssertEqual(library["lesson.overview"]?.text, CellCycleNarration.overview)
        XCTAssertTrue(CellCycleNarration.overview.hasPrefix("Fun fact! Most brain cells"))
        for phase in CellCyclePhase.allCases {
            for step in CellCycleMitosisStep.allCases {
                for kind in CellCycleCellKind.allCases {
                    let id = CellCycleNarration.cueID(phase: phase, step: step, kind: kind)
                    let cue = try XCTUnwrap(library[id], id)
                    XCTAssertEqual(cue.text, CellCycleNarration.phaseText(phase, step: step, kind: kind), id)
                    XCTAssertFalse(cue.text.contains("**"), id)
                }
            }
        }
        for player in CellCyclePlayer.all {
            XCTAssertEqual(library[player.narrationID]?.text, player.narrationText)
        }
        for cue in library.recordings {
            let path = cue.resource as NSString
            let url = try XCTUnwrap(Bundle.main.url(forResource: path.deletingPathExtension,
                                                   withExtension: path.pathExtension), cue.id)
            let audio = try AVAudioPlayer(contentsOf: url)
            XCTAssertGreaterThan(audio.duration, 0.5, cue.id)
            XCTAssertEqual(audio.numberOfChannels, 1, cue.id)
        }
    }

    private func makeNarrator() throws -> (LessonNarrator, CycleNarrationPlayback) {
        let playback = CycleNarrationPlayback()
        let narrator = LessonNarrator(library: try NarrationLibrary.load(resource: "cell-cycle-narration"),
                                     playback: playback, initialPhaseID: "phase.g1",
                                     phaseDelay: 0.01, overviewDelay: 0.01,
                                     resolveURL: { URL(fileURLWithPath: "/test/" + $0.resource) })
        return (narrator, playback)
    }
    private func settle() async { try? await Task.sleep(for: .milliseconds(70)) }

    func testFunFactContinuesToSelectedPhaseThenWaits() async throws {
        let (narrator, playback) = try makeNarrator()
        narrator.selectPhase("phase.g0")
        narrator.playOverview()
        XCTAssertEqual(narrator.currentCueID, "lesson.overview")
        playback.finish()
        await settle()
        XCTAssertEqual(narrator.currentCueID, "phase.g0")
        playback.finish()
        await settle()
        XCTAssertEqual(playback.starts.count, 2)
        XCTAssertFalse(narrator.isPlaying)
        narrator.stop()
    }

    func testSubstageAndCellTypeChangesCancelOldSpeechAndStopCancelsQueuedClip() async throws {
        let (narrator, playback) = try makeNarrator()
        narrator.playOverview()
        narrator.selectPhase("phase.mitosis.metaphase")
        narrator.selectPhase("phase.cytokinesis.plant")
        playback.finish(0)
        await settle()
        XCTAssertEqual(narrator.currentCueID, "phase.cytokinesis.plant")
        XCTAssertEqual(playback.starts.count, 2)
        narrator.selectPhase("phase.cytokinesis.animal")
        narrator.stop()
        await settle()
        narrator.selectPhase("phase.s")
        await settle()
        XCTAssertEqual(playback.starts.count, 2)
        XCTAssertFalse(narrator.isPlaying)
        XCTAssertFalse(narrator.isScheduled)
    }
}
