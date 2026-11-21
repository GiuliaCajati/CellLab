import Foundation

@main struct ExportRespirationNarration {
    struct Cue: Codable { let id, title, text: String }
    struct Library: Codable { let lessonTitle: String; let recordings: [Cue] }

    static func main() throws {
        var cues = [Cue(id: "lesson.overview", title: "Opening · Listen", text: RespirationNarration.overview)]
        cues += RespirationStep.slides.map { Cue(id: $0.narrationID, title: $0.content.title, text: $0.narrationText) }
        cues += [Cue(id: RespirationStep.overview.narrationID, title: "The big picture", text: RespirationStep.overview.narrationText),
                 Cue(id: "reference.equation", title: "The overall reaction", text: RespirationNarration.equation),
                 Cue(id: "players.introduction", title: "Meet the energy-making crew", text: RespirationNarration.playersIntroduction)]
        cues += RespirationPlayer.all.map { Cue(id: $0.narrationID, title: $0.title, text: $0.narrationText) }
        precondition(Set(cues.map(\.id)).count == cues.count)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        FileHandle.standardOutput.write(try encoder.encode(Library(lessonTitle: "Cellular respiration", recordings: cues)))
    }
}
