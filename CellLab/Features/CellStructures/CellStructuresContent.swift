// CellStructuresContent.swift — Animal cell structures. CellLab.
import Foundation

enum CSCellKind: String, CaseIterable, Identifiable, Hashable, Sendable {
    case animal
    var id: String { rawValue }
    var title: String { "Animal" }
    var specimen: String { "ANIMAL CELL" }
}
enum CSPart: String, CaseIterable, Identifiable, Hashable, Sendable {
    case membrane, cytoplasm, nucleus, nucleolus, ribosomes, roughER, smoothER, golgi, vesicles, lysosomes, peroxisomes, mitochondria, cytoskeleton, microfilaments, intermediateFilaments, microtubules, centrosome, cilia, flagellum
    var id: String { rawValue }
    var content: CSPartContent { CSPartContent.all[self]! }
    func isAvailable(in kind: CSCellKind) -> Bool { true }
}
struct CSPartContent: Sendable {
    let title: String
    let nickname: String
    let group: String
    let hex: UInt32
    let summary: String
    let action: String
    let details: [String]
    let related: [CSPart]
    static let all: [CSPart: CSPartContent] = [
        .membrane: .init(
            title: "Plasma membrane",
            nickname: "A selective front door",
            group: "Boundaries",
            hex: 0xD0E5C2,
            summary: "Controls what enters and leaves, receives signals, and separates the cell from its surroundings.",
            action: "O₂ crosses the bilayer; an ion moves through a transport protein.",
            details: [
                "Phospholipids form two layers: water-loving heads face water; water-fearing fatty-acid tails face inward.",
                "Small nonpolar molecules such as O₂ and CO₂ pass through the bilayer. Ions and many polar molecules, including glucose, need transport proteins.",
                "Proteins drift within this fluid mosaic, anchor the cell, and receive signals. Cholesterol helps regulate animal membrane fluidity."
            ],
            related: [.cytoplasm, .vesicles]),
        .cytoplasm: .init(
            title: "Cytoplasm & cytosol",
            nickname: "The inside story",
            group: "Boundaries",
            hex: 0xC8E7EF,
            summary: "Cytoplasm is the cell’s interior outside the nucleus. Cytosol is its watery fluid, where many reactions happen.",
            action: "Dissolved molecules move through the cytosol around organelles.",
            details: [
                "Cytoplasm includes cytosol, organelles, and other structures between the plasma membrane and nucleus.",
                "Cytosol is the watery fluid surrounding the organelles; the nucleus is not part of the cytoplasm.",
                "Cytosol contains water, ions, enzymes, RNA, and nutrients. It supports chemical reactions and movement within cells."
            ],
            related: [.membrane, .cytoskeleton]),
        .nucleus: .init(
            title: "Nucleus",
            nickname: "Recipes live here",
            group: "Genetic control",
            hex: 0xDECCE9,
            summary: "Stores most of the cell’s DNA. DNA instructions are transcribed into mRNA for protein production.",
            action: "An mRNA copy travels from DNA through a nuclear pore.",
            details: [
                "A double-membrane nuclear envelope surrounds the nucleus. Protein-lined nuclear pores regulate traffic.",
                "DNA remains in the nucleus while an mRNA copy can leave for translation.",
                "The nucleus contains chromatin and a dense nucleolus. Mitochondria also contain their own DNA."
            ],
            related: [.nucleolus, .ribosomes, .roughER]),
        .nucleolus: .init(
            title: "Nucleolus",
            nickname: "Ribosome assembly station",
            group: "Genetic control",
            hex: 0xDECCE9,
            summary: "Makes ribosomal RNA and assembles it with proteins into ribosomal subunits.",
            action: "Two ribosomal subunits assemble and leave through a nuclear pore.",
            details: [
                "This dense region sits inside the nucleus and has no surrounding membrane.",
                "Ribosomal RNA (rRNA) joins with imported proteins to form large and small subunits.",
                "The subunits leave through nuclear pores and later join on mRNA in the cytoplasm."
            ],
            related: [.nucleus, .ribosomes]),
        .ribosomes: .init(
            title: "Ribosomes",
            nickname: "Tiny protein builders",
            group: "Build & deliver",
            hex: 0xF7E49C,
            summary: "Read mRNA and join amino acids into proteins. Ribosomes can be free in cytosol or bound to rough ER.",
            action: "A ribosome reads mRNA while an amino-acid chain grows.",
            details: [
                "Each ribosome has two subunits made of rRNA and proteins, without a surrounding membrane.",
                "Free ribosomes make proteins for the cytosol and many internal organelles.",
                "ER-bound ribosomes make proteins entering the secretory pathway, including exported, membrane, and lysosomal proteins."
            ],
            related: [.roughER, .nucleolus]),
        .roughER: .init(
            title: "Rough ER",
            nickname: "Build, fold, send",
            group: "Build & deliver",
            hex: 0xC8E7EF,
            summary: "Its attached ribosomes make proteins that enter the ER to fold and begin processing.",
            action: "A new protein enters the ER, folds, and leaves in a vesicle.",
            details: [
                "Flattened membrane sacs and tubes connect with the nuclear envelope. Ribosomes give the cytoplasmic surface its rough appearance.",
                "Proteins enter the ER as they are made; many fold and receive initial modifications there.",
                "Cargo for secretion, membranes, and parts of the endomembrane system leaves for the Golgi in transport vesicles."
            ],
            related: [.ribosomes, .vesicles, .golgi]),
        .smoothER: .init(
            title: "Smooth ER",
            nickname: "Lipids, calcium & cleanup",
            group: "Build & deliver",
            hex: 0xF3C9B5,
            summary: "Makes lipids, helps detoxify chemicals, and stores calcium ions.",
            action: "Lipids form along smooth tubules; stored Ca²⁺ is released.",
            details: [
                "A branching membrane-tube network connects to the rough ER but lacks attached ribosomes.",
                "Its roles include making membrane lipids and detoxifying drugs and poisons, especially in certain cell types.",
                "In muscle, specialized smooth ER stores and releases Ca²⁺ to help trigger contraction."
            ],
            related: [.roughER, .membrane]),
        .golgi: .init(
            title: "Golgi apparatus",
            nickname: "The cellular sorting office",
            group: "Build & deliver",
            hex: 0xF3C9B5,
            summary: "Modifies, labels, and sorts proteins and lipids, then packages them for delivery.",
            action: "Cargo arrives from the ER, gains a tag, and leaves in a vesicle.",
            details: [
                "The Golgi is a stack of flattened membrane sacs. Its receiving (cis) face accepts ER cargo; its shipping (trans) face sends cargo onward.",
                "It modifies proteins and lipids, often adding sugar groups. A protein with attached carbohydrates is a glycoprotein.",
                "Outgoing vesicles deliver cargo to the plasma membrane, outside the cell, or to destinations such as lysosomes. Most initial protein folding happens in the ER."
            ],
            related: [.roughER, .vesicles, .lysosomes]),
        .vesicles: .init(
            title: "Transport vesicles",
            nickname: "Bubble-wrapped deliveries",
            group: "Build & deliver",
            hex: 0xC8E7EF,
            summary: "Small membrane bubbles carry proteins, lipids, and other cargo between destinations.",
            action: "A vesicle carries cargo from ER to Golgi, then toward the membrane.",
            details: [
                "Vesicles pinch off from a donor membrane, carry cargo, and fuse with an appropriate target membrane.",
                "They connect the ER, Golgi, lysosomes, and plasma membrane in the endomembrane system.",
                "During exocytosis, a vesicle fuses with the plasma membrane and releases cargo outside."
            ],
            related: [.roughER, .golgi, .membrane]),
        .lysosomes: .init(
            title: "Lysosomes",
            nickname: "Break it down. Use it again.",
            group: "Recycle & store",
            hex: 0xDECCE9,
            summary: "Acidic enzyme-filled sacs digest debris, captured microbes, and worn-out cell parts for reuse.",
            action: "A large cargo piece breaks into smaller reusable building blocks.",
            details: [
                "A single membrane encloses digestive enzymes in an acidic interior, around pH 4.8.",
                "Hydrolysis breaks large molecules into reusable monomers.",
                "They digest captured microbes, damaged organelles, and other debris so the cell can reuse their building blocks."
            ],
            related: [.vesicles, .peroxisomes]),
        .peroxisomes: .init(
            title: "Peroxisomes",
            nickname: "Careful chemical cleanup",
            group: "Recycle & store",
            hex: 0xD0E5C2,
            summary: "Break down fatty acids and help detoxify chemicals. Enzymes safely remove hydrogen peroxide.",
            action: "Catalase converts hydrogen peroxide into water and oxygen.",
            details: [
                "A single membrane surrounds concentrated enzymes; some peroxisomes show a dense crystalline enzyme core.",
                "Fatty-acid breakdown and other reactions can generate hydrogen peroxide (H₂O₂). Catalase converts it into H₂O and O₂.",
                "Peroxisomes also contribute to lipid synthesis; exact jobs vary with cell type. They are distinct from lysosomes."
            ],
            related: [.lysosomes, .mitochondria]),
        .mitochondria: .init(
            title: "Mitochondria",
            nickname: "Fuel in. ATP out.",
            group: "Energy",
            hex: 0xF3C9B5,
            summary: "Use energy from food during cellular respiration to make ATP that powers cell work.",
            action: "ATP appears near the folded inner membrane during respiration.",
            details: [
                "Two membranes enclose each mitochondrion. The inner one folds into cristae, increasing surface area for energy conversion.",
                "The matrix is the inner fluid space and contains mitochondrial DNA and ribosomes.",
                "ATP production depends on coordinated reactions, many at the inner membrane."
            ],
            related: [.cytoplasm]),
        .cytoskeleton: .init(
            title: "Cytoskeleton",
            nickname: "Support with a transport network",
            group: "Support & motion",
            hex: 0xD0E5C2,
            summary: "A protein-fiber network supports cell shape, anchors organelles, and helps move cargo and chromosomes.",
            action: "A motor protein moves a vesicle along a cytoskeletal track.",
            details: [
                "Three major classes are actin microfilaments, intermediate filaments, and tubulin microtubules. Their abundance varies by cell type.",
                "Fibers support shape, position organelles, and provide tracks for motor proteins.",
                "The network also helps separate chromosomes in division. Actin and myosin work together in contraction."
            ],
            related: [.microfilaments, .intermediateFilaments, .microtubules]),
        .microfilaments: .init(
            title: "Microfilaments",
            nickname: "Actin in action",
            group: "Support & motion",
            hex: 0xF3C9B5,
            summary: "Thin actin fibers support the cell cortex and work with myosin to produce movement and contraction.",
            action: "Myosin slides actin fibers, shortening a contractile arrangement.",
            details: [
                "About 7 nm wide, each filament consists of two twisted chains of actin subunits.",
                "Actin helps shape the cell surface and supports movement.",
                "Actin and myosin form the contractile ring that pinches an animal cell during cytokinesis."
            ],
            related: [.cytoskeleton, .microtubules]),
        .intermediateFilaments: .init(
            title: "Intermediate filaments",
            nickname: "Ropes that resist a stretch",
            group: "Support & motion",
            hex: 0xDECCE9,
            summary: "Tough, rope-like fibers give mechanical strength and help anchor cell structures.",
            action: "A braided fiber remains connected as outward forces pull on it.",
            details: [
                "About 10 nm wide, these fibers are built from different proteins, depending on cell type.",
                "They help resist pulling forces and stabilize organelles and cell architecture.",
                "Nuclear lamins form a supporting mesh beneath the nuclear envelope. Cytoplasmic intermediate filaments are especially characteristic of animal cells."
            ],
            related: [.cytoskeleton, .nucleus]),
        .microtubules: .init(
            title: "Microtubules",
            nickname: "Hollow tracks. Heavy lifting.",
            group: "Support & motion",
            hex: 0xC8E7EF,
            summary: "Tubulin tubes guide motor-driven transport, form the spindle, and support eukaryotic cilia and flagella.",
            action: "A motor protein walks a vesicle along a microtubule.",
            details: [
                "About 25 nm across, microtubules are hollow tubes assembled from tubulin subunits.",
                "Motor proteins use them as tracks to move organelles and vesicles.",
                "They form the mitotic spindle and the internal framework of eukaryotic cilia and flagella."
            ],
            related: [.centrosome, .cilia, .flagellum]),
        .centrosome: .init(
            title: "Centrosome & centrioles",
            nickname: "The microtubule organizer",
            group: "Support & motion",
            hex: 0xF7E49C,
            summary: "An animal-cell organizing center that helps assemble microtubules, including the mitotic spindle.",
            action: "Microtubules grow outward from material around a centriole pair.",
            details: [
                "Near the nucleus, a typical centrosome contains two barrel-shaped centrioles oriented roughly at right angles.",
                "Surrounding pericentriolar material organizes microtubules; centrioles are not the spindle fibers themselves.",
                "Centrioles can become basal bodies that anchor cilia or flagella."
            ],
            related: [.microtubules, .cilia, .flagellum]),
        .cilia: .init(
            title: "Cilia",
            nickname: "A coordinated surface sweep",
            group: "Support & motion",
            hex: 0xC8E7EF,
            summary: "Short projections can beat together to move a cell or sweep material across its surface.",
            action: "Coordinated ciliary bends sweep particles across a surface.",
            details: [
                "Motile eukaryotic cilia usually contain a 9 + 2 microtubule array: nine outer doublets and a central pair.",
                "Dynein-powered microtubule sliding produces bending. Basal bodies anchor cilia.",
                "Not all animal cells have cilia. Many primary cilia mainly sense signals and usually have a 9 + 0 arrangement."
            ],
            related: [.microtubules, .centrosome, .flagellum]),
        .flagellum: .init(
            title: "Flagellum",
            nickname: "A long-distance mover",
            group: "Support & motion",
            hex: 0xC8E7EF,
            summary: "A long projection that bends to propel certain animal cells, such as sperm.",
            action: "Dynein-driven microtubule sliding bends the tail to move the cell.",
            details: [
                "A eukaryotic flagellum usually has a 9 + 2 microtubule framework: nine outer doublets and one central pair.",
                "Dynein motors cause neighboring microtubules to slide; links between them turn this sliding into bending.",
                "A basal body anchors the flagellum. This is a specialized feature, not a structure found on every animal cell."
            ],
            related: [.cilia, .microtubules]),
    ]
}
