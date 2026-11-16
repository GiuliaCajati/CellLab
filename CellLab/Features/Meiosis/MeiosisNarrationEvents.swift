import Foundation

extension MeiosisSession.Stage {
    var narrationKey: String {
        ["interphase", "prophase-i", "metaphase-i", "anaphase-i", "telophase-i",
         "interkinesis", "prophase-ii", "metaphase-ii", "anaphase-ii", "telophase-ii", "complete"][rawValue]
    }
}

extension MeiosisSession {
    /// Changes only when the next available instruction changes, not on every tap.
    var instructionNarrationID: String {
        let step: String
        switch stage {
        case .interphase: step = replicated ? "prepare" : "start"
        case .prophaseI:
            if condensedI.count < 4 { step = "start" }
            else if !envelopeOpenI { step = "envelope" }
            else if synapsed.count < 2 { step = "pair" }
            else { step = "cross" }
        case .metaphaseI:
            step = !attachmentsIComplete ? "start" : alignedI.count < 2 ? "align" : "inspect"
        case .anaphaseI: step = centromeresProtected ? "separate" : "start"
        case .telophaseI: step = nucleiI.count < 2 ? "start" : "divide"
        case .interkinesis: step = replicationBlocked ? "prepare" : "start"
        case .prophaseII: step = condensedII.count < 4 ? "start" : "envelopes"
        case .metaphaseII:
            step = !attachmentsIIComplete ? "start" : alignedII.count < 4 ? "align" : "inspect"
        case .anaphaseII: step = centromeresSplit ? "separate" : "start"
        case .telophaseII:
            step = nucleiII.count < 4 ? "start" : !relaxedII ? "unpack" : "divide"
        case .complete: step = "start"
        }
        return "game.\(stage.narrationKey).\(step)"
    }

    var completionNarrationID: String { "game.\(stage.narrationKey).result" }
}

/// Shared popup content is also exported for offline speech generation.
nonisolated struct MeiosisPopup: Identifiable {
    let id = UUID()
    let title: String
    let explanation: String
    let takeaway: String
    let buttonTitle: String
    let advancesStage: Bool
    let showsTakeaway: Bool
    static func completed(_ s: MeiosisSession) -> Self {
        let next = MeiosisSession.Stage(rawValue: s.stage.rawValue + 1)
        // Short milestone lesson; complete content remains in the options explanation.
        let summary: [String]
        switch s.stage {
        case .interphase: summary = [s.facts[1], s.facts[2], s.facts[3]]
        case .prophaseI: summary = [s.facts[1], s.facts[2]]
        case .metaphaseI: summary = [s.facts[0], s.facts[1], s.facts[3]]
        case .anaphaseI: summary = s.facts
        case .telophaseI: summary = [s.facts[1], s.facts[2]]
        case .interkinesis: summary = [s.facts[1]]
        case .prophaseII: summary = s.facts
        case .metaphaseII: summary = [s.facts[0], s.facts[1]]
        case .anaphaseII: summary = s.facts
        case .telophaseII: summary = [s.facts[0], s.facts[1], s.facts[2]]
        case .complete: summary = s.facts
        }
        return Self(title: "\(s.stage.title) complete!", explanation: summary.map { "✅ \($0)" }.joined(separator: "\n\n"),
                    takeaway: s.stage.takeaway, buttonTitle: "Next: \(next?.title ?? "Continue")", advancesStage: true,
                    showsTakeaway: s.stage == .interphase || s.stage == .interkinesis)
    }
    static func explanation(_ s: MeiosisSession) -> Self {
        Self(title: s.stage.title, explanation: s.facts.map { "•  \($0)" }.joined(separator: "\n\n"),
             takeaway: s.stage.takeaway, buttonTitle: "Back to the cell", advancesStage: false, showsTakeaway: false)
    }
}

