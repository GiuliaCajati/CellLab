import XCTest
@testable import CellLab

final class MeiosisSessionTests: XCTestCase {
    func testEveryIndependentOrientationFinishesWithFourDistinctHaploidProducts() {
        for left0 in [false, true] {
            for left1 in [false, true] {
                var s = prepared(orientation: [left0, left1])
                completeProphaseI(&s)
                connectAndAlignI(&s)
                s.send(.protectCentromeres); s.send(.separateHomologs)
                XCTAssertTrue(s.canAdvance); XCTAssertFalse(s.centromeresSplit)
                s.send(.advance)
                s.send(.rebuildI(0)); s.send(.rebuildI(1)); s.send(.divideI)
                XCTAssertTrue(s.canAdvance); s.send(.advance)
                s.send(.blockReplication); s.send(.makeInterkinesisProteins)
                XCTAssertTrue(s.canAdvance); s.send(.advance)
                for key in 0..<4 { s.send(.condenseII(key)) }
                s.send(.openEnvelopeII(0)); s.send(.openEnvelopeII(1))
                XCTAssertTrue(s.canAdvance); s.send(.advance)
                for pole in [MeiosisSession.Pole.top, .bottom] {
                    s.send(.choosePole(pole))
                    for key in 0..<4 { s.send(.attachII(key)) }
                }
                for key in 0..<4 { s.send(.alignII(key, nearEquator: true)) }
                s.send(.inspectII); XCTAssertTrue(s.canAdvance); s.send(.advance)
                s.send(.splitCentromeres); s.send(.separateSisters)
                XCTAssertTrue(s.canAdvance); s.send(.advance)
                for product in 0..<4 { s.send(.rebuildII(product)) }
                s.send(.relaxChromosomes); s.send(.divideII)
                XCTAssertTrue(s.canAdvance); s.send(.advance)
                XCTAssertEqual(s.stage, .complete)
                XCTAssertEqual(Set((0..<4).map { s.gameteAlleles($0) }).count, 4)
                for cell in 0..<2 {
                    let ids = (0..<2).map { s.homolog(in: cell, pair: $0) }
                    XCTAssertEqual(Set(ids.map { $0 / 2 }), Set([0, 1]))
                }
                for pair in 0..<2 {
                    XCTAssertNotEqual(s.homolog(in: 0, pair: pair), s.homolog(in: 1, pair: pair))
                }
                XCTAssertEqual(s.penalties, 0)
                XCTAssertTrue(s.replicated)
                XCTAssertTrue(s.replicationBlocked)
            }
        }
    }

    func testCrossoverIsReciprocalAndChangesOnlyTwoNonSisterChromatidsPerPair() {
        var s = prepared(orientation: [true, true])
        for id in 0..<4 { s.send(.condenseI(id)) }
        s.send(.openEnvelopeI)
        for pair in 0..<2 {
            let maternal = pair * 2, paternal = maternal + 1
            let originalM = s.alleles(homolog: maternal, sister: 0)
            let originalP = s.alleles(homolog: paternal, sister: 1)
            s.send(.synapse(pair, matched: true)); s.send(.crossOver(pair, matched: true))
            XCTAssertEqual(s.alleles(homolog: maternal, sister: 0), originalM)
            XCTAssertEqual(s.alleles(homolog: paternal, sister: 1), originalP)
            XCTAssertNotEqual(s.alleles(homolog: maternal, sister: 1), originalM)
            XCTAssertNotEqual(s.alleles(homolog: paternal, sister: 0), originalP)
            let after = [s.alleles(homolog: maternal, sister: 0), s.alleles(homolog: maternal, sister: 1),
                         s.alleles(homolog: paternal, sister: 0), s.alleles(homolog: paternal, sister: 1)].joined().sorted()
            XCTAssertEqual(after, (originalM + originalM + originalP + originalP).sorted())
        }
    }

    func testNoProgressWithoutPreparationAndNoEarlySisterSeparation() {
        var s = MeiosisSession(maternalLeft: [true, false])
        s.send(.prepareDivision); s.send(.advance); s.send(.separateSisters)
        XCTAssertEqual(s.stage, .interphase); XCTAssertFalse(s.divisionPrepared); XCTAssertFalse(s.separatedII)
        s.send(.replicateDNA); XCTAssertFalse(s.canAdvance)
        s.send(.prepareDivision); XCTAssertTrue(s.canAdvance)
        s.send(.advance); completeProphaseI(&s); connectAndAlignI(&s)
        s.send(.splitCentromeres); s.send(.separateSisters); s.send(.separateHomologs)
        XCTAssertFalse(s.centromeresSplit); XCTAssertFalse(s.separatedII); XCTAssertFalse(s.separatedI)
        s.send(.protectCentromeres); s.send(.separateHomologs)
        XCTAssertTrue(s.separatedI); XCTAssertFalse(s.centromeresSplit)
    }

    func testInterkinesisRejectsAnotherReplicationAndRecordsPenalty() {
        var s = prepared(orientation: [false, true])
        completeProphaseI(&s); connectAndAlignI(&s)
        s.send(.protectCentromeres); s.send(.separateHomologs); s.send(.advance)
        s.send(.rebuildI(0)); s.send(.rebuildI(1)); s.send(.divideI); s.send(.advance)
        XCTAssertEqual(s.stage, .interkinesis)
        s.send(.attemptExtraReplication)
        XCTAssertEqual(s.penalties, 1); XCTAssertTrue(s.needsCorrection)
        XCTAssertFalse(s.canAdvance); XCTAssertFalse(s.interkinesisProteins)
        s.send(.replicateDNA); XCTAssertFalse(s.canAdvance)
        s.send(.blockReplication); s.send(.makeInterkinesisProteins)
        XCTAssertTrue(s.canAdvance)
    }

    func testWrongPoleAndOffEquatorDropsDoNotPassCheckpoint() {
        var s = prepared(orientation: [true, false]); completeProphaseI(&s)
        s.send(.choosePole(.right)); s.send(.attachI(0))
        XCTAssertEqual(s.rightAttachments.count, 0); XCTAssertEqual(s.penalties, 1)
        for id in 0..<4 { s.send(.choosePole(s.poleForHomolog(id))); s.send(.attachI(id)) }
        s.send(.alignI(0, nearEquator: false)); s.send(.inspectI)
        XCTAssertFalse(s.checkpointI); XCTAssertFalse(s.canAdvance)
        s.send(.alignI(0, nearEquator: true)); s.send(.alignI(1, nearEquator: true)); s.send(.inspectI)
        XCTAssertTrue(s.canAdvance)
        s.send(.flipPair(0))
        XCTAssertFalse(s.checkpointI); XCTAssertFalse(s.canAdvance)
        XCTAssertEqual(s.leftAttachments.count + s.rightAttachments.count, 2)
    }

    func testHumanCombinationMathAndRestart() {
        XCTAssertEqual(MeiosisSession.humanGameteCombinations, 8_388_608)
        XCTAssertEqual(MeiosisSession.humanZygoteCombinations, 70_368_744_177_664)
        var s = prepared(orientation: [true, true]); completeProphaseI(&s)
        s.send(.restart)
        XCTAssertEqual(s.stage, .interphase); XCTAssertFalse(s.replicated)
        XCTAssertTrue(s.crossed.isEmpty); XCTAssertTrue(s.nucleiI.isEmpty); XCTAssertTrue(s.nucleiII.isEmpty)
    }

    private func prepared(orientation: [Bool]) -> MeiosisSession {
        var s = MeiosisSession(maternalLeft: orientation)
        s.send(.replicateDNA); s.send(.prepareDivision); s.send(.advance)
        return s
    }
    /// Starts in prophase I, finishes in metaphase I.
    private func completeProphaseI(_ s: inout MeiosisSession) {
        for id in 0..<4 { s.send(.condenseI(id)) }
        s.send(.openEnvelopeI)
        for pair in 0..<2 { s.send(.synapse(pair, matched: true)); s.send(.crossOver(pair, matched: true)) }
        XCTAssertTrue(s.canAdvance); s.send(.advance)
    }
    /// Starts in metaphase I, finishes in anaphase I.
    private func connectAndAlignI(_ s: inout MeiosisSession) {
        for id in 0..<4 { s.send(.choosePole(s.poleForHomolog(id))); s.send(.attachI(id)) }
        s.send(.alignI(0, nearEquator: true)); s.send(.alignI(1, nearEquator: true)); s.send(.inspectI)
        XCTAssertTrue(s.canAdvance); s.send(.advance)
    }
}
