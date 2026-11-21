import Foundation

@main struct ExportDNATechnologyNarration {
    struct Cue: Codable { let id, title, text: String }
    struct Library: Codable { let lessonTitle: String; let recordings: [Cue] }

    static func main() throws {
        var cues = [Cue(id: "lesson.overview", title: "Opening · Listen", text: DNATechnologyNarration.overview)]
        for topic in DTTopic.allCases {
            for stage in topic.article.stages {
                precondition(DTScene.all[topic.rawValue + "-" + stage.id] != nil)
                cues.append(Cue(id: topic.narrationID(for: stage), title: topic.article.title + " · " + stage.title,
                                text: topic.narrationText(for: stage)))
            }
        }
        cues += [Cue(id: "tools.overview", title: "Meet the tools", text: DNATechnologyNarration.toolsOverview),
                 Cue(id: "reference.pcr-counter", title: "How the PCR counter works", text: DNATechnologyNarration.pcrCounter)]
        cues += DTTerm.all.map { Cue(id: $0.narrationID, title: $0.name, text: $0.narrationText) }
        precondition(Set(cues.map(\.id)).count == cues.count)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        FileHandle.standardOutput.write(try encoder.encode(Library(lessonTitle: "DNA Technology", recordings: cues)))
    }
}
