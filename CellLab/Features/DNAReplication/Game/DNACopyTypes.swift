import Foundation

enum DNACopyBase: String, CaseIterable, Identifiable, Sendable {
    case a = "A", t = "T", c = "C", g = "G"
    var id: String { rawValue }
    var complement: Self {
        switch self {
        case .a: return .t
        case .t: return .a
        case .c: return .g
        case .g: return .c
        }
    }
    var payload: String { "celllab.dna.base.\(rawValue)" }
    init?(payload: String) {
        guard payload.hasPrefix("celllab.dna.base.") else { return nil }
        self.init(rawValue: String(payload.dropFirst("celllab.dna.base.".count)))
    }
}

enum DNACopyTool: String, CaseIterable, Identifiable, Sendable {
    case helicase, binding, primase, polymerase, repair, ligase
    var id: String { rawValue }
    var title: String {
        switch self {
        case .helicase: return "Helicase"
        case .binding: return "Binding proteins"
        case .primase: return "Primase"
        case .polymerase: return "DNA polymerase"
        case .repair: return "Repair enzymes"
        case .ligase: return "Ligase"
        }
    }
    var memory: String {
        switch self {
        case .helicase: return "Unzip DNA"
        case .binding: return "Keep it open"
        case .primase: return "Make a start"
        case .polymerase: return "Build + check"
        case .repair: return "Remove RNA"
        case .ligase: return "Glue the backbone"
        }
    }
    var asset: String? {
        switch self {
        case .helicase: return "DNAHelicaseZipper"
        case .primase: return "DNAPrimaseStarter"
        case .polymerase: return "DNAPolymeraseBuilder"
        case .ligase: return "DNALigaseGlue"
        case .binding, .repair: return nil
        }
    }
    var symbol: String { self == .binding ? "circle.grid.2x2.fill" : "eraser.fill" }
    var payload: String { "celllab.dna.tool.\(rawValue)" }
    init?(payload: String) {
        guard payload.hasPrefix("celllab.dna.tool.") else { return nil }
        self.init(rawValue: String(payload.dropFirst("celllab.dna.tool.".count)))
    }
}

enum DNACopyStage: Int, CaseIterable, Identifiable, Sendable {
    case origin, unwind, stabilize, prime, leading, lagging, remove, replace, seal, complete
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .origin: return "Find the starting line"
        case .unwind: return "Unzip the DNA"
        case .stabilize: return "Keep the strands apart"
        case .prime: return "Set the starting block"
        case .leading: return "Build toward the fork"
        case .lagging: return "Build in short stretches"
        case .remove: return "Remove the RNA primers"
        case .replace: return "Fill the gaps with DNA"
        case .seal: return "Seal the backbone"
        case .complete: return "Two copies. Nicely done."
        }
    }
    var group: Int {
        switch self {
        case .origin, .unwind, .stabilize, .prime: return 0
        case .leading, .lagging: return 1
        case .remove, .replace, .seal, .complete: return 2
        }
    }
    var isJunction: Bool { self == .remove || self == .replace || self == .seal }
}

enum DNACopyLane: String, Sendable { case leading, lagging }

enum DNACopySite: Int, CaseIterable, Identifiable, Hashable, Sendable {
    case leading, laggingOne, laggingTwo
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .leading: return "Leading strand"
        case .laggingOne: return "Lagging fragment 1"
        case .laggingTwo: return "Lagging fragment 2"
        }
    }
}

enum DNACopyTarget: Hashable, Sendable {
    case origin(Int), helicase, binding(Int), primer(DNACopyLane, Int)
    case load(DNACopyLane, Int), base(DNACopyLane, Int), mismatch
    case remove(DNACopySite), replacement(DNACopySite, Int), nick(DNACopySite)
}

struct DNACopyCelebration: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let body: String
    let tags: [String]
    let next: DNACopyStage?
    var isCheck = false
}

// The two original templates are complementary and antiparallel.
// Leading indices run bottom → top, in the direction of new 5′ → 3′ synthesis.
// Lagging fragment 0 is older (lower); fragment 1 starts closer to the fork.
enum DNACopySequence {
    static let leading: [DNACopyBase] = [.a, .c, .g, .t, .a, .c, .g, .t]
    static let count = 8
    static let fragmentLength = 4
    static let fragmentCount = 2
    static let primerLength = 2

    static func row(lane: DNACopyLane, index: Int) -> Int {
        lane == .leading ? count - 1 - index :
            (fragmentCount - 1 - index / fragmentLength) * fragmentLength + index % fragmentLength
    }
    static func template(lane: DNACopyLane, index: Int) -> DNACopyBase {
        if lane == .leading { return leading[index] }
        return leading[count - 1 - row(lane: lane, index: index)].complement
    }
    static func replacementTemplate(site: DNACopySite, index: Int) -> DNACopyBase {
        if site == .leading { return leading[index] }
        return template(lane: .lagging, index: (site.rawValue - 1) * fragmentLength + index)
    }
}
