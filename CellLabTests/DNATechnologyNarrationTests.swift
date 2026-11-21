import AVFAudio
import XCTest
@testable import CellLab

@MainActor private final class DTTestNarrationPlayback: NarrationPlayback {
    var onCompletion: ((UUID, Bool) -> Void)?
    var starts: [(String, UUID)] = []
    func play(url: URL, token: UUID) throws { starts.append((url.lastPathComponent, token)) }
    func stop() {}
    func finish(_ index: Int? = nil) { onCompletion?(starts[index ?? starts.count - 1].1, true) }
}

@MainActor final class DNATechnologyNarrationTests: XCTestCase {
    func testAllTopicsStagesNotesAndDefinitionsHavePlayableOfflineRecordings() throws {
        let library = try NarrationLibrary.load(resource:"dna-technology-narration")
        let stageCount = DTTopic.allCases.reduce(0) { $0 + $1.article.stages.count }
        XCTAssertEqual(library.recordings.count,stageCount + DTTerm.all.count + 3)
        XCTAssertEqual(library.recordings.count,106)
        XCTAssertEqual(Set(library.recordings.map(\.id)).count,106)
        XCTAssertEqual(library["lesson.overview"]?.text,DNATechnologyNarration.overview)
        XCTAssertEqual(library["tools.overview"]?.text,DNATechnologyNarration.toolsOverview)
        XCTAssertEqual(library["reference.pcr-counter"]?.text,DNATechnologyNarration.pcrCounter)
        for topic in DTTopic.allCases {
            for stage in topic.article.stages {
                let cue = try XCTUnwrap(library[topic.narrationID(for:stage)])
                XCTAssertEqual(cue.text,topic.narrationText(for:stage))
                for text in [stage.heading,stage.summary] + stage.bullets {
                    XCTAssertTrue(cue.text.contains(text),cue.id)
                }
                let scene = try XCTUnwrap(DTScene.all[topic.rawValue + "-" + stage.id])
                XCTAssertTrue(cue.text.contains(scene.note),cue.id)
            }
        }
        for term in DTTerm.all { XCTAssertEqual(library[term.narrationID]?.text,term.narrationText) }
        for cue in library.recordings {
            let resource = cue.resource as NSString
            let url = try XCTUnwrap(Bundle.main.url(forResource:resource.deletingPathExtension,
                                                   withExtension:resource.pathExtension),cue.id)
            XCTAssertTrue(url.isFileURL)
            let audio = try AVAudioPlayer(contentsOf:url)
            XCTAssertGreaterThan(audio.duration,0.5,cue.id)
            XCTAssertEqual(audio.numberOfChannels,1,cue.id)
        }
    }

    private func makeNarrator() throws -> (LessonNarrator,DTTestNarrationPlayback) {
        let playback = DTTestNarrationPlayback()
        let narrator = LessonNarrator(library:try NarrationLibrary.load(resource:"dna-technology-narration"),
                                     playback:playback,initialPhaseID:"lesson.pcr.heat",
                                     phaseDelay:0.01,overviewDelay:0.01,
                                     resolveURL:{ URL(fileURLWithPath:"/test/" + $0.resource) })
        return (narrator,playback)
    }
    private func settle() async { try? await Task.sleep(for:.milliseconds(70)) }

    func testOpeningContinuesToChosenStepAndTopicChangesReplaceSpeech() async throws {
        let (narrator,playback) = try makeNarrator()
        narrator.selectPhase("lesson.pcr.prime")
        narrator.playOverview()
        XCTAssertEqual(narrator.currentCueID,"lesson.overview")
        playback.finish()
        await settle()
        XCTAssertEqual(narrator.currentCueID,"lesson.pcr.prime")
        playback.finish()
        await settle()
        XCTAssertFalse(narrator.isPlaying)
        XCTAssertEqual(playback.starts.count,2)
        narrator.selectPhase("lesson.editing.guide")
        narrator.selectPhase("lesson.editing.repair")
        playback.finish(1)
        await settle()
        XCTAssertEqual(narrator.currentCueID,"lesson.editing.repair")
        XCTAssertEqual(playback.starts.count,3)
        narrator.stop()
    }

    func testStopCancelsQueuedStepsAndReferencesDoNotResumeLesson() async throws {
        let (narrator,playback) = try makeNarrator()
        narrator.playOverview()
        playback.finish()
        narrator.stop()
        await settle()
        narrator.selectPhase("lesson.pcr.extend")
        await settle()
        XCTAssertEqual(playback.starts.count,1)
        narrator.playStandalone("reference.pcr-counter")
        playback.finish()
        await settle()
        XCTAssertEqual(playback.starts.count,2)
        narrator.playStandalone("term.taq")
        playback.finish()
        await settle()
        XCTAssertEqual(playback.starts.count,3)
        XCTAssertFalse(narrator.isPlaying)
        XCTAssertFalse(narrator.isScheduled)
        narrator.stop()
    }
}
