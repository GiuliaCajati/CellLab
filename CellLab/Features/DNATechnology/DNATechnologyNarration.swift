import Foundation

enum DNATechnologyNarration {
    static let overview = """
    Tiny tools. Big discoveries! We can read DNA, copy a chosen section, or change a sequence. But those are different jobs, so let’s choose the right tool! Tap a lab area, then choose a step. I’ll explain its description and the extra biology notes. PCR’s counter shows an ideal copying model. Meet the tools and key terms opens the definitions, and the axolotl on each definition can read it aloud. Let’s explore DNA technology!
    """
    static let toolsOverview = """
    Welcome to the DNA toolbox! Search for a tool or concept, or browse the topic groups. Tap a term to open its full definition, then tap the axolotl to hear it. Explore takes you back to that tool’s lesson. Let’s find out what each helper does!
    """
    static let pcrCounter = """
    This counter starts with one DNA template. In an ideal PCR cycle, the number of copies doubles. One cycle gives two copies, two cycles give four, and three cycles give eight. Tap One more cycle to see the total grow, or Reset to start again. The expression two to the power of n means doubling n times. This is an idealized model; real reactions become less efficient and do not keep doubling perfectly.
    """

    static func text(_ parts: [String]) -> String {
        parts.map { part in
            let clean = part.split(whereSeparator: \.isWhitespace).joined(separator: " ")
            guard let last = clean.last else { return "" }
            return ".!?".contains(last) ? clean : clean + "."
        }.filter { !$0.isEmpty }.joined(separator: " ")
    }
}

extension DTTopic {
    func narrationID(for stage: DTStage) -> String { "lesson.\(rawValue).\(stage.id)" }
    func narrationText(for stage: DTStage) -> String {
        var parts: [String] = []
        if stage.id == article.stages.first?.id {
            parts += ["Let’s explore " + article.title + ".", article.summary]
        }
        parts += [stage.heading, stage.summary] + stage.bullets
        if let note = DTScene.all[rawValue + "-" + stage.id]?.note { parts.append(note) }
        return DNATechnologyNarration.text(parts)
    }
}

extension DTTerm {
    var narrationID: String { "term.\(id)" }
    var narrationText: String { DNATechnologyNarration.text([name, definition]) }
}
