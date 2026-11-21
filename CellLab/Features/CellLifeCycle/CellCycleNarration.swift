import Foundation

enum CellCycleNarration {
    static let overview = """
    Fun fact! Most brain cells, called neurons, spend almost their entire lives outside the active cell cycle in a phase called G₀. Once mature, they normally do not divide again. But resting from division does not mean doing nothing. Your neurons are busy sending signals that help you think, move, and remember! Other cells keep cycling to help you grow and replace worn-out cells. During interphase, a cell grows in G₁, copies its DNA in S phase, and prepares to divide in G₂. Then mitosis divides the nucleus, and cytokinesis splits the cell in two. Tap a section of the wheel and I’ll read its description. In mitosis, choose a stage; in cytokinesis, compare animal and plant cells. Meet the key players explains the helpers and checkpoints. Let’s explore the cell life cycle!
    """

    /// Keep narration tied to the same strings that appear on each card.
    static func text(_ parts: [String]) -> String {
        parts.map { part in
            let clean = part.replacingOccurrences(of: "**", with: "")
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard let last = clean.last else { return "" }
            return ".!?".contains(last) ? clean : clean + "."
        }.filter { !$0.isEmpty }.joined(separator: " ")
    }

    static func cueID(phase: CellCyclePhase, step: CellCycleMitosisStep, kind: CellCycleCellKind) -> String {
        switch phase {
        case .mitosis: return "phase.mitosis.\(step.rawValue)"
        case .cytokinesis: return "phase.cytokinesis.\(kind.rawValue)"
        default: return "phase.\(phase.rawValue)"
        }
    }

    static func phaseText(_ phase: CellCyclePhase, step: CellCycleMitosisStep = .prophase,
                          kind: CellCycleCellKind = .animal) -> String {
        let content = phase.content
        var parts = [content.title, content.subtitle] + [content.summary].compactMap { $0 }
        switch phase {
        case .mitosis:
            parts += [step.content.title] + step.content.bullets
            if let checkpoint = step.content.checkpoint { parts.append(checkpoint) }
        case .cytokinesis:
            parts += [kind.content.title] + kind.content.bullets
        default:
            parts += content.bullets
            if let checkpoint = content.checkpoint { parts.append(checkpoint) }
        }
        return text(parts)
    }
}

extension CellCyclePlayer {
    var narrationID: String { "player.\(id)" }
    var narrationTitle: String { title.replacingOccurrences(of: "\n", with: " ") }
    var narrationText: String { CellCycleNarration.text([title, caption] + bullets) }
}
