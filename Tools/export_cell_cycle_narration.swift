import Foundation

@main struct ExportCellCycleNarration {
    struct Cue: Codable { let id, title, text: String }
    struct Library: Codable { let lessonTitle: String; let recordings: [Cue] }

    static func main() throws {
        var cues = [Cue(id: "lesson.overview", title: "Opening · Listen", text: CellCycleNarration.overview)]
        for phase in CellCyclePhase.allCases {
            switch phase {
            case .mitosis:
                for step in CellCycleMitosisStep.allCases {
                    cues.append(Cue(id: CellCycleNarration.cueID(phase: phase, step: step, kind: .animal),
                                    title: "Mitosis · " + step.content.title,
                                    text: CellCycleNarration.phaseText(phase, step: step)))
                }
            case .cytokinesis:
                for kind in CellCycleCellKind.allCases {
                    cues.append(Cue(id: CellCycleNarration.cueID(phase: phase, step: .prophase, kind: kind),
                                    title: "Cytokinesis · " + kind.content.title,
                                    text: CellCycleNarration.phaseText(phase, kind: kind)))
                }
            default:
                cues.append(Cue(id: CellCycleNarration.cueID(phase: phase, step: .prophase, kind: .animal),
                                title: phase.content.title, text: CellCycleNarration.phaseText(phase)))
            }
        }
        cues += CellCyclePlayer.all.map { Cue(id: $0.narrationID, title: $0.narrationTitle, text: $0.narrationText) }
        precondition(Set(cues.map(\.id)).count == cues.count)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        FileHandle.standardOutput.write(try encoder.encode(Library(lessonTitle: "Cell Life Cycle", recordings: cues)))
    }
}
