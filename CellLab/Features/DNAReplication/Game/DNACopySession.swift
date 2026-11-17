import Foundation
import Observation

@MainActor @Observable final class DNACopySession {
    // Match LessonNarrator's workaround for the iOS 26.2 isolated-deinit crash.
    nonisolated deinit {}
    private(set) var stage: DNACopyStage = .origin
    private(set) var selectedTool: DNACopyTool?
    private(set) var selectedBase: DNACopyBase?
    private(set) var origin: Int?
    private(set) var unwound = false
    private(set) var bindingSites: Set<Int> = []
    private(set) var leadingPrimed = false
    private(set) var leadingLoaded = false
    private(set) var leading: [DNACopyBase?] = Array(repeating: nil, count: DNACopySequence.count)
    private(set) var lagging: [DNACopyBase?] = Array(repeating: nil, count: DNACopySequence.count)
    private(set) var laggingPrimed: Set<Int> = []
    private(set) var laggingLoaded: Int?
    private(set) var fragment = 0
    private(set) var mismatchIntroduced = false
    private(set) var mismatchRemoved = false
    private(set) var mismatchCorrected = false
    private(set) var removedPrimers: Set<DNACopySite> = []
    private(set) var replacements: [DNACopySite: [DNACopyBase?]] = [:]
    private(set) var sealed: Set<DNACopySite> = []
    private(set) var celebration: DNACopyCelebration?
    private(set) var notice = "Tap a glowing origin on the DNA."
    private(set) var successSerial = 0
    private(set) var correctionSerial = 0
    private(set) var placedBases = 0
    private(set) var usedTools: Set<DNACopyTool> = []
    private(set) var lastSuccessTarget: DNACopyTarget?

    // A second, explicit way to use a selection. It obeys exactly the same
    // biological guards as touching or dragging to a molecular target.
    var canApplySelection: Bool {
        guard celebration == nil, let target = activeTarget else { return false }
        if case .origin = target { return false }
        if expectedBase != nil {
            if case .replacement = target, selectedTool != .polymerase { return false }
            return selectedBase != nil
        }
        return selectedTool != nil
    }
    var primaryActionTitle: String {
        guard let target = activeTarget else { return "Continue when ready" }
        if case .origin = target { return "Tap an origin" }
        if expectedBase != nil {
            if case .replacement = target, selectedTool != .polymerase { return "Choose DNA polymerase" }
            return selectedBase.map { "Attach \($0.rawValue)" } ?? "Choose a nucleotide"
        }
        return selectedTool.map { "Use \($0.title)" } ?? "Choose a tool"
    }
    func applySelection() {
        guard canApplySelection, let target = activeTarget else { hint(); return }
        tap(target)
    }
    func missedDrop() {
        guard celebration == nil else { return }
        notice = expectedBase == nil ? "Aim for the glowing +, or select a tool and use the button below." :
            "Drop on the glowing + at the growing 3′ end—or use Attach below."
    }

    var correctingMismatch: Bool { mismatchIntroduced && !mismatchCorrected }
    func synthesizedBase(lane: DNACopyLane, index: Int) -> DNACopyBase? {
        guard (0..<DNACopySequence.count).contains(index) else { return nil }
        if lane == .leading {
            return index < 2 ? replacements[.leading]?[index] : leading[index]
        }
        if index % 4 < 2, let site = DNACopySite(rawValue: index / 4 + 1) {
            return replacements[site]?[index % 4]
        }
        return lagging[index]
    }
    var activeSite: DNACopySite? {
        switch stage {
        case .remove: return DNACopySite.allCases.first { !removedPrimers.contains($0) }
        case .replace: return DNACopySite.allCases.first { site in
            (replacements[site] ?? [nil, nil]).contains(where: { $0 == nil })
        }
        case .seal: return DNACopySite.allCases.first { !sealed.contains($0) }
        default: return nil
        }
    }
    var activeTarget: DNACopyTarget? {
        guard celebration == nil else { return nil }
        switch stage {
        case .origin: return .origin(1)
        case .unwind: return .helicase
        case .stabilize: return (0..<3).first(where: { !bindingSites.contains($0) }).map { .binding($0) }
        case .prime: return .primer(.leading, 0)
        case .leading:
            if correctingMismatch && !mismatchRemoved { return .mismatch }
            if !leadingLoaded { return .load(.leading, 0) }
            return (2..<DNACopySequence.count).first(where: { leading[$0] == nil }).map { .base(.leading, $0) }
        case .lagging:
            guard fragment < DNACopySequence.fragmentCount else { return nil }
            if !laggingPrimed.contains(fragment) { return .primer(.lagging, fragment) }
            if laggingLoaded != fragment { return .load(.lagging, fragment) }
            let start = fragment * DNACopySequence.fragmentLength
            return (start + 2..<start + 4).first(where: { lagging[$0] == nil }).map { .base(.lagging, $0) }
        case .remove: return activeSite.map { .remove($0) }
        case .replace:
            guard let site = activeSite,
                  let index = (replacements[site] ?? [nil, nil]).firstIndex(where: { $0 == nil }) else { return nil }
            return .replacement(site, index)
        case .seal: return activeSite.map { .nick($0) }
        case .complete: return nil
        }
    }
    var expectedBase: DNACopyBase? {
        guard let target = activeTarget else { return nil }
        switch target {
        case let .base(lane, index): return DNACopySequence.template(lane: lane, index: index).complement
        case let .replacement(site, index): return DNACopySequence.replacementTemplate(site: site, index: index).complement
        default: return nil
        }
    }
    var neededTool: DNACopyTool? {
        guard let target = activeTarget else { return nil }
        switch target {
        case .helicase: return .helicase
        case .binding: return .binding
        case .primer: return .primase
        case .load, .mismatch: return .polymerase
        case .remove: return .repair
        case .replacement: return .polymerase
        case .nick: return .ligase
        case .origin, .base: return nil
        }
    }
    var targetLabel: String {
        guard let target = activeTarget else { return "Continue when ready" }
        switch target {
        case .origin: return "Origin of replication"
        case .helicase: return "Unzip here with helicase"
        case .binding: return "Stabilize this single DNA strand"
        case .primer: return "Place an RNA primer with primase"
        case .load: return "Attach DNA polymerase to the primer’s 3′ end"
        case .base: return "Growing 3′ end. Add \(expectedBase?.rawValue ?? "the matching base")"
        case .mismatch: return "Mismatched base. Use DNA polymerase to remove it"
        case .remove: return "Remove the RNA primer with repair enzymes"
        case .replacement: return "Fill from the neighboring 3′ end. Add \(expectedBase?.rawValue ?? "a matching DNA base")"
        case .nick: return "Seal the sugar-phosphate backbone with ligase"
        }
    }
    var instruction: String {
        switch stage {
        case .origin: return "Tap a glowing origin. We’ll copy one short section."
        case .unwind: return "Choose helicase. Drag it to the glowing target—or tap the target."
        case .stabilize: return "Use binding proteins on the three glowing spots."
        case .prime: return "Use primase to lay an RNA primer on the leading template."
        case .leading:
            if correctingMismatch && !mismatchRemoved { return "Use DNA polymerase on the red mismatch to remove it."
            }
            if !leadingLoaded { return "Bring DNA polymerase to the primer’s exposed 3′ end." }
            return "Drag a matching nucleotide onto the glowing 3′ end. Build upward, toward the fork."
        case .lagging:
            if !laggingPrimed.contains(fragment) { return "Use primase: this Okazaki fragment needs its own RNA primer." }
            if laggingLoaded != fragment { return "Attach DNA polymerase to this primer’s 3′ end." }
            return "Add matching nucleotides downward, away from the fork. Growth is still 5′ → 3′."
        case .remove: return "Use repair enzymes to remove each temporary RNA primer."
        case .replace: return "Select DNA polymerase, then add matching DNA bases from the neighboring 3′ end."
        case .seal: return "Use ligase at each glowing nick to join the backbone."
        case .complete: return "Each DNA molecule has one parental strand and one new strand."
        }
    }

    func choose(tool: DNACopyTool) {
        guard celebration == nil, stage != .complete else { return }
        selectedTool = tool; selectedBase = nil
        notice = "\(tool.title) · \(tool.memory). Tap the glowing target."
    }
    func choose(base: DNACopyBase) {
        guard celebration == nil, stage != .complete else { return }
        guard expectedBase != nil else {
            notice = neededTool.map { "Use \($0.title.lowercased()) at the glowing target first." } ?? instruction
            return
        }
        selectedBase = base
        notice = "\(base.rawValue) selected. Tap the glowing + or Attach \(base.rawValue)."
    }
    @discardableResult func receive(_ payload: String, at target: DNACopyTarget) -> Bool {
        guard celebration == nil else { return false }
        if let base = DNACopyBase(payload: payload) { return add(base, at: target) }
        if let tool = DNACopyTool(payload: payload) { return use(tool, at: target) }
        return false
    }
    func tap(_ target: DNACopyTarget) {
        guard celebration == nil else { return }
        if case let .origin(index) = target { start(at: index); return }
        // A selected nucleotide is only applied to a nucleotide target.
        switch target {
        case .base, .replacement:
            if let selectedBase { _ = add(selectedBase, at: target); return }
        default: break
        }
        guard let selectedTool else { hint(); return }
        _ = use(selectedTool, at: target)
    }
    func hint() {
        if let base = expectedBase {
            notice = "Try \(base.rawValue). DNA polymerase adds it to the exposed 3′ end."
        } else if let tool = neededTool { notice = "Choose \(tool.title.lowercased()), then tap the glowing target." }
        else { notice = "Tap a glowing origin to begin copying DNA." }
    }
    func start(at index: Int) {
        guard stage == .origin, celebration == nil, (0..<3).contains(index) else { return }
        origin = index
        lastSuccessTarget = .origin(index)
        celebrate("Starting line found!", "Replication begins at origins of replication. Hundreds of starting sites help a human cell copy billions of nucleotides in about 8–10 hours.", ["Origins of replication", "S phase"], next: .unwind)
    }
    @discardableResult func use(_ tool: DNACopyTool, at target: DNACopyTarget) -> Bool {
        guard celebration == nil, stage != .complete else { return false }
        let validBinding: Bool
        if case let .binding(index) = target { validBinding = stage == .stabilize && (0..<3).contains(index) && !bindingSites.contains(index) }
        else { validBinding = false }
        guard target == activeTarget || validBinding else { reject("Use the glowing target for this task."); return false }
        guard tool == neededTool else {
            reject(neededTool.map { "This task needs \($0.title.lowercased())." } ?? "Drag a matching DNA nucleotide to the growing 3′ end.")
            return false
        }
        selectedTool = tool; selectedBase = nil; usedTools.insert(tool)
        lastSuccessTarget = target
        switch target {
        case .helicase:
            unwound = true
            celebrate("Unzipped!", "Helicase breaks the hydrogen bonds between complementary base pairs, separating the two DNA strands. ATP powers enzyme work.", ["Helicase", "Hydrogen bonds", "ATP"], next: .stabilize)
        case let .binding(index):
            bindingSites.insert(index); succeed("Strand held open.")
            if bindingSites.count == 3 {
                celebrate("Open for copying!", "Binding proteins stabilize the separated strands and keep them from rejoining.", ["Binding proteins", "DNA templates"], next: .prime)
            }
        case let .primer(lane, fragment):
            if lane == .leading {
                leadingPrimed = true
                celebrate("Starting block ready!", "Primase makes a short RNA primer. Its exposed 3′ end gives DNA polymerase a place to begin; DNA polymerase cannot start from scratch.", ["Primase", "RNA primer", "3′ end"], next: .leading)
            } else { laggingPrimed.insert(fragment); succeed("RNA primer placed. Bring in DNA polymerase.") }
        case let .load(lane, fragment):
            if lane == .leading { leadingLoaded = true } else { laggingLoaded = fragment }
            succeed("Builder attached. Match a floating nucleotide to the template.")
        case .mismatch:
            leading[4] = nil; mismatchRemoved = true
            succeed("Mismatch removed. Add the correct complementary DNA nucleotide.")
        case let .remove(site):
            removedPrimers.insert(site); succeed("RNA primer removed. The next primer is highlighted.")
            if removedPrimers.count == DNACopySite.allCases.count {
                celebrate("Temporary starts removed!", "Repair enzymes remove the RNA primers from both strands. DNA polymerase will replace them with DNA nucleotides.", ["Repair enzymes", "Primer removal"], next: .replace)
            }
        case .replacement:
            // Loading the builder and adding a nucleotide are separate actions.
            succeed("DNA polymerase is ready. Drag a complementary DNA nucleotide into the gap.")
        case let .nick(site):
            sealed.insert(site); succeed("Covalent backbone bond sealed.")
            if sealed.count == DNACopySite.allCases.count {
                celebrate("All glued together!", "Ligase forms covalent bonds in the sugar-phosphate backbone. After primer replacement, these bonds connect neighboring Okazaki fragments into a continuous strand.", ["Ligase", "Covalent bonds", "Sugar-phosphate backbone"], next: .complete)
            }
        default: return false
        }
        return true
    }
    @discardableResult func add(_ base: DNACopyBase, at target: DNACopyTarget) -> Bool {
        guard celebration == nil, target == activeTarget, let expected = expectedBase else {
            if celebration == nil { reject("Build at the glowing 3′ end. Each new stretch needs an RNA primer first.") }
            return false
        }
        if case .replacement = target, selectedTool != .polymerase {
            reject("Choose DNA polymerase to fill this gap with DNA."); return false
        }
        guard base == expected else {
            reject("\(expected.complement.rawValue) pairs with \(expected.rawValue). Try \(expected.rawValue).")
            return false
        }
        selectedBase = nil; placedBases += 1
        lastSuccessTarget = target
        switch target {
        case let .base(lane, index):
            if lane == .leading {
                guard leadingPrimed && leadingLoaded else { return false }
                leading[index] = base
                succeed("\(baseCheer) \(expected.complement.rawValue)–\(base.rawValue) paired. Growing 5′ → 3′.")
                if index == 3 && !mismatchIntroduced {
                    // A simulated polymerase slip appears at the NEXT growing end.
                    // A correctly placed player base is never changed into an error.
                    mismatchIntroduced = true
                    let correct = DNACopySequence.template(lane: .leading, index: 4).complement
                    leading[4] = DNACopyBase.allCases.first { $0 != correct }
                    celebration = DNACopyCelebration(title: "A mismatch slipped in", body: "DNA polymerase proofreads while building. Use the builder on the red mismatch, then add the correct nucleotide.", tags: ["Proofreading", "Growing 3′ end"], next: nil, isCheck: true)
                } else if index == 4 && mismatchRemoved && !mismatchCorrected {
                    mismatchCorrected = true
                    celebrate("Caught and corrected!", "DNA polymerase removes mismatched nucleotides and inserts correct ones. With proofreading and additional repair, the final error rate can be about one mistake per billion nucleotides. A permanent uncorrected change is a mutation.", ["Proofreading", "DNA repair", "Mutation"], next: nil)
                } else if (2..<8).allSatisfy({ leading[$0] != nil }) {
                    celebrate("One continuous stretch!", "The leading strand grows continuously, 5′ → 3′, toward the unwinding replication fork. New nucleotides always join an exposed 3′ end.", ["Leading strand", "5′ → 3′"], next: .lagging)
                }
            } else {
                guard laggingPrimed.contains(fragment), laggingLoaded == fragment else { return false }
                lagging[index] = base
                succeed("\(baseCheer) \(expected.complement.rawValue)–\(base.rawValue) paired. This fragment grows away from the fork.")
                if index % 4 == 3 {
                    let finished = fragment
                    fragment += 1; laggingLoaded = nil
                    if fragment == DNACopySequence.fragmentCount {
                        celebrate("Fragments built!", "The lagging strand is made discontinuously as Okazaki fragments. Each grows 5′ → 3′ away from the fork and begins with its own RNA primer.", ["Lagging strand", "Okazaki fragments", "RNA primers"], next: .remove)
                    } else {
                        celebrate("An Okazaki fragment!", "This short stretch grew 5′ → 3′ away from the fork. The next fragment begins closer to the fork and needs a new RNA primer.", ["Okazaki fragment", "Primase"], next: nil)
                        notice = "Fragment \(finished + 1) finished. Prime the next fragment."
                    }
                }
            }
        case let .replacement(site, index):
            var values = replacements[site] ?? [nil, nil]
            values[index] = base; replacements[site] = values
            succeed("\(baseCheer) DNA fills the gap from the neighboring 3′ end.")
            if DNACopySite.allCases.allSatisfy({ site in (replacements[site] ?? [nil, nil]).allSatisfy { $0 != nil } }) {
                celebrate("RNA replaced with DNA!", "DNA polymerase fills the gaps using a neighboring 3′ end. A nick remains where the replacement DNA meets the existing strand; ligase will seal that last backbone bond.", ["DNA polymerase", "Primer replacement", "Nick"], next: .seal)
            }
        default: return false
        }
        return true
    }
    func continueAfterCelebration() {
        guard let card = celebration else { return }
        celebration = nil
        if let next = card.next {
            stage = next; selectedTool = nil; selectedBase = nil
        }
        notice = instruction
    }
    private func succeed(_ message: String) { successSerial += 1; notice = message }
    private var baseCheer: String {
        ["Nice match!", "That fits!", "Good pair!", "Keep building!"][max(0, placedBases - 1) % 4]
    }
    private func reject(_ message: String) { correctionSerial += 1; notice = message }
    private func celebrate(_ title: String, _ body: String, _ tags: [String], next: DNACopyStage?) {
        successSerial += 1
        celebration = DNACopyCelebration(title: title, body: body, tags: tags, next: next)
    }
}
