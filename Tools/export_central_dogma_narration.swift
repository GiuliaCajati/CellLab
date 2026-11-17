import Foundation

@main struct ExportCentralDogmaNarration {
    struct Cue: Codable {
        let id, title, text: String
    }
    struct Library: Codable {
        let lessonTitle: String
        let recordings: [Cue]
    }
    static func main() throws {
        var entries = [
            Cue(id: "lesson.overview", title: "Opening · Listen", text: CentralDogmaNarrationText.overview),
            Cue(id: "reference.players", title: "Meet the key players", text: CentralDogmaNarrationText.playersIntroduction),
            Cue(id: "game.introduction", title: "How to play RNA Relay", text: CentralDogmaNarrationText.gameIntroduction),
            Cue(id: "game.complete", title: "Message delivered!", text: CentralDogmaNarrationText.gameComplete)
        ]
        entries += CentralDogmaStep.allCases.map { Cue(id: $0.narrationID, title: $0.content.title, text: $0.narrationText) }
        entries += CentralDogmaPlayer.all.map { Cue(id: $0.narrationID, title: $0.title, text: $0.narrationText) }
        for mission in CentralDogmaGameData.shared.missions {
            for step in mission.steps {
                let cue = Cue(id: step.narrationID, title: step.title, text: step.instruction)
                if let existing = entries.first(where: { $0.id == cue.id }) {
                    precondition(existing.text == cue.text, "A narration ID must always have identical text")
                } else { entries.append(cue) }
                if let milestone = step.milestone, !entries.contains(where: { $0.id == milestone.narrationID }) {
                    entries.append(Cue(id: milestone.narrationID, title: milestone.title, text: milestone.narrationText))
                }
            }
        }
        precondition(Set(entries.map(\.id)).count == entries.count)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        FileHandle.standardOutput.write(try encoder.encode(Library(lessonTitle: "Central Dogma", recordings: entries)))
    }
}
