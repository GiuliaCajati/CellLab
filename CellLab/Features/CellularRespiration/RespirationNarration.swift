import Foundation

enum RespirationNarration {
    static let overview = """
    Every time you blink, your cells spend ATP! Where does that energy come from? Cellular respiration! Cells break down fuel, like glucose, and capture some of its energy in ATP. We’ll follow the sugar, visit the mitochondrion, and see a tiny enzyme powered by flowing hydrogen ions. Swipe through the steps, and I’ll read each description. Below the cards, you can hear the big picture and the overall reaction. Meet the key players explains the helpers. Let’s make some ATP!
    """
    static let playersIntroduction = "Let’s meet the energy-making crew! I’ll read the definitions on each card. Swipe to a new helper to hear its job, or tap Stop whenever you want a quiet moment."
    static let equation = """
    Here’s the overall reaction for aerobic cellular respiration. One glucose molecule plus six oxygen molecules produces six carbon dioxide molecules and six water molecules. Some of the released energy is captured in ATP, and some is released as heat. The formula is a summary of many small reactions, not one giant step!
    """

    static func plain(_ text: String) -> String {
        text.replacingOccurrences(of: "**", with: "")
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}

extension RespirationStep {
    var narrationID: String { self == .overview ? "reference.big-picture" : "lesson.\(id)" }
    var narrationIntroduction: String {
        switch self {
        case .overview: "Let’s connect the whole energy journey."
        case .glycolysis: "First, one sugar is split into two smaller molecules."
        case .transition: "Next, the cell prepares the fuel for the cycle."
        case .krebs: "Now the cycle loads up the electron carriers."
        case .transport: "The electrons’ energy helps build a hydrogen ion gradient."
        case .chemiosmosis: "Now flowing hydrogen ions power ATP synthase."
        case .accounting: "Let’s count the ATP and compare the model with real cells."
        case .efficiency: "Some energy is captured in ATP, and some becomes heat."
        case .anaerobic: "Some microbes use a different final electron acceptor."
        case .fermentation: "Fermentation recycles a carrier so glycolysis can keep going."
        }
    }
    var narrationText: String {
        narrationIntroduction + "\n\n" + RespirationNarration.plain(content.bullets.joined(separator: " "))
    }
}

extension RespirationPlayer {
    var narrationID: String { "player.\(id)" }
    var narrationText: String {
        RespirationNarration.plain(title + ". " + caption + ". " + bullets.joined(separator: " "))
    }
}
