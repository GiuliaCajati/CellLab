import AVFAudio
import XCTest
@testable import CellLab

@MainActor private final class CSNarrationPlayback: NarrationPlayback {
    var onCompletion: ((UUID, Bool) -> Void)?
    var starts: [(String, UUID)] = []
    func play(url: URL, token: UUID) throws { starts.append((url.deletingPathExtension().lastPathComponent, token)) }
    func stop() {}
    func finish(_ index: Int? = nil) { onCompletion?(starts[index ?? starts.count - 1].1, true) }
}

@MainActor final class CellStructuresNarrationTests: XCTestCase {
    func testEveryStructureAndItsDetailsHavePlayableOfflineRecordingsFromTheDisplayedText() throws {
        let library = try NarrationLibrary.load(resource: "cell-structures-narration")
        XCTAssertEqual(library.lessonTitle, "Cell Structures")
        XCTAssertEqual(library.recordings.count, CSPart.allCases.count * 2 + 1)
        XCTAssertEqual(Set(library.recordings.map(\.id)).count, library.recordings.count)
        XCTAssertEqual(library["lesson.overview"]?.text, CSNarrationText.overview)
        for part in CSPart.allCases {
            let explanation = try XCTUnwrap(library[part.narrationID])
            XCTAssertEqual(explanation.title, part.content.title)
            XCTAssertTrue(explanation.text.contains(part.content.summary), part.id)
            XCTAssertTrue(explanation.text.contains(part.content.action), part.id)
            let details = try XCTUnwrap(library[part.detailNarrationID])
            for paragraph in part.content.details {
                XCTAssertTrue(details.text.contains(paragraph), part.id)
            }
        }
        for cue in library.recordings {
            XCTAssertTrue(cue.resource.hasPrefix("cell-structures."))
            let path = cue.resource as NSString
            let url = try XCTUnwrap(Bundle.main.url(forResource: path.deletingPathExtension, withExtension: path.pathExtension), cue.id)
            let audio = try AVAudioPlayer(contentsOf: url)
            XCTAssertGreaterThan(audio.duration, 0.5, cue.id)
            XCTAssertEqual(audio.numberOfChannels, 1, cue.id)
        }
    }

    private func makeNarrator() throws -> (LessonNarrator, CSNarrationPlayback) {
        let playback = CSNarrationPlayback()
        let narrator = LessonNarrator(library: try NarrationLibrary.load(resource: "cell-structures-narration"),
                                     playback: playback, initialPhaseID: CSPart.nucleus.narrationID,
                                     phaseDelay: 0.01, overviewDelay: 0.01,
                                     resolveURL: { URL(fileURLWithPath: "/test/" + $0.resource) })
        return (narrator, playback)
    }
    private func settle() async { try? await Task.sleep(for: .milliseconds(70)) }

    func testOverviewExplainsNucleusAndWaitsForAnotherSelection() async throws {
        XCTAssertEqual(LessonNarrator.cellStructures().visiblePhase, CSPart.nucleus.narrationID)
        let (narrator, playback) = try makeNarrator()
        XCTAssertFalse(narrator.isPlaying)
        narrator.toggleLesson()
        XCTAssertEqual(narrator.currentCueID, "lesson.overview")
        playback.finish()
        await settle()
        XCTAssertEqual(narrator.currentCueID, CSPart.nucleus.narrationID)
        playback.finish()
        await settle()
        XCTAssertEqual(playback.starts.count, 2)
        XCTAssertFalse(narrator.isPlaying)
        narrator.stop()
    }

    func testSelectionInterruptsOldSpeechAndStopCancelsPendingExplanations() async throws {
        let (narrator, playback) = try makeNarrator()
        narrator.playOverview()
        narrator.selectPhase(CSPart.nucleolus.narrationID)
        narrator.selectPhase(CSPart.mitochondria.narrationID)
        playback.finish(0)
        await settle()
        XCTAssertEqual(narrator.currentCueID, CSPart.mitochondria.narrationID)
        XCTAssertEqual(playback.starts.count, 2)
        narrator.selectPhase(CSPart.golgi.narrationID)
        narrator.stop()
        await settle()
        narrator.selectPhase(CSPart.membrane.narrationID)
        await settle()
        XCTAssertEqual(playback.starts.count, 2)
        XCTAssertFalse(narrator.isPlaying)
        XCTAssertFalse(narrator.isScheduled)
    }

    func testOptionalDetailsNeverStartAnAutomaticTour() async throws {
        let (narrator, playback) = try makeNarrator()
        narrator.playStandalone(CSPart.nucleus.detailNarrationID)
        playback.finish()
        await settle()
        narrator.selectPhase(CSPart.ribosomes.narrationID)
        await settle()
        XCTAssertEqual(playback.starts.count, 1)
        XCTAssertFalse(narrator.isPlaying)
        XCTAssertEqual(narrator.mode, .quiet)
    }
}
