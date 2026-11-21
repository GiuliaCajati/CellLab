import Foundation

@main struct ExportHomeNarration {
    struct Cue: Codable { let id, title, text: String }
    struct Library: Codable { let lessonTitle: String; let recordings: [Cue] }
    static func main() throws {
        let cues = [Cue(id: "home.overview", title: "Welcome to CellLab", text: CellLabHomeNarration.welcome)]
            + CellLabHomeModule.allCases.map { Cue(id: $0.cueID, title: $0.title, text: $0.narrationText) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        FileHandle.standardOutput.write(try encoder.encode(Library(lessonTitle: "CellLab", recordings: cues)))
    }
}
