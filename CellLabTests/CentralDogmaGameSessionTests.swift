// Add to the CellLabTests target, not the app target. Run in Xcode on a Mac.
import XCTest
@testable import CellLab

final class CentralDogmaGameSessionTests: XCTestCase {
    @MainActor func testOneTapRNAChoiceChecksPairingAndRejectsStaleTaps() throws {
        let game = CentralDogmaGameSession()
        for _ in 0..<3 {
            let step = try XCTUnwrap(game.step)
            XCTAssertTrue(game.submit(step.payload, target: step.target, stepID: step.id))
        }
        let step = try XCTUnwrap(game.step)
        XCTAssertEqual(step.kind, "rna")
        let score = game.score
        game.choose("rna:U", stepID: step.id)
        XCTAssertEqual(game.rnaCount, 0)
        XCTAssertEqual(game.score, score)
        XCTAssertEqual(game.step?.id, step.id)
        game.choose("rna:A", stepID: step.id)
        XCTAssertEqual(game.rnaCount, 1)
        XCTAssertEqual(game.step?.id, "rna-1")
        let earned = game.score
        game.choose("rna:A", stepID: step.id)
        XCTAssertEqual(game.rnaCount, 1)
        XCTAssertEqual(game.score, earned)
    }
    @MainActor func testWrongActionDoesNotChangeMoleculeOrPoints() {
        let game = CentralDogmaGameSession(), step = CentralDogmaGameData.shared.missions[0].steps[0]
        XCTAssertFalse(game.submit("tool:polymerase", target: step.target, stepID: step.id))
        XCTAssertEqual(game.index, 0); XCTAssertEqual(game.score, 0); XCTAssertEqual(game.records.count, 0)
    }
    @MainActor func testFullRoundAndDuplicateProtection() {
        let game = CentralDogmaGameSession()
        while let step = game.step {
            game.continueAfterCheckpoint()
            let payload = step.uniqueGroup == nil ? step.payload : step.options.first { !game.usedPieces.contains($0.payload) }!.payload
            let target = step.uniqueGroup == nil ? step.target : (0..<4).map { "hemoglobin:\($0)" }.first { !game.usedSlots.contains($0) }!
            XCTAssertTrue(game.submit(payload, target: target, stepID: step.id))
            let earned = game.score, index = game.index, attempts = game.attempts
            XCTAssertFalse(game.submit(payload, target: target, stepID: step.id))
            XCTAssertEqual(game.score, earned); XCTAssertEqual(game.index, index); XCTAssertEqual(game.attempts, attempts)
        }
        XCTAssertTrue(game.isComplete); XCTAssertEqual(game.accuracy, 100)
        XCTAssertEqual(game.rnaCount, game.mission.preRNA.count); XCTAssertEqual(game.chainCount, 3)
        XCTAssertEqual(game.usedPieces.count, 4); XCTAssertEqual(game.usedSlots.count, 4)
    }
    @MainActor func testSourcePairingForEveryStopVariant() {
        let pair: [Character: Character] = ["A": "U", "T": "A", "G": "C", "C": "G"]
        for mission in CentralDogmaGameData.shared.missions {
            XCTAssertEqual(String(mission.template.map { pair[$0]! }), mission.preRNA)
            XCTAssertEqual(mission.regions.filter { $0.kind == "exon" }.map(\.sequence).joined(), mission.matureRNA)
            XCTAssertEqual(mission.codons.last, mission.stop)
            XCTAssertTrue(mission.codons.dropLast().allSatisfy { $0 == "AUG" })
        }
    }
}
