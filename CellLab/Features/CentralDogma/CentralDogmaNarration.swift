import Foundation

enum CentralDogmaNarrationText {
    static func plain(_ text: String) -> String {
        text.replacingOccurrences(of: "**", with: "")
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    static let overview = """
    How does a cell turn the instructions in DNA into something it can use? First, it copies a gene into RNA. Then a ribosome reads that message to build a protein. That’s gene expression! The Central Dogma follows this flow of information: DNA to RNA to protein. Tap me whenever you’d like a hand. We’ll start by finding the gene, and you can swipe when you’re ready for the next step.
    """
    static let playersIntroduction = "Let’s meet the protein-making crew! Swipe through the cards to explore each molecule’s job. Tap a speaker to hear its definition."
    static let gameIntroduction = "Welcome to RNA Relay! Copy a protein-coding gene’s RNA, edit the message, and build an amino acid chain. Then explore folding and two finishing examples. Choose a tool, then tap its target, or drag the tool into place. Correct matches earn points. Mistakes leave the molecule unchanged, and hints are free. Tap me during the game to hear the current instruction and follow along."
    static let gameComplete = "Message delivered! You practiced transcription, processing, translation, folding, and protein finishing. You can start a new round with a different stop codon, or tap Done to return to the lesson."

    /// Stable IDs let identical repeated game instructions share one local clip.
    static func cueID(_ prefix: String, text: String) -> String {
        let hash = text.utf8.reduce(UInt64(14695981039346656037)) { ($0 ^ UInt64($1)) &* 1099511628211 }
        return prefix + "." + String(hash, radix: 16)
    }
}

extension CentralDogmaStep {
    var narrationID: String { self == .overview ? "reference.big-picture" : "lesson.\(id)" }
    var narrationDescription: String { CentralDogmaNarrationText.plain(content.bullets.joined(separator: " ")) }
    var narrationIntroduction: String {
        switch self {
        case .overview: "Let’s put the whole journey together."
        case .transcriptionStart: "First, let’s find the start of a gene."
        case .transcriptionBuild: "Now the cell writes an RNA copy of the gene."
        case .transcriptionEnd: "The RNA message is ready to be released."
        case .processing: "Before this message leaves the nucleus, it gets a little editing."
        case .translationStart: "Next, the message meets the ribosome."
        case .translationBuild: "Now the ribosome links amino acids into a growing chain."
        case .translationEnd: "A stop signal tells the ribosome when the chain is finished."
        case .folding: "The new chain needs to fold into a useful shape."
        case .finishing: "Some proteins need a few finishing touches."
        }
    }
    var narrationText: String { narrationIntroduction + "\n\n" + narrationDescription }
}

extension CentralDogmaPlayer {
    var narrationID: String { "player.\(id)" }
    var narrationText: String { CentralDogmaNarrationText.plain(title + ". " + bullets.joined(separator: " ")) }
}

extension CentralDogmaGameStep {
    var narrationID: String { CentralDogmaNarrationText.cueID("game.instruction", text: instruction) }
}

extension CentralDogmaGameMilestone {
    var narrationText: String { title + "\n\n" + body }
    var narrationID: String { CentralDogmaNarrationText.cueID("game.result", text: narrationText) }
}
