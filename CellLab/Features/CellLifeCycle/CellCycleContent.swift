//
//  CellCycleContent.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/13/26.
//

// CellCycleContent.swift
// CellLab — self-contained content, condensed from the supplied outline only.
// No runtime JSON loading or existing catalog changes are required.

import Foundation

enum CellCycleTint: String {
    case sage, blue, lavender, butter, peach
}

struct CellCyclePhaseContent {
    let title: String
    let shortLabel: String
    let subtitle: String
    let group: String
    let tint: CellCycleTint
    let startDegrees: Double?
    let endDegrees: Double?
    let summary: String?
    let bullets: [String]
    let checkpoint: String?
}

enum CellCyclePhase: String, CaseIterable, Identifiable {
    case g1, s, g2, mitosis, cytokinesis, g0

    var id: String { rawValue }
    static let circularCases: [Self] = [.g1, .s, .g2, .mitosis, .cytokinesis]

    var content: CellCyclePhaseContent {
        switch self {
        case .g1:
            return CellCyclePhaseContent(
                title: "G₁ phase", shortLabel: "G₁",
                subtitle: "Active life between divisions.", group: "Interphase · Gap 1",
                tint: .sage, startDegrees: -145, endDegrees: -55,
                summary: nil,
                bullets: ["The cell **grows**, performs **metabolic functions**, and makes new **organelles** and **proteins**.", "**Chromatin** stays unwound so genes can be **transcribed** and DNA can be copied."],
                checkpoint: "G₁ checkpoint · Check DNA for damage."
            )
        case .s:
            return CellCyclePhaseContent(
                title: "S phase", shortLabel: "S",
                subtitle: "Make a matching DNA copy.", group: "Interphase · Synthesis",
                tint: .blue, startDegrees: -55, endDegrees: 35,
                summary: nil,
                bullets: ["**Enzymes** duplicate the cell’s **DNA**.", "Each chromosome changes from **one DNA molecule** to **two identical sister chromatids**, joined at a **centromere**.", "In animal cells, the **centrosome** duplicates, ready to organize the **mitotic spindle**."],
                checkpoint: "S checkpoints · Nucleotides available; no strand breaks."
            )
        case .g2:
            return CellCyclePhaseContent(
                title: "G₂ phase", shortLabel: "G₂",
                subtitle: "Get division-ready.", group: "Interphase · Gap 2",
                tint: .lavender, startDegrees: 35, endDegrees: 105,
                summary: nil,
                bullets: ["The cell keeps **growing**.", "It makes **spindle proteins** and **membrane components** needed for division."],
                checkpoint: "G₂ checkpoint · Complete DNA copies + spindle machinery."
            )
        case .mitosis:
            return CellCyclePhaseContent(
                title: "Mitosis", shortLabel: "MITOSIS",
                subtitle: "Divide the nucleus.", group: "Nuclear division",
                tint: .butter, startDegrees: 105, endDegrees: 175,
                summary: "Separate replicated chromosomes into **two identical nuclei**.",
                bullets: [],
                checkpoint: nil
            )
        case .cytokinesis:
            return CellCyclePhaseContent(
                title: "Cytokinesis", shortLabel: "CYTO",
                subtitle: "Split the cell.", group: "Cytoplasm division",
                tint: .peach, startDegrees: 175, endDegrees: 215,
                summary: "Divide **cytoplasm** and **organelles** into **two daughter cells**, each with a nucleus.",
                bullets: [],
                checkpoint: nil
            )
        case .g0:
            return CellCyclePhaseContent(
                title: "G₀ phase", shortLabel: "G₀",
                subtitle: "Working. Not dividing.", group: "Non-dividing (resting) state",
                tint: .lavender, startDegrees: nil, endDegrees: nil,
                summary: nil,
                bullets: ["The cell functions normally, without **DNA replication** or preparation for division.", "Some cells, such as **adult neurons**, remain in **G₀** permanently."],
                checkpoint: nil
            )
        }
    }

    var accessibilityName: String {
        switch self {
        case .g1: return "G 1 phase: cell growth"
        case .s: return "S phase: DNA replication"
        case .g2: return "G 2 phase: division preparation"
        case .mitosis: return "Mitosis: nuclear division"
        case .cytokinesis: return "Cytokinesis: cytoplasm division"
        case .g0: return "G 0: non-dividing state"
        }
    }
}

struct CellCycleStepContent {
    let title: String
    let bullets: [String]
    let checkpoint: String?
}

enum CellCycleMitosisStep: String, CaseIterable, Identifiable {
    case prophase, prometaphase, metaphase, anaphase, telophase
    var id: String { rawValue }

    var content: CellCycleStepContent {
        switch self {
        case .prophase:
            return CellCycleStepContent(
                title: "Prophase",
                bullets: ["**Chromatin** coils into compact, visible **replicated chromosomes**.", "The **nucleolus** disappears; **centrosomes** move toward opposite poles.", "The **mitotic spindle** begins assembling from **microtubules**."],
                checkpoint: nil
            )
        case .prometaphase:
            return CellCycleStepContent(
                title: "Prometaphase",
                bullets: ["The **nuclear envelope** and **endoplasmic reticulum** fragment.", "**Kinetochores** assemble on **centromeres**, attaching sister chromatids to spindle microtubules."],
                checkpoint: nil
            )
        case .metaphase:
            return CellCycleStepContent(
                title: "Metaphase",
                bullets: ["Spindle **microtubules** align replicated chromosomes single-file along the **equator (midline)**."],
                checkpoint: "M checkpoint · Secure attachments + aligned chromosomes."
            )
        case .anaphase:
            return CellCycleStepContent(
                title: "Anaphase",
                bullets: ["Sister chromatids separate at their **centromeres**; each is now an individual, **unreplicated chromosome**.", "**Kinetochore fibers** shorten, pulling chromosomes toward opposite poles.", "**Non-kinetochore microtubules** lengthen, stretching the cell."],
                checkpoint: nil
            )
        case .telophase:
            return CellCycleStepContent(
                title: "Telophase",
                bullets: ["**Chromosomes decondense** at opposite poles.", "**Nuclear envelopes** and **nucleoli** reform around each DNA set.", "The **mitotic spindle** disassembles."],
                checkpoint: nil
            )
        }
    }
}

enum CellCycleCellKind: String, CaseIterable, Identifiable {
    case animal, plant
    var id: String { rawValue }

    var content: CellCycleStepContent {
        switch self {
        case .animal:
            return CellCycleStepContent(
                title: "Animal cells",
                bullets: ["An **actin-and-myosin contractile ring** tightens beneath the cell membrane.", "A **cleavage furrow** pinches the cell in two, like a drawstring."],
                checkpoint: nil
            )
        case .plant:
            return CellCycleStepContent(
                title: "Plant cells",
                bullets: ["**Golgi vesicles** gather at the midline to build a **cell plate**.", "The plate develops into a rigid **cell wall** between the daughter cells."],
                checkpoint: nil
            )
        }
    }
}

enum CellCycleIllustration: String {
    case chromosome, spindle, g1Checkpoint, replicationCheckpoint
    case mCheckpoint, cyclins, animal, plant
}

struct CellCyclePlayer: Identifiable {
    let id: String
    let title: String
    let tint: CellCycleTint
    let artwork: String
    let illustration: CellCycleIllustration
    let caption: String
    let bullets: [String]

    static let all: [Self] = [
        CellCyclePlayer(
            id: "p53", title: "G₁ checkpoint\n& p53", tint: .peach,
            artwork: "CellCycleCell", illustration: .g1Checkpoint,
            caption: "DNA damage · Repair · Apoptosis",
            bullets: ["**Internal checkpoints** check that each stage is complete before the cell proceeds.", "The **G₁ checkpoint** inspects DNA for damage; **p53** promotes repair.", "If damage cannot be repaired, p53 can trigger **apoptosis**: programmed cell death.", "**p53** (encoded by the TP53 gene on chromosome 17) is a vital regulatory transcription factor and tumor suppressor protein often called the 'guardian of the genome'"]
        ),
        CellCyclePlayer(
            id: "replicationChecks", title: "S & G₂\ncheckpoints", tint: .lavender,
            artwork: "CellCycleCell", illustration: .replicationCheckpoint,
            caption: "DNA copying · Division preparation",
            bullets: ["**S phase checkpoints** monitor nucleotide availability and check for DNA strand breaks.", "The **G₂ checkpoint** verifies two complete, identical DNA sets.", "It also checks that **spindle-making machinery** is present before mitosis."]
        ),
        CellCyclePlayer(
            id: "kinetochores", title: "Kinetochores &\nthe M checkpoint", tint: .butter,
            artwork: "CellCycleSpindle", illustration: .mCheckpoint,
            caption: "Attach · Align · Separate",
            bullets: ["**Kinetochores** are protein complexes on centromeres that anchor sister chromatids to spindle microtubules.", "The **metaphase (M) checkpoint** checks that all kinetochores are securely attached and chromosomes are aligned.", "Only then can sister chromatids separate at their **centromeres**."]
        ),
        CellCyclePlayer(
            id: "cyclins", title: "Cyclins", tint: .lavender,
            artwork: "CellCycleCell", illustration: .cyclins,
            caption: "Rise · Fall · Progress",
            bullets: ["**Cyclins** are signaling proteins whose concentrations rise and fall.", "They help activate **transcription factors** that drive progress into subsequent cycle stages.", "**transcription factors** is a specialized protein that controls the rate at which genetic information is transcribed from DNA into messenger RNA (mRNA)"]
        ),
        CellCyclePlayer(
            id: "contractileRing", title: "The contractile\nring", tint: .sage,
            artwork: "CellCycleAnimalDivision", illustration: .animal,
            caption: "Actin + myosin · Cleavage furrow",
            bullets: ["In animal cells, **actin** and **myosin** form a contractile ring beneath the cell membrane.", "The ring tightens like a drawstring, forming a **cleavage furrow**.", "The cell pinches into **two distinct daughter cells**."]
        ),
        CellCyclePlayer(
            id: "cellPlate", title: "Golgi vesicles &\nthe cell plate", tint: .peach,
            artwork: "CellCyclePlantDivision", illustration: .plant,
            caption: "Cell plate → Cell wall",
            bullets: ["In plant cells, the **Golgi apparatus** sends vesicles to the cell midline.", "Vesicles assemble a **cell plate** between daughter cells.", "**Cellulose** and other **polysaccharides** form a rigid new **cell wall**."]
        ),
    ]
}
