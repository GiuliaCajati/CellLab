import Foundation

/// Shared by the home cards, spoken tour, and audio exporter.
enum CellLabHomeModule: String, CaseIterable, Identifiable, Hashable, Sendable {
    case structures, cycle, mitosis, meiosis, sphase, dogma, respiration, technology

    var id: String { rawValue }
    var cueID: String { "home.\(rawValue)" }

    var title: String {
        switch self {
        case .structures: "Cell Structures"
        case .cycle: "Cell Life Cycle"
        case .mitosis: "Mitosis"
        case .meiosis: "Meiosis"
        case .sphase: "S Phase"
        case .dogma: "Central Dogma"
        case .respiration: "Cellular Respiration"
        case .technology: "DNA Technology"
        }
    }

    var subtitle: String {
        switch self {
        case .structures: "Meet the tiny team."
        case .cycle: "Grow. Copy. Divide."
        case .mitosis: "One becomes two."
        case .meiosis: "Mix things up."
        case .sphase: "DNA replication"
        case .dogma: "Transcription. Translation."
        case .respiration: "ATP, made here."
        case .technology: "Small tools. Big possibilities."
        }
    }

    var image: String {
        switch self {
        case .structures: "art_structures"
        case .cycle: "art_cycle"
        case .mitosis: "art_mitosis"
        case .meiosis: "art_meiosis"
        case .sphase: "art_s_phase"
        case .dogma: "art_dogma"
        case .respiration: "art_respiration"
        case .technology: "art_dna"
        }
    }

    var actionLabel: String {
        switch self {
        case .structures, .respiration: "Let’s Explore →"
        case .cycle: "Living the life →"
        case .mitosis: "Let’s split →"
        case .meiosis: "Let’s mix →"
        case .sphase: "Let’s Synthesize →"
        case .dogma: "Making Peptide →"
        case .technology: "Let’s Get Crisp →"
        }
    }

    var overview: String {
        switch self {
        case .structures:
            "Meet the tiny team inside a cell! Explore the membrane, nucleus, and organelles, and discover how they work together to keep the cell going. Tap a part to learn its job."
        case .cycle:
            "What does a cell do between divisions? Follow it as it grows, copies its DNA, checks its work, and divides. You can explore the cycle and meet the checkpoint crew. Some cells even take a long rest!"
        case .mitosis:
            "One cell, two matching teams! Follow the chromosomes as their copies line up and separate, making two nuclei with matching sets of chromosomes."
        case .meiosis:
            "Time to mix things up! Pair chromosomes from mom and dad, see how they swap matching sections, and follow two divisions that make cells with half the usual chromosome number."
        case .sphase:
            "How does a cell copy its DNA? Watch helicase unzip the double helix, then meet the enzymes that build and join the new strands. Each finished DNA molecule keeps one original strand."
        case .dogma:
            "Turn a gene into a protein! Follow the message from DNA to RNA in the nucleus, then out to a ribosome, where amino acids join into a chain."
        case .respiration:
            "Where does a cell get usable energy? Follow glucose through glycolysis and into the mitochondrion, and see how oxygen helps the cell make ATP. Explore each step and the big picture below."
        case .technology:
            "Meet the tools scientists use to study and change DNA! Explore how PCR makes more copies, how CRISPR targets a DNA sequence, and how other tools help us read, compare, and use genetic information."
        }
    }

    /// Present only when this lesson has an implemented, reachable game.
    var gameSummary: String? {
        switch self {
        case .mitosis:
            "In the game, help organize and separate the chromosomes, then divide the cell. Open the lesson and tap Play game to try it!"
        case .meiosis:
            "In the game, help pair and separate chromosomes through both divisions to make the final cells. Open the lesson and tap Play game to try it!"
        case .sphase:
            "In the DNA copying game, unzip the DNA, add matching building blocks, and seal the strands. Open the lesson and tap Play game to try it!"
        case .dogma:
            "In RNA Relay, carry the message from the gene to the ribosome and build an amino acid chain. Open the lesson and tap Play game to try it!"
        default: nil
        }
    }

    var hasGame: Bool { gameSummary != nil }
    var narrationText: String { [overview, gameSummary].compactMap { $0 }.joined(separator: " ") }
}

enum CellLabHomeNarration {
    static let welcome = "Welcome to CellLab! I’m your little lab buddy. Pick a lesson to explore the tiny world inside your cells, and tap me whenever you want a friendly explanation. See a game controller on a card? That lesson has a game, too! Tap the game badge to jump into the game, or open the lesson to explore first. Tap a speaker on a lesson card to hear what you’ll discover. Ready to explore?"
}
