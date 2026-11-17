import AVFAudio
import XCTest
@testable import CellLab

@MainActor private final class SPhaseTestPlayback: NarrationPlayback {
    var onCompletion: ((UUID, Bool) -> Void)?
    var starts: [(String, UUID)] = []
    func play(url: URL, token: UUID) throws { starts.append((url.deletingPathExtension().lastPathComponent, token)) }
    func stop() {}
    func finish(_ index: Int? = nil) { onCompletion?(starts[index ?? starts.count - 1].1, true) }
}

@MainActor final class SPhaseNarrationTests: XCTestCase {
    func testEveryRecordingIsBundledDecodableAndSeparateFromTheOtherLessons() throws {
        let library = try NarrationLibrary.load(resource: "sphase-narration")
        XCTAssertEqual(library.lessonTitle, "S phase")
        XCTAssertEqual(Set(library.recordings.map(\.id)).count, library.recordings.count)
        XCTAssertGreaterThan(library.recordings.count, 50)
        let others = try ["mitosis-narration", "meiosis-narration"].flatMap {
            try NarrationLibrary.load(resource: $0).recordings.map(\.resource)
        }
        XCTAssertTrue(Set(library.recordings.map(\.resource)).isDisjoint(with: others))
        for cue in library.recordings {
            let path = cue.resource as NSString
            let url = try XCTUnwrap(Bundle.main.url(forResource: path.deletingPathExtension, withExtension: path.pathExtension), cue.id)
            let player = try AVAudioPlayer(contentsOf: url)
            XCTAssertGreaterThan(player.duration, 0.5, cue.id)
            XCTAssertEqual(player.numberOfChannels, 1, cue.id)
            XCTAssertFalse(cue.text.contains("READ_"), cue.id)
        }
    }

    func testAllNineDescriptionsAndEveryVocabularyDefinitionUseTheDisplayedText() throws {
        let library = try NarrationLibrary.load(resource: "sphase-narration")
        for step in DNAReplicationStep.carouselCases {
            let cue = try XCTUnwrap(library[step.narrationID])
            let paragraphs = cue.text.components(separatedBy: "\n\n")
            XCTAssertEqual(paragraphs.count, 2, cue.id)
            XCTAssertEqual(paragraphs.last, step.narrationDescription, cue.id)
            XCTAssertEqual(paragraphs.first?.filter { ".!?".contains($0) }.count, 1, cue.id)
        }
        for player in DNAReplicationPlayer.all {
            XCTAssertEqual(library[player.narrationID]?.text, player.narrationText, player.id)
        }
        for term in DNACopyTerm.all {
            XCTAssertEqual(library[term.narrationID]?.text, term.narrationText, term.id)
        }
    }

    func testEveryGameInstructionAndCompletionMatchesTheLiveAction() throws {
        let library = try NarrationLibrary.load(resource: "sphase-narration")
        let session = DNACopySession()
        var seen: Set<String> = []
        for _ in 0..<80 {
            if let card = session.celebration {
                let cue = try XCTUnwrap(library[card.narrationID], card.narrationID)
                XCTAssertEqual(cue.text, card.narrationText)
                seen.insert(cue.id)
                session.continueAfterCelebration()
                continue
            }
            let cue = try XCTUnwrap(library[session.instructionNarrationID], session.instructionNarrationID)
            seen.insert(cue.id)
            if session.stage == .origin {
                XCTAssertTrue(cue.text.hasSuffix("\n\n" + session.instruction))
                XCTAssertTrue(cue.text.hasPrefix("Your turn to join the copying crew!"))
                session.start(at: 2)
            } else if session.stage == .complete {
                XCTAssertEqual(cue.text, session.instruction)
                break
            } else {
                XCTAssertEqual(cue.text, session.instruction)
                let target = try XCTUnwrap(session.activeTarget)
                if let base = session.expectedBase {
                    if session.stage == .replace { session.choose(tool: .polymerase) }
                    XCTAssertTrue(session.add(base, at: target))
                } else {
                    XCTAssertTrue(session.use(try XCTUnwrap(session.neededTool), at: target))
                }
            }
        }
        XCTAssertEqual(session.stage, .complete)
        XCTAssertEqual(session.placedBases, 16)
        XCTAssertEqual(seen, Set(library.recordings.filter { $0.id.hasPrefix("game.") }.map(\.id)))
    }

    func testOverviewHandsOffAndRapidSwipesStopAndObsoleteCompletionsStayQuiet() async throws {
        let library = try NarrationLibrary.load(resource: "sphase-narration")
        let playback = SPhaseTestPlayback()
        let narrator = LessonNarrator(library: library, playback: playback,
                                     initialPhaseID: DNAReplicationStep.origins.narrationID,
                                     phaseNames: Dictionary(uniqueKeysWithValues: DNAReplicationStep.carouselCases.map { ($0.narrationID, $0.content.title) }),
                                     phaseDelay: 0.02, overviewDelay: 0.02) { URL(fileURLWithPath: "/test/" + $0.resource) }
        XCTAssertEqual(narrator.lessonButtonTitle, "Hear overview")
        narrator.toggleLesson()
        playback.finish()
        try await Task.sleep(for: .milliseconds(80))
        XCTAssertEqual(playback.starts.last?.0, "sphase.lesson.origins")
        playback.finish()
        XCTAssertEqual(narrator.lessonButtonTitle, "Replay Origins of replication")
        narrator.selectPhase("lesson.unzip")
        narrator.selectPhase("lesson.stabilize")
        try await Task.sleep(for: .milliseconds(80))
        XCTAssertEqual(playback.starts.last?.0, "sphase.lesson.stabilize")
        let count = playback.starts.count
        narrator.selectPhase("lesson.stabilize")
        XCTAssertEqual(playback.starts.count, count)
        narrator.selectPhase("lesson.build")
        narrator.stop()
        playback.finish(0)
        try await Task.sleep(for: .milliseconds(80))
        XCTAssertEqual(playback.starts.count, count)
        XCTAssertFalse(narrator.isPlaying)
        narrator.playStandalone("player.helicase")
        narrator.selectPhase("lesson.seal")
        try await Task.sleep(for: .milliseconds(80))
        XCTAssertEqual(playback.starts.last?.0, "sphase.player.helicase")
        narrator.stop()
    }
}
