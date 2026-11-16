import Foundation

/// The script identifiers are the editable link between an on-screen event and its recording.
extension MitosisSession {
    var instructionNarrationID: String {
        switch stage {
        case .prophase: condensed.count < 4 ? "game.prophase.start" : "game.prophase.packed"
        case .prometaphase: envelopeOpen ? "game.prometaphase.envelope-open" : "game.prometaphase.start"
        case .metaphase: aligned.count == 4 ? "game.metaphase.aligned" : "game.metaphase.start"
        case .anaphase: "game.anaphase.start"
        case .telophase: "game.telophase.start"
        case .complete: "game.complete"
        }
    }

    var completionNarrationID: String {
        "game." + (stage == .complete ? "complete" : stage.title.lowercased() + ".result")
    }

    var lessonNarrationID: String { "lesson." + (stage == .complete ? "telophase" : stage.title.lowercased()) }
}
