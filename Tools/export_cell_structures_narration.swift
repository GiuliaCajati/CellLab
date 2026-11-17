import Foundation

@main struct ExportCellStructuresNarration {
    struct Cue: Codable { let id, title, text: String }
    struct Library: Codable { let lessonTitle: String; let recordings: [Cue] }

    static func main() throws {
        let cues = [Cue(id: "lesson.overview", title: "Opening · Listen", text: CSNarrationText.overview)]
            + CSPart.allCases.flatMap { part in
                [Cue(id: part.narrationID, title: part.content.title, text: part.narrationText),
                 Cue(id: part.detailNarrationID, title: "Look closer · " + part.content.title, text: part.detailNarrationText)]
            }
        precondition(Set(cues.map(\.id)).count == cues.count)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        FileHandle.standardOutput.write(try encoder.encode(Library(lessonTitle: "Cell Structures", recordings: cues)))
    }
}
