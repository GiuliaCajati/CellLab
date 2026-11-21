import AVFAudio
import XCTest
@testable import CellLab

@MainActor private final class HomeTestPlayback: NarrationPlayback {
    var onCompletion: ((UUID, Bool) -> Void)?
    var starts: [(String, UUID)] = []
    func play(url: URL, token: UUID) throws { starts.append((url.lastPathComponent, token)) }
    func stop() {}
    func finish(_ index: Int) { onCompletion?(starts[index].1, true) }
}

@MainActor final class HomeGuideTests: XCTestCase {
    func testTourMatchesCardsAndEveryClipPlaysOffline() throws {
        XCTAssertEqual(Set(CellLabHomeModule.allCases.filter(\.hasGame)), [.mitosis, .meiosis, .sphase, .dogma])
        let library = try NarrationLibrary.load(resource: "home-narration")
        XCTAssertEqual(library.recordings.count, 9)
        XCTAssertEqual(Set(library.recordings.map(\.id)).count, 9)
        XCTAssertEqual(library["home.overview"]?.text, CellLabHomeNarration.welcome)
        for module in CellLabHomeModule.allCases {
            let cue = try XCTUnwrap(library[module.cueID])
            XCTAssertEqual(cue.text, module.narrationText)
            XCTAssertEqual(cue.title, module.title)
            XCTAssertTrue(cue.text.hasPrefix(module.overview))
            if let game = module.gameSummary { XCTAssertTrue(cue.text.hasSuffix(game)) }
        }
        for cue in library.recordings {
            let path = cue.resource as NSString
            let url = try XCTUnwrap(Bundle.main.url(forResource: path.deletingPathExtension, withExtension: path.pathExtension))
            let audio = try AVAudioPlayer(contentsOf: url)
            XCTAssertGreaterThan(audio.duration, 1, cue.id)
            XCTAssertEqual(audio.numberOfChannels, 1, cue.id)
        }
    }

    func testPreviewsWaitForTapAndStopRejectsOldCompletion() async throws {
        let playback = HomeTestPlayback()
        let narrator = LessonNarrator(library: try NarrationLibrary.load(resource: "home-narration"), playback: playback,
                                     overviewCueID: "home.overview", initialPhaseID: "home.overview",
                                     phaseDelay: 0.01, overviewDelay: 0.01,
                                     resolveURL: { URL(fileURLWithPath: "/test/" + $0.resource) })
        narrator.playStandalone("home.overview")
        playback.finish(0)
        try await Task.sleep(for: .milliseconds(70))
        XCTAssertEqual(playback.starts.count, 1)
        XCTAssertFalse(narrator.isPlaying)
        XCTAssertFalse(narrator.isScheduled)
        narrator.playStandalone(CellLabHomeModule.mitosis.cueID)
        narrator.playStandalone(CellLabHomeModule.cycle.cueID)
        playback.finish(1)
        XCTAssertTrue(narrator.isPlaying)
        XCTAssertEqual(narrator.currentCueID, CellLabHomeModule.cycle.cueID)
        narrator.stop()
        playback.finish(2)
        try await Task.sleep(for: .milliseconds(70))
        XCTAssertFalse(narrator.isPlaying)
        XCTAssertFalse(narrator.isScheduled)
        XCTAssertEqual(playback.starts.count, 3)
    }
}
