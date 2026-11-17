import Foundation

/// Exports the real lesson, vocabulary, and a valid walk through every game action.
@main struct ExportSPhaseNarration {
    struct Cue: Codable, Equatable {
        let id: String
        let title: String
        let text: String
    }
    struct Content: Codable {
        let steps: [Cue]
        let players: [Cue]
        let terms: [Cue]
        let game: [Cue]
    }

    @MainActor static func main() throws {
        let session = DNACopySession()
        var game: [Cue] = []
        func collect() {
            let cue: Cue
            if let card = session.celebration {
                cue = Cue(id: card.narrationID, title: card.title, text: card.narrationText)
            } else {
                cue = Cue(id: session.instructionNarrationID, title: session.stage.title + " · Instruction", text: session.instruction)
            }
            if let previous = game.first(where: { $0.id == cue.id }) {
                precondition(previous == cue, "A narration ID must always describe the same words: \(cue.id)")
            } else { game.append(cue) }
        }
        func advance() {
            precondition(session.celebration != nil)
            session.continueAfterCelebration()
            collect()
        }
        func use(_ tool: DNACopyTool, _ target: DNACopyTarget) {
            precondition(session.use(tool, at: target))
            collect()
        }
        func add() {
            precondition(session.add(session.expectedBase!, at: session.activeTarget!))
            collect()
        }
        collect()
        session.start(at: 1); collect(); advance()
        use(.helicase, .helicase); advance()
        for site in 0..<3 { use(.binding, .binding(site)) }
        advance()
        use(.primase, .primer(.leading, 0)); advance()
        use(.polymerase, .load(.leading, 0))
        add(); add(); advance()
        use(.polymerase, .mismatch)
        add(); advance()
        for _ in 5..<8 { add() }
        advance()
        for fragment in 0..<2 {
            use(.primase, .primer(.lagging, fragment))
            use(.polymerase, .load(.lagging, fragment))
            add(); add(); advance()
        }
        for site in DNACopySite.allCases { use(.repair, .remove(site)) }
        advance()
        session.choose(tool: .polymerase)
        for _ in 0..<6 { add() }
        advance()
        for site in DNACopySite.allCases { use(.ligase, .nick(site)) }
        advance()
        precondition(session.stage == .complete && session.placedBases == 16)
        let content = Content(
            steps: DNAReplicationStep.carouselCases.map { Cue(id: $0.content.slug, title: $0.content.title, text: $0.narrationDescription) },
            players: DNAReplicationPlayer.all.map { Cue(id: $0.narrationID, title: $0.narrationTitle, text: $0.narrationText) },
            terms: DNACopyTerm.all.map { Cue(id: $0.narrationID, title: $0.title, text: $0.narrationText) }, game: game)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        FileHandle.standardOutput.write(try encoder.encode(content))
    }
}
