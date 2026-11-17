import Foundation
import Observation

struct CentralDogmaGameRecord: Sendable { let id, kind, payload, target: String }
struct CentralDogmaGameFeedback: Sendable {
    let text: String
    let correct: Bool?
    let points: Int
}

@MainActor @Observable final class CentralDogmaGameSession {
    // Avoid the iOS 26.2 isolated-deinit runtime crash, as in the other games.
    nonisolated deinit {}
    private(set) var missionIndex = 0
    private(set) var index = 0
    private(set) var score = 0
    private(set) var attempts = 0
    private(set) var correct = 0
    private(set) var streak = 0
    private(set) var bestStreak = 0
    private(set) var hints = 0
    private(set) var records: [CentralDogmaGameRecord] = []
    private(set) var badges: [String] = []
    private(set) var pending: CentralDogmaGameMilestone?
    private(set) var successSerial = 0
    private(set) var mistakeSerial = 0
    var selectedPayload: String?
    private(set) var feedback = CentralDogmaGameFeedback(text: "Choose a tool, then its target. Dragging works too.", correct: nil, points: 0)

    var mission: CentralDogmaGameMission { CentralDogmaGameData.shared.missions[missionIndex] }
    var step: CentralDogmaGameStep? { index < mission.steps.count ? mission.steps[index] : nil }
    var isComplete: Bool { index == mission.steps.count }
    var accuracy: Int { attempts == 0 ? 100 : Int((Double(correct) / Double(attempts) * 100).rounded()) }
    var progress: Double { Double(index) / Double(mission.steps.count) }
    var rnaCount: Int { records.filter { $0.kind == "rna" }.count }
    var chainCount: Int { (has("initiator") ? 1 : 0) + records.filter { $0.kind == "bond" }.count }
    var usedPieces: Set<String> { Set(records.filter { $0.kind == "assemble" }.map(\.payload)) }
    var usedSlots: Set<String> { Set(records.filter { $0.kind == "assemble" }.map(\.target)) }
    func has(_ id: String) -> Bool { records.contains { $0.id == id } }

    func choose(_ payload: String) { selectedPayload = payload }
    func showHint() {
        guard let step else { return }
        hints += 1
        feedback = .init(text: step.hint, correct: nil, points: 0)
    }
    func continueAfterCheckpoint() { pending = nil }
    func restart() {
        missionIndex = (missionIndex + 1) % CentralDogmaGameData.shared.missions.count
        index = 0; score = 0; attempts = 0; correct = 0; streak = 0; bestStreak = 0; hints = 0
        records = []; badges = []; pending = nil; selectedPayload = nil
        feedback = .init(text: "New message, new stop codon. Let’s go!", correct: nil, points: 0)
    }

    @discardableResult func submit(_ payload: String, target: String, stepID: String) -> Bool {
        guard let step, pending == nil, step.id == stepID else { return false }
        if step.uniqueGroup != nil && (usedPieces.contains(payload) || usedSlots.contains(target)) { return false }
        let rightTarget = step.target == "hemoglobin:*"
            ? ["hemoglobin:0", "hemoglobin:1", "hemoglobin:2", "hemoglobin:3"].contains(target)
            : target == step.target
        let rightPayload = step.payload == "*"
            ? step.options.contains { $0.payload == payload }
            : payload == step.payload
        attempts += 1
        guard rightTarget && rightPayload else {
            streak = 0; mistakeSerial += 1
            feedback = .init(text: step.wrong, correct: false, points: 0)
            return false
        }
        correct += 1; streak += 1; bestStreak = max(bestStreak, streak)
        let earned = step.points + min(streak - 1, 4) * 2
        score += earned
        records.append(.init(id: step.id, kind: step.kind, payload: payload, target: target))
        selectedPayload = nil; index += 1; successSerial += 1
        feedback = .init(text: step.success, correct: true, points: earned)
        if let milestone = step.milestone { pending = milestone; badges.append(milestone.badge) }
        return true
    }
}
