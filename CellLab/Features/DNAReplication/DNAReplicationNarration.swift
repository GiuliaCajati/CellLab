import Foundation

enum DNAReplicationNarrationText {
    static func plain(_ text: String) -> String {
        text.replacingOccurrences(of: "**", with: "")
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}

extension DNAReplicationStep {
    var narrationID: String { "lesson.\(content.slug)" }
    var narrationDescription: String { DNAReplicationNarrationText.plain(content.bullets.joined(separator: " ")) }
}

extension DNAReplicationPlayer {
    var narrationID: String { "player.\(id)" }
    var narrationTitle: String { DNAReplicationNarrationText.plain(title) }
    var narrationText: String { narrationTitle + ". " + DNAReplicationNarrationText.plain(bullets.joined(separator: " ")) }
}

extension DNACopyTerm {
    var narrationID: String { "term.\(id)" }
    var narrationText: String { title + ". " + body }
}

extension DNACopyStage {
    var narrationKey: String {
        ["origin", "unwind", "stabilize", "prime", "leading", "lagging", "remove", "replace", "seal", "complete"][rawValue]
    }
}

extension DNACopySession {
    /// Changes with the instruction, rather than each repeated nucleotide or tool tap.
    var instructionNarrationID: String {
        let action: String
        switch stage {
        case .leading:
            if correctingMismatch && !mismatchRemoved { action = "correct" }
            else { action = leadingLoaded ? "build" : "load" }
        case .lagging:
            if !laggingPrimed.contains(fragment) { action = "prime" }
            else { action = laggingLoaded == fragment ? "build" : "load" }
        default: action = "start"
        }
        return "game.\(stage.narrationKey).\(action)"
    }
}

extension DNACopyCelebration {
    var narrationID: String {
        let slug = title.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }.joined(separator: "-")
        return "game.result.\(slug)"
    }
    var narrationText: String { title + "\n\n" + body }
}
