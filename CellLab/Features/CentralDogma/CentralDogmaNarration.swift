import Foundation

enum CentralDogmaNarrationText {
    static func plain(_ text: String) -> String {
        text.replacingOccurrences(of: "**", with: "")
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    static let overview = """
    Fun fact! With a jellyfish gene, cats, mice, and even bacteria can glow green under blue light. How? The genetic code is nearly universal, so their cells can build the same glowing protein! That’s gene expression! DNA is copied into RNA, then ribosomes read the message to build a protein. Swipe to explore, and tap me for a hand. Let’s find the gene!
    """
    static let playersIntroduction = "Let’s meet the protein-making crew! Swipe through the cards to explore each molecule’s job. Tap a speaker to hear its definition."
    static let gameIntroduction = "Let’s turn DNA into a protein! Copy the gene, send the mRNA out, and build a chain at the ribosome. Tap each matching RNA base. For other steps, pick a molecule and tap its glowing target, or drag it there. Tap me for help!"
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
