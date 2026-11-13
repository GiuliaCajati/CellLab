import XCTest
@testable import CellLab

@MainActor final class DNACopySessionTests: XCTestCase {
    private func advance(_ session: DNACopySession) {
        XCTAssertNotNil(session.celebration)
        session.continueAfterCelebration()
    }
    private func prepare(_ session: DNACopySession) {
        session.start(at: 1); advance(session)
        XCTAssertTrue(session.use(.helicase, at: .helicase)); advance(session)
        for site in 0..<3 { XCTAssertTrue(session.use(.binding, at: .binding(site))) }
        advance(session)
        XCTAssertTrue(session.use(.primase, at: .primer(.leading, 0))); advance(session)
        XCTAssertTrue(session.use(.polymerase, at: .load(.leading, 0)))
    }
    private func buildLeading(_ session: DNACopySession) {
        prepare(session)
        for index in [2, 3] {
            XCTAssertTrue(session.add(DNACopySequence.leading[index].complement, at: .base(.leading, index)))
        }
        XCTAssertTrue(session.correctingMismatch)
        advance(session)
        XCTAssertEqual(session.activeTarget, .mismatch)
        XCTAssertTrue(session.use(.polymerase, at: .mismatch))
        XCTAssertTrue(session.add(DNACopySequence.leading[4].complement, at: .base(.leading, 4)))
        XCTAssertTrue(session.mismatchCorrected)
        advance(session)
        for index in 5..<8 { XCTAssertTrue(session.add(DNACopySequence.leading[index].complement, at: .base(.leading, index))) }
        advance(session)
        XCTAssertEqual(session.stage, .lagging)
    }
    private func buildBoth(_ session: DNACopySession) {
        buildLeading(session)
        for fragment in 0..<2 {
            XCTAssertTrue(session.use(.primase, at: .primer(.lagging, fragment)))
            XCTAssertTrue(session.use(.polymerase, at: .load(.lagging, fragment)))
            for index in fragment * 4 + 2..<fragment * 4 + 4 {
                XCTAssertTrue(session.add(DNACopySequence.template(lane: .lagging, index: index).complement, at: .base(.lagging, index)))
            }
            advance(session)
        }
        XCTAssertEqual(session.stage, .remove)
    }
    func testTemplatesAreComplementaryAtEveryPhysicalRow() {
        for index in 0..<8 {
            let row = DNACopySequence.row(lane: .lagging, index: index)
            XCTAssertEqual(DNACopySequence.template(lane: .lagging, index: index), DNACopySequence.leading[7 - row].complement)
        }
        for base in DNACopyBase.allCases { XCTAssertEqual(base.complement.complement, base) }
    }
    func testDNARequiresTheRightPreparationAndGrowingEnd() {
        let session = DNACopySession()
        XCTAssertFalse(session.add(.a, at: .base(.leading, 2)))
        XCTAssertFalse(session.use(.ligase, at: .helicase))
        prepare(session)
        XCTAssertFalse(session.add(.a, at: .base(.leading, 7)))
        let expected = session.expectedBase!
        let wrong = DNACopyBase.allCases.first { $0 != expected }!
        XCTAssertFalse(session.add(wrong, at: .base(.leading, 2)))
        XCTAssertNil(session.leading[2])
        XCTAssertEqual(session.placedBases, 0)
        XCTAssertTrue(session.add(expected, at: .base(.leading, 2)))
    }
    func testProofreadingBlocksExtensionUntilMismatchRemoved() {
        let session = DNACopySession(); prepare(session)
        for index in [2, 3] { _ = session.add(DNACopySequence.leading[index].complement, at: .base(.leading, index)) }
        XCTAssertEqual(session.leading[3], DNACopySequence.leading[3].complement)
        advance(session)
        XCTAssertFalse(session.add(.a, at: .base(.leading, 5)))
        XCTAssertFalse(session.add(session.leading[4]!, at: .mismatch))
        XCTAssertTrue(session.use(.polymerase, at: .mismatch))
        XCTAssertNil(session.leading[4])
        XCTAssertEqual(session.activeTarget, .base(.leading, 4))
    }
    func testEveryLaggingFragmentNeedsAPrimer() {
        let session = DNACopySession(); buildLeading(session)
        XCTAssertFalse(session.use(.polymerase, at: .load(.lagging, 0)))
        XCTAssertFalse(session.add(.c, at: .base(.lagging, 2)))
        _ = session.use(.primase, at: .primer(.lagging, 0))
        _ = session.use(.polymerase, at: .load(.lagging, 0))
        for index in 2..<4 { _ = session.add(DNACopySequence.template(lane: .lagging, index: index).complement, at: .base(.lagging, index)) }
        advance(session)
        XCTAssertEqual(session.activeTarget, .primer(.lagging, 1))
        XCTAssertFalse(session.add(.c, at: .base(.lagging, 6)))
    }
    func testCompleteCopyReplacesAllPrimersBeforeSealing() {
        let session = DNACopySession(); buildBoth(session)
        XCTAssertFalse(session.use(.ligase, at: .nick(.leading)))
        for site in DNACopySite.allCases { XCTAssertTrue(session.use(.repair, at: .remove(site))) }
        advance(session)
        XCTAssertEqual(session.stage, .replace)
        XCTAssertFalse(session.add(session.expectedBase!, at: session.activeTarget!))
        session.choose(tool: .polymerase)
        for site in DNACopySite.allCases {
            for index in 0..<2 {
                let value = DNACopySequence.replacementTemplate(site: site, index: index).complement
                XCTAssertTrue(session.add(value, at: .replacement(site, index)))
            }
        }
        advance(session)
        XCTAssertEqual(session.stage, .seal)
        for site in DNACopySite.allCases { XCTAssertTrue(session.use(.ligase, at: .nick(site))) }
        advance(session)
        XCTAssertEqual(session.stage, .complete)
        XCTAssertEqual(session.placedBases, 16)
        XCTAssertEqual(session.sealed.count, 3)
        XCTAssertEqual(session.removedPrimers.count, 3)
        XCTAssertEqual(session.usedTools, Set(DNACopyTool.allCases))
        XCTAssertTrue(session.mismatchCorrected)
        XCTAssertNil(session.activeTarget)
    }
    func testPopupsPreventAccidentalDoubleActions() {
        let session = DNACopySession(); session.start(at: 0)
        XCTAssertNotNil(session.celebration)
        XCTAssertFalse(session.use(.helicase, at: .helicase))
        session.start(at: 2)
        XCTAssertEqual(session.origin, 0)
    }
    func testForeignDragPayloadsAreRejected() {
        let session = DNACopySession()
        XCTAssertFalse(session.receive("A", at: .origin(0)))
        XCTAssertNil(DNACopyBase(payload: "celllab.dna.base.U"))
        XCTAssertNil(DNACopyTool(payload: "celllab.dna.tool.unknown"))
        for base in DNACopyBase.allCases { XCTAssertEqual(DNACopyBase(payload: base.payload), base) }
        for tool in DNACopyTool.allCases { XCTAssertEqual(DNACopyTool(payload: tool.payload), tool) }
    }
    func testFreshSessionHasNoCarriedProgress() {
        let first = DNACopySession(); prepare(first)
        let fresh = DNACopySession()
        XCTAssertEqual(fresh.stage, .origin)
        XCTAssertNil(fresh.selectedTool)
        XCTAssertNil(fresh.origin)
        XCTAssertFalse(fresh.unwound)
        XCTAssertEqual(fresh.placedBases, 0)
    }
}
