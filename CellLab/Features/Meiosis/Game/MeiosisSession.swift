import Foundation

/// Content is limited to the user's supplied Meiosis Master Edition specification.
/// Four illustrated chromosomes = two homologous pairs (2n = 4); humans have 2n = 46.
/// One reciprocal exchange per pair makes the four illustrated products distinct.
nonisolated struct MeiosisSession {
    enum Pole: String, CaseIterable, Identifiable {
        case left = "Left", right = "Right", top = "Top", bottom = "Bottom"
        var id: Self { self }
    }

    enum Stage: Int, CaseIterable, Identifiable {
        case interphase, prophaseI, metaphaseI, anaphaseI, telophaseI
        case interkinesis, prophaseII, metaphaseII, anaphaseII, telophaseII, complete
        var id: Self { self }
        var title: String {
            switch self {
            case .interphase: "Interphase"
            case .prophaseI: "Prophase I"
            case .metaphaseI: "Metaphase I"
            case .anaphaseI: "Anaphase I"
            case .telophaseI: "Telophase I & cytokinesis"
            case .interkinesis: "Interkinesis"
            case .prophaseII: "Prophase II"
            case .metaphaseII: "Metaphase II"
            case .anaphaseII: "Anaphase II"
            case .telophaseII: "Telophase II & cytokinesis"
            case .complete: "Meiosis complete"
            }
        }
        var act: String {
            switch self {
            case .interphase: "PREPARE"
            case .prophaseI, .metaphaseI, .anaphaseI, .telophaseI: "MEIOSIS I · HOMOLOGS"
            case .interkinesis: "BETWEEN DIVISIONS"
            case .prophaseII, .metaphaseII, .anaphaseII, .telophaseII: "MEIOSIS II · SISTERS"
            case .complete: "ONE → TWO → FOUR"
            }
        }
    }

    enum Action {
        case replicateDNA, prepareDivision, condenseI(Int), openEnvelopeI
        case synapse(Int, matched: Bool), crossOver(Int, matched: Bool)
        case flipPair(Int), choosePole(Pole), attachI(Int), alignI(Int, nearEquator: Bool)
        case inspectI, protectCentromeres, separateHomologs, rebuildI(Int), divideI
        case blockReplication, makeInterkinesisProteins, attemptExtraReplication
        case condenseII(Int), openEnvelopeII(Int), attachII(Int)
        case alignII(Int, nearEquator: Bool), inspectII, splitCentromeres, separateSisters
        case rebuildII(Int), relaxChromosomes, divideII, advance, restart
    }

    static let chromosomeIDs = Array(0..<4)
    static let pairIDs = Array(0..<2)
    static let humanGameteCombinations: UInt64 = 8_388_608
    static let humanZygoteCombinations = humanGameteCombinations * humanGameteCombinations

    private(set) var stage: Stage = .prophaseI
    private(set) var replicated = true
    private(set) var divisionPrepared = true
    private(set) var condensedI: Set<Int> = []
    private(set) var envelopeOpenI = false
    private(set) var synapsed: Set<Int> = []
    private(set) var crossed: Set<Int> = []
    /// true = maternal homolog faces left. Each pair is independently oriented.
    private(set) var maternalLeft: [Bool]
    private(set) var selectedPole: Pole = .left
    private(set) var leftAttachments: Set<Int> = []
    private(set) var rightAttachments: Set<Int> = []
    private(set) var alignedI: Set<Int> = []
    private(set) var checkpointI = false
    private(set) var centromeresProtected = false
    private(set) var separatedI = false
    private(set) var nucleiI: Set<Int> = []
    private(set) var dividedI = false
    private(set) var replicationBlocked = false
    private(set) var interkinesisProteins = false
    private(set) var condensedII: Set<Int> = []
    private(set) var envelopesOpenII: Set<Int> = []
    private(set) var topAttachments: Set<Int> = []
    private(set) var bottomAttachments: Set<Int> = []
    private(set) var alignedII: Set<Int> = []
    private(set) var checkpointII = false
    private(set) var centromeresSplit = false
    private(set) var separatedII = false
    private(set) var nucleiII: Set<Int> = []
    private(set) var relaxedII = false
    private(set) var dividedII = false
    private(set) var penalties = 0
    private(set) var feedback = "One cell. Two divisions. Let's go."
    private(set) var needsCorrection = false

    init(maternalLeft: [Bool]? = nil) {
        if let maternalLeft, maternalLeft.count == 2 {
            self.maternalLeft = maternalLeft
        } else {
            self.maternalLeft = [Bool.random(), Bool.random()]
        }
    }

    var attachmentsIComplete: Bool { leftAttachments.count == 2 && rightAttachments.count == 2 }
    var attachmentsIIComplete: Bool { topAttachments.count == 4 && bottomAttachments.count == 4 }
    var canAdvance: Bool {
        switch stage {
        case .interphase: replicated && divisionPrepared
        case .prophaseI: condensedI.count == 4 && envelopeOpenI && synapsed.count == 2 && crossed.count == 2
        case .metaphaseI: attachmentsIComplete && alignedI.count == 2 && checkpointI
        case .anaphaseI: centromeresProtected && separatedI
        case .telophaseI: nucleiI.count == 2 && dividedI
        case .interkinesis: replicationBlocked && interkinesisProteins
        case .prophaseII: condensedII.count == 4 && envelopesOpenII.count == 2
        case .metaphaseII: attachmentsIIComplete && alignedII.count == 4 && checkpointII
        case .anaphaseII: centromeresSplit && separatedII
        case .telophaseII: nucleiII.count == 4 && relaxedII && dividedII
        case .complete: false
        }
    }

    var instruction: String {
        switch stage {
        case .interphase:
            return !replicated ? "Copy the DNA. Keep the chromosome count." : "Make division proteins and duplicate centrosomes."
        case .prophaseI:
            if condensedI.count < 4 { return "Tap each DNA bundle to pack it." }
            if !envelopeOpenI { return "Open the nuclear envelope." }
            if synapsed.count < 2 { return "Drag matching homologs together—or tap to pair." }
            return "Tap each chiasma to swap matching DNA segments."
        case .metaphaseI:
            if !attachmentsIComplete { return "Orient pairs. Choose a pole; connect its homologs." }
            return alignedI.count < 2 ? "Drag pairs to the equator—or tap to align." : "Inspect the double-file lineup."
        case .anaphaseI:
            return !centromeresProtected ? "Keep sisters joined at their centromeres." : "Pull homologs to opposite poles."
        case .telophaseI:
            return nucleiI.count < 2 ? "Tap both chromosome groups to rebuild nuclei." : "Pinch the cytoplasm into two cells."
        case .interkinesis:
            return !replicationBlocked ? "Block DNA replication. No second copy!" : "Make proteins for the next division."
        case .prophaseII:
            return condensedII.count < 4 ? "Tap chromosomes in both cells to re-pack them." : "Open both nuclear envelopes."
        case .metaphaseII:
            if !attachmentsIIComplete { return "Choose top or bottom. Connect each sister's kinetochore." }
            return alignedII.count < 4 ? "Move chromosomes onto each cell's equator." : "Inspect both single-file lineups."
        case .anaphaseII:
            return !centromeresSplit ? "Release the connections at the centromeres." : "Now pull sister chromatids apart."
        case .telophaseII:
            if nucleiII.count < 4 { return "Tap all four groups to rebuild nuclear envelopes." }
            return !relaxedII ? "Unpack chromosomes into chromatin." : "Divide both cells. Four haploid products!"
        case .complete:
            return "Four distinct chromosome combinations. Nicely divided."
        }
    }

    /// Chromosome identity: 0 = pair 1 maternal, 1 = pair 1 paternal, etc.
    func poleForHomolog(_ id: Int) -> Pole {
        let isMaternal = id % 2 == 0
        return isMaternal == maternalLeft[id / 2] ? .left : .right
    }
    /// In meiosis II, key = cell * 2 + pair. Each cell contains ONE homolog per pair.
    func homolog(in cell: Int, pair: Int) -> Int {
        let maternal = cell == 0 ? maternalLeft[pair] : !maternalLeft[pair]
        return pair * 2 + (maternal ? 0 : 1)
    }
    func alleles(homolog id: Int, sister: Int) -> String {
        let pair = id / 2
        let maternal = id % 2 == 0
        let parental = pair == 0 ? (maternal ? "AB" : "ab") : (maternal ? "CD" : "cd")
        guard crossed.contains(pair) else { return parental }
        // Only the two INNER non-sister chromatids exchanged their distal segments.
        if maternal && sister == 1 { return pair == 0 ? "Ab" : "Cd" }
        if !maternal && sister == 0 { return pair == 0 ? "aB" : "cD" }
        return parental
    }
    /// Product order: upper left, lower left, upper right, lower right.
    func gameteAlleles(_ product: Int) -> String {
        let cell = product / 2, sister = product % 2
        return Self.pairIDs.map { alleles(homolog: homolog(in: cell, pair: $0), sister: sister) }.joined(separator: " · ")
    }

    var facts: [String] {
        switch stage {
        case .interphase: [
            "An unreplicated chromosome contains one DNA double helix with associated packaging proteins.",
            "During S phase, DNA replication produces two identical sister chromatids joined at the centromere. Polymerases and other proteins support DNA synthesis and cell growth.",
            "DNA amount doubles; chromosome count stays the same: 2n = 46 in humans. This illustrated model uses 2n = 4.",
            "Division proteins are synthesized and centrosomes, which organize microtubules, duplicate before division."
        ]
        case .prophaseI: [
            "Chromatin condenses into visible chromosomes. Nuclear-envelope breakdown lets spindle microtubules reach kinetochores, protein attachment structures at centromeres. The envelope has two membranes and nuclear pores.",
            "Synapsis pairs maternal and paternal homologs gene by gene. Homologs have corresponding genes at corresponding positions and matching overall size, centromere position and banding; their alleles can differ.",
            "Crossing over exchanges corresponding segments between non-sister chromatids at chiasmata. Recombinant chromatids have new allele combinations; chromatids not involved remain parental.",
            "Here, one reciprocal exchange is made in each pair. The letters A/B and C/D are illustrative allele markers, not named human genes.",
            "A mule has 63 chromosomes (31 donkey + 32 horse). Unpaired chromosomes and structural mismatches interfere with normal synapsis. Try the hybrid challenge in Game options."
        ]
        case .metaphaseI: [
            "Homologous pairs align double-file at the cell equator. Each replicated homolog faces an opposite pole from its partner.",
            "In meiosis I, the sister kinetochores of one homolog connect toward the same pole. Its homolog connects toward the other pole. Sisters remain joined.",
            "Each pair's maternal/paternal orientation is independent of the other pairs. This random alignment creates chromosome combinations.",
            "For humans, 2²³ = 8,388,608 chromosome combinations per gamete from independent assortment alone. Crossing over adds further diversity. Two illustrated pairs give 2² = 4 orientations."
        ]
        case .anaphaseI: [
            "Spindle microtubules shorten and pull homologous chromosomes to opposite poles.",
            "Sister chromatids remain attached at their centromeres. They do not separate in anaphase I.",
            "Each future daughter cell receives one replicated homolog from every pair. This is the reduction division: 2n → n."
        ]
        case .telophaseI: [
            "The separated homologs gather at opposite poles. This game shows temporary nuclear envelopes forming and chromosomes loosening before the next division; these features can vary between organisms.",
            "Cytokinesis divides the cytoplasm into two haploid cells. Each contains one set of replicated chromosomes, not homologous pairs.",
            "In humans, each daughter cell has n = 23 chromosomes, each still made of two sister chromatids. In this model, each has n = 2."
        ]
        case .interkinesis: [
            "Interkinesis is the interval between meiosis I and meiosis II. This game shows briefly loosened chromatin while division proteins are produced.",
            "There is no S phase and no DNA replication between the two meiotic divisions. Copying DNA here earns a penalty and is blocked.",
            "The two cells remain haploid; their chromosomes still have two sister chromatids."
        ]
        case .prophaseII: [
            "Chromosomes re-condense in both haploid cells. Spindle apparatuses form and the nuclear envelopes shown in this model break down.",
            "No additional DNA is copied. Each chromosome still consists of two sister chromatids; crossing over can have made those chromatids genetically different."
        ]
        case .metaphaseII: [
            "Chromosomes align single-file along the equator of each haploid cell.",
            "The kinetochores of sister chromatids connect to spindle fibers from opposite poles. In this scene those poles are at the top and bottom of each cell.",
            "The first division separated homologs; this division prepares to separate sister chromatids."
        ]
        case .anaphaseII: [
            "Cohesion holding sister chromatids together at their centromeres is released. The DNA at the centromere is not cut out.",
            "Spindle microtubules shorten and separate sister chromatids toward opposite poles of each cell.",
            "Each separated chromatid is now an individual, unreplicated chromosome. Both cells divide their chromosome copies."
        ]
        case .telophaseII: [
            "Four nuclear envelopes form around the isolated chromosome sets. Chromosomes de-condense into extended chromatin.",
            "Cytokinesis divides both cells, producing four genetically nonidentical haploid products in this model.",
            "Each illustrated product has n = 2; human gametes have n = 23. The equal divisions here model gamete formation generally; the oogenesis mode shows unequal cytoplasmic packaging."
        ]
        case .complete: [
            "One diploid precursor has undergone two divisions to form four haploid products. DNA was copied once, before meiosis I.",
            "Crossing over and independent assortment create genetic diversity. In this model, the four displayed allele combinations are distinct.",
            "Open Diversity & packaging for random fertilization, spermatogenesis, oogenesis, and plant alternation of generations.",
            "Open Division error lab for nondisjunction, aneuploidy, polyploidy, structural changes, and the hybrid pairing challenge."
        ]
        }
    }

    mutating func send(_ action: Action) {
        needsCorrection = false
        switch action {
        case .replicateDNA:
            guard stage == .interphase else { return }
            replicated = true; respond("DNA doubled. Chromosome count unchanged.")
        case .prepareDivision:
            guard stage == .interphase, replicated else { return }
            divisionPrepared = true; respond("Proteins ready. Centrosomes duplicated.")
        case .condenseI(let id):
            guard stage == .prophaseI, Self.chromosomeIDs.contains(id) else { return }
            condensedI.insert(id); respond("Same DNA. Smaller suitcase.")
        case .openEnvelopeI:
            guard stage == .prophaseI, condensedI.count == 4 else { return }
            envelopeOpenI = true; respond("Envelope open. Find each homolog's match.")
        case .synapse(let pair, let matched):
            guard stage == .prophaseI, envelopeOpenI, Self.pairIDs.contains(pair) else { return }
            guard matched else { correct("Match size, centromere position and gene positions."); return }
            synapsed.insert(pair); respond("Gene by gene. Homologs paired.")
        case .crossOver(let pair, let matched):
            guard stage == .prophaseI, synapsed.contains(pair), Self.pairIDs.contains(pair) else { return }
            guard matched else { correct("Exchange matching segments between non-sister chromatids."); return }
            crossed.insert(pair); respond("A reciprocal swap. New allele combinations!")
        case .flipPair(let pair):
            guard stage == .metaphaseI, Self.pairIDs.contains(pair) else { return }
            maternalLeft[pair].toggle()
            for id in [pair * 2, pair * 2 + 1] { leftAttachments.remove(id); rightAttachments.remove(id) }
            checkpointI = false; respond("Pair flipped. Reconnect its homologs to their new poles.")
        case .choosePole(let pole):
            guard (stage == .metaphaseI && [.left, .right].contains(pole)) ||
                    (stage == .metaphaseII && [.top, .bottom].contains(pole)) else { return }
            selectedPole = pole
        case .attachI(let id):
            guard stage == .metaphaseI, Self.chromosomeIDs.contains(id) else { return }
            guard selectedPole == poleForHomolog(id) else {
                correct("This homolog faces the other pole. Its sisters must travel together."); return
            }
            if selectedPole == .left { leftAttachments.insert(id) } else { rightAttachments.insert(id) }
            respond("Both sister kinetochores face the same pole.")
        case .alignI(let pair, let near):
            guard stage == .metaphaseI, attachmentsIComplete, Self.pairIDs.contains(pair) else { return }
            guard near else { correct("Aim for the vertical equator—or tap to align."); return }
            alignedI.insert(pair)
        case .inspectI:
            guard stage == .metaphaseI else { return }
            guard attachmentsIComplete, alignedI.count == 2 else { correct("Connect and align both pairs first."); return }
            checkpointI = true
        case .protectCentromeres:
            guard stage == .anaphaseI else { return }
            centromeresProtected = true
        case .separateHomologs:
            guard stage == .anaphaseI, centromeresProtected, checkpointI else { return }
            separatedI = true; respond("Homologs apart. Sisters still joined.")
        case .rebuildI(let cell):
            guard stage == .telophaseI, separatedI, (0..<2).contains(cell) else { return }
            nucleiI.insert(cell)
        case .divideI:
            guard stage == .telophaseI, nucleiI.count == 2 else { return }
            dividedI = true
        case .blockReplication:
            guard stage == .interkinesis else { return }
            replicationBlocked = true
        case .makeInterkinesisProteins:
            guard stage == .interkinesis, replicationBlocked else { return }
            interkinesisProteins = true
        case .attemptExtraReplication:
            guard stage == .interkinesis else { return }
            correct("No S phase here. DNA must not be copied between meiosis I and II.")
        case .condenseII(let key):
            guard stage == .prophaseII, Self.chromosomeIDs.contains(key) else { return }
            condensedII.insert(key)
        case .openEnvelopeII(let cell):
            guard stage == .prophaseII, condensedII.count == 4, (0..<2).contains(cell) else { return }
            envelopesOpenII.insert(cell)
        case .attachII(let key):
            guard stage == .metaphaseII, Self.chromosomeIDs.contains(key) else { return }
            if selectedPole == .top { topAttachments.insert(key) }
            else if selectedPole == .bottom { bottomAttachments.insert(key) }
        case .alignII(let key, let near):
            guard stage == .metaphaseII, attachmentsIIComplete, Self.chromosomeIDs.contains(key) else { return }
            guard near else { correct("Aim for this cell's horizontal equator—or tap to align."); return }
            alignedII.insert(key)
        case .inspectII:
            guard stage == .metaphaseII else { return }
            guard attachmentsIIComplete, alignedII.count == 4 else { correct("Connect and align every chromosome in both cells."); return }
            checkpointII = true
        case .splitCentromeres:
            guard stage == .anaphaseII, checkpointII else { return }
            centromeresSplit = true
        case .separateSisters:
            guard stage == .anaphaseII, centromeresSplit, checkpointII else { return }
            separatedII = true
        case .rebuildII(let product):
            guard stage == .telophaseII, separatedII, (0..<4).contains(product) else { return }
            nucleiII.insert(product)
        case .relaxChromosomes:
            guard stage == .telophaseII, nucleiII.count == 4 else { return }
            relaxedII = true
        case .divideII:
            guard stage == .telophaseII, nucleiII.count == 4, relaxedII else { return }
            dividedII = true
        case .advance:
            guard canAdvance, let next = Stage(rawValue: stage.rawValue + 1) else { return }
            stage = next
            if next == .metaphaseII { selectedPole = .top }
            respond(instruction)
        case .restart: self = Self()
        }
    }
    private mutating func respond(_ text: String) { feedback = text }
    private mutating func correct(_ text: String) {
        penalties += 1; feedback = text; needsCorrection = true
    }
}

extension MeiosisSession.Stage {
    nonisolated var takeaway: String {
        switch self {
        case .interphase: "DNA doubles. Chromosome count does not."
        case .prophaseI: "Non-sister chromatids swap corresponding segments."
        case .metaphaseI: "Pairs double-file. Each pair chooses its own orientation."
        case .anaphaseI: "Homologs separate. Sisters stay together."
        case .telophaseI: "Two haploid cells. Chromosomes are still replicated."
        case .interkinesis: "No DNA replication between the two divisions."
        case .prophaseII: "Two cells prepare to separate their chromosome copies."
        case .metaphaseII: "Single-file. Sister kinetochores face opposite poles."
        case .anaphaseII: "Sisters separate. Each is now a chromosome."
        case .telophaseII: "Four haploid products. One DNA replication, two divisions."
        case .complete: "Crossing over + independent assortment = diversity."
        }
    }
}
