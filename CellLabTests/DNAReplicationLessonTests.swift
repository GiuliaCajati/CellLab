import XCTest
@testable import CellLab

@MainActor
final class DNAReplicationLessonTests: XCTestCase {
    func testNewClockOwnerTakesOverWithoutDoubleSpeed() async throws {
        let session = DNAReplicationSession()
        session.select(.unzip, play: true)
        let first = Task { await session.run() }
        try await Task.sleep(for: .milliseconds(200))
        let before = session.progress
        let started = Date()
        let second = Task { await session.run() }
        try await Task.sleep(for: .milliseconds(600))
        session.isPlaying = false
        let elapsed = Date().timeIntervalSince(started)
        first.cancel(); second.cancel()
        XCTAssertEqual(session.progress - before, elapsed / 6, accuracy: 0.025)
        await first.value
        await second.value
    }

    func testEveryPreparationAndCopyingStepIsReachableInOrder() {
        let steps = DNAReplicationStep.carouselCases
        XCTAssertEqual(steps, [.origins, .unzip, .stabilize, .prime, .build, .proofread, .replace, .seal, .result])
        XCTAssertNil(steps.first?.previous)
        XCTAssertNil(steps.last?.next)
        for index in 0..<(steps.count - 1) {
            XCTAssertEqual(steps[index].next, steps[index + 1])
            XCTAssertEqual(steps[index + 1].previous, steps[index])
        }
        XCTAssertEqual(DNAReplicationSession().step, .origins)
    }

    func testSelectedHelicaseAnimationEndsAndWaitsOnTheSameCard() {
        let session = DNAReplicationSession()
        session.select(.unzip, play: true)
        session.advance(by: 2)
        XCTAssertGreaterThan(session.progress, 0)
        XCTAssertLessThan(session.progress, 1)
        session.advance(by: 10)
        XCTAssertEqual(session.step, .unzip)
        XCTAssertEqual(session.progress, 1)
        XCTAssertFalse(session.isPlaying)
        session.advance(by: 50)
        XCTAssertEqual(session.step, .unzip)
    }

    func testPauseResumeAndReplayKeepOneDeterministicProgressValue() {
        let session = DNAReplicationSession()
        session.select(.unzip, play: true)
        session.advance(by: 2)
        session.togglePlayback()
        let paused = session.progress
        session.advance(by: 20)
        XCTAssertEqual(session.progress, paused)
        session.togglePlayback()
        session.advance(by: 1)
        XCTAssertEqual(session.progress, 0.5, accuracy: 0.0001)
        session.replay(play: true)
        XCTAssertEqual(session.progress, 0)
        session.select(.stabilize, play: false)
        XCTAssertFalse(session.isPlaying)
        XCTAssertEqual(session.progress, 1)
    }

    func testOptionalWholeLessonIncludesHelicaseAndStopsAtTheResult() {
        let session = DNAReplicationSession()
        session.autoAdvance = true
        session.replay(play: true)
        for step in DNAReplicationStep.carouselCases {
            XCTAssertEqual(session.step, step)
            session.advance(by: step.content.duration)
        }
        XCTAssertEqual(session.step, .result)
        XCTAssertEqual(session.progress, 1)
        XCTAssertFalse(session.isPlaying)
    }

    func testHelicaseMovesTowardPairedDNABeforeEachRowSeparates() {
        let start = DNAUnzipGeometry(progress: 0)
        let middle = DNAUnzipGeometry(progress: 0.5)
        let end = DNAUnzipGeometry(progress: 1)
        XCTAssertGreaterThan(start.helicase.y, middle.helicase.y)
        XCTAssertGreaterThan(middle.helicase.y, end.helicase.y)
        for index in 0..<12 {
            let row = CGFloat(61 + index * 24)
            XCTAssertEqual(start.strandX(left: true, at: row), 156)
            XCTAssertEqual(start.strandX(left: false, at: row), 204)
        }
        for progress in [-1.0, 0, 0.25, 0.5, 0.75, 1, 2] {
            let geometry = DNAUnzipGeometry(progress: progress)
            XCTAssertGreaterThanOrEqual(geometry.forkY, 110)
            XCTAssertLessThanOrEqual(geometry.forkY, 350)
            XCTAssertEqual(geometry.separation(at: geometry.forkY - 1), 0)
            XCTAssertEqual(geometry.separation(at: geometry.forkY + geometry.spread), 1)
            for row in stride(from: CGFloat(38), through: 352, by: 2) {
                XCTAssertLessThan(geometry.strandX(left: true, at: row), geometry.strandX(left: false, at: row))
            }
        }
        XCTAssertEqual(end.strandX(left: true, at: 352), 75)
        XCTAssertEqual(end.strandX(left: false, at: 352), 285)
    }

    func testHelicaseLoadingTargetAndActorRemainInsideSmallPhoneBoard() {
        let width: CGFloat = 288
        let target = DNACopyBoardLayout.screen(DNACopyBoardLayout.point(.helicase), width: width)
        let board = CGRect(x: 0, y: 0, width: width, height: width * 460 / 360)
        XCTAssertTrue(board.insetBy(dx: 28, dy: 28).contains(target))
        for progress in [0.0, 0.25, 0.5, 0.75, 1] {
            let geometry = DNAUnzipGeometry(progress: progress, openLeft: 94, openRight: 266,
                                            startY: 390, endY: 110, spread: 64)
            let actor = DNACopyBoardLayout.screen(geometry.helicase, width: width)
            XCTAssertTrue(board.contains(actor))
        }
    }
}
