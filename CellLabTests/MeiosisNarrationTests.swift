import AVFAudio
import XCTest
@testable import CellLab

@MainActor
private final class MeiosisTestPlayback: NarrationPlayback {
    var onCompletion: ((UUID, Bool) -> Void)?
    var starts: [(String, UUID)] = []
    func play(url: URL, token: UUID) throws { starts.append((url.deletingPathExtension().lastPathComponent, token)) }
    func stop() {}
    func finish(_ index: Int? = nil) { onCompletion?(starts[index ?? starts.count - 1].1, true) }
}

@MainActor
final class MeiosisNarrationTests: XCTestCase {
    func testEveryCueIsBundledDecodableAndDistinctFromMitosis() throws {
        let library = try NarrationLibrary.load(resource: "meiosis-narration")
        let mitosis = try NarrationLibrary.load(resource: "mitosis-narration")
        XCTAssertEqual(library.lessonTitle, "Meiosis")
        XCTAssertEqual(library.recordings.count, 64)
        XCTAssertEqual(Set(library.recordings.map(\.id)).count, 64)
        XCTAssertTrue(Set(library.recordings.map(\.resource)).isDisjoint(with: mitosis.recordings.map(\.resource)))
        for cue in library.recordings {
            let path = cue.resource as NSString
            let url = try XCTUnwrap(Bundle.main.url(forResource: path.deletingPathExtension, withExtension: path.pathExtension))
            let player = try AVAudioPlayer(contentsOf: url)
            XCTAssertGreaterThan(player.duration, 0.5, cue.id)
            XCTAssertEqual(player.numberOfChannels, 1, cue.id)
            XCTAssertFalse(cue.text.contains("READ_PHASE_DESCRIPTION"))
        }
    }

    func testEveryPhaseTranscriptReadsItsActualOnScreenDescription() throws {
        let library = try NarrationLibrary.load(resource: "meiosis-narration")
        for phase in MeiPhase.allCases {
            let cue = try XCTUnwrap(library[phase.narrationID])
            let paragraphs = cue.text.components(separatedBy: "\n\n")
            XCTAssertEqual(paragraphs.count, 2, cue.id)
            let description = phase.explanation.split(separator: "\n").map {
                String($0).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "• ", with: "")
            }.joined(separator: " ")
            XCTAssertEqual(paragraphs.last, description, cue.id)
            XCTAssertEqual(paragraphs.first?.filter { ".!?".contains($0) }.count, 1, cue.id)
        }
    }

    func testOverviewHandsOffToProphaseOneAndSwipesUseRomanNumeralNames() async throws {
        let playback = MeiosisTestPlayback()
        let library = try NarrationLibrary.load(resource: "meiosis-narration")
        let narrator = LessonNarrator(library: library, playback: playback,
                                     initialPhaseID: MeiPhase.prophaseI.narrationID,
                                     phaseNames: Dictionary(uniqueKeysWithValues: MeiPhase.allCases.map { ($0.narrationID, $0.title) }),
                                     phaseDelay: 0.02, overviewDelay: 0.02) {
            URL(fileURLWithPath: "/test/" + $0.resource)
        }
        XCTAssertEqual(narrator.lessonButtonTitle, "Hear overview")
        XCTAssertTrue(playback.starts.isEmpty)
        narrator.toggleLesson()
        playback.finish()
        try await Task.sleep(for: .milliseconds(80))
        XCTAssertEqual(playback.starts.last?.0, "meiosis.lesson.prophase-i")
        playback.finish()
        XCTAssertEqual(narrator.lessonButtonTitle, "Replay Prophase I")
        narrator.selectPhase(MeiPhase.metaphaseI.narrationID)
        narrator.selectPhase(MeiPhase.prophaseII.narrationID)
        try await Task.sleep(for: .milliseconds(80))
        XCTAssertEqual(playback.starts.last?.0, "meiosis.lesson.prophase-ii")
        narrator.stop()
        narrator.selectPhase(MeiPhase.telophaseII.narrationID)
        try await Task.sleep(for: .milliseconds(80))
        XCTAssertEqual(playback.starts.count, 3)
        XCTAssertEqual(narrator.lessonButtonTitle, "Hear Telophase II")
    }

    func testEveryReachableGameInstructionAndPopupMatchesItsRecording() throws {
        let library = try NarrationLibrary.load(resource: "meiosis-narration")
        var seen: Set<String> = []
        for orientation in [[true, true], [true, false], [false, true], [false, false]] {
            var session = MeiosisSession(maternalLeft: orientation)
            func verify() throws {
                let id = session.canAdvance ? session.completionNarrationID : session.instructionNarrationID
                let cue = try XCTUnwrap(library[id], id)
                seen.insert(id)
                if session.canAdvance {
                    let popup = MeiosisPopup.completed(session)
                    let text = popup.explanation.replacingOccurrences(of: "✅ ", with: "")
                        + (popup.showsTakeaway ? "\n\n" + popup.takeaway : "")
                    XCTAssertEqual(cue.text, text, id)
                } else {
                    XCTAssertTrue(cue.text.hasPrefix(session.instruction), id)
                }
            }
            func send(_ action: MeiosisSession.Action) throws {
                session.send(action)
                XCTAssertFalse(session.needsCorrection)
                try verify()
            }
            try verify()
            for id in 0..<4 { try send(.condenseI(id)) }
            try send(.openEnvelopeI)
            for pair in 0..<2 { try send(.synapse(pair, matched: true)) }
            for pair in 0..<2 { try send(.crossOver(pair, matched: true)) }
            try send(.advance)
            for id in 0..<4 { try send(.choosePole(session.poleForHomolog(id))); try send(.attachI(id)) }
            for pair in 0..<2 { try send(.alignI(pair, nearEquator: true)) }
            try send(.inspectI); try send(.advance)
            try send(.protectCentromeres); try send(.separateHomologs); try send(.advance)
            for cell in 0..<2 { try send(.rebuildI(cell)) }
            try send(.divideI); try send(.advance)
            try send(.blockReplication); try send(.makeInterkinesisProteins); try send(.advance)
            for id in 0..<4 { try send(.condenseII(id)) }
            for cell in 0..<2 { try send(.openEnvelopeII(cell)) }
            try send(.advance)
            for pole in [MeiosisSession.Pole.top, .bottom] {
                try send(.choosePole(pole))
                for id in 0..<4 { try send(.attachII(id)) }
            }
            for id in 0..<4 { try send(.alignII(id, nearEquator: true)) }
            try send(.inspectII); try send(.advance)
            try send(.splitCentromeres); try send(.separateSisters); try send(.advance)
            for product in 0..<4 { try send(.rebuildII(product)) }
            try send(.relaxChromosomes); try send(.divideII); try send(.advance)
            XCTAssertEqual(session.stage, .complete)
        }
        XCTAssertEqual(seen.count, 33)
    }
}
