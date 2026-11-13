// DNAReplicationContent.swift — CellLab
// Teaching copy follows the supplied outline. No external biology references are required.
import Foundation

struct DNAReplicationStepContent: Sendable {
    let slug: String
    let title: String
    let shortTitle: String
    let focus: String
    let mnemonic: String
    let asset: String?
    let duration: Double
    let bullets: [String]
    let callout: String
    let playerID: String
    let accessibility: String
}

enum DNAReplicationStep: Int, CaseIterable, Identifiable, Hashable, Sendable {
    case origins, unzip, stabilize, prime, build, proofread, replace, seal, result
    var id: Int { rawValue }
    static let carouselCases: [Self] = [.prime, .build, .proofread, .replace, .seal, .result]
    var next: Self? {
        guard let index = Self.carouselCases.firstIndex(of: self), index + 1 < Self.carouselCases.count else { return nil }
        return Self.carouselCases[index + 1]
    }
    var previous: Self? {
        guard let index = Self.carouselCases.firstIndex(of: self), index > 0 else { return nil }
        return Self.carouselCases[index - 1]
    }
    var content: DNAReplicationStepContent {
        switch self {
        case .origins:
            return DNAReplicationStepContent(
                slug: "origins", title: "Origins of replication", shortTitle: "Origins",
                focus: "Origins of replication", mnemonic: "Where copying begins", asset: nil, duration: 5,
                bullets: ["DNA is copied during **S phase of interphase**, before cell division.", "The **genome** is all the cell’s genetic material. An unreplicated **chromosome** contains one continuous DNA molecule plus associated proteins.", "Many **origins of replication** let copying begin at several places along a chromosome."],
                callout: "Many starts. One complete genome copy.", playerID: "genome",
                accessibility: "A closed DNA ladder has several highlighted starting locations along it. These mark origins of replication on one DNA molecule."
            )
        case .unzip:
            return DNAReplicationStepContent(
                slug: "unzip", title: "Helicase", shortTitle: "Unzip",
                focus: "Helicase", mnemonic: "Unzip the DNA", asset: "DNAHelicaseZipper", duration: 6,
                bullets: ["**Helicase** unwinds DNA by breaking **hydrogen bonds** between complementary bases.", "The separated strands provide templates for copying."],
                callout: "Open the base pairs; keep the backbones intact.", playerID: "helicase",
                accessibility: "Helicase moves at a replication fork and separates paired bases. The original sugar-phosphate backbones remain intact."
            )
        case .stabilize:
            return DNAReplicationStepContent(
                slug: "stabilize", title: "Binding proteins", shortTitle: "Hold",
                focus: "Binding proteins", mnemonic: "Keep the strands apart", asset: nil, duration: 4,
                bullets: ["**Binding proteins** attach to the separated DNA strands.", "They keep the strands stable and prevent them from rejoining."],
                callout: "Stable templates, ready to copy.", playerID: "binding",
                accessibility: "Binding proteins attach along both separated original DNA strands, keeping them stable before copying."
            )
        case .prime:
            return DNAReplicationStepContent(
                slug: "prime", title: "RNA primer", shortTitle: "Prime",
                focus: "Primase", mnemonic: "Start here", asset: "DNAPrimaseStarter", duration: 5,
                bullets: ["**Before priming:** copying begins at **origins**. **Helicase** unzips DNA; **binding proteins** keep the strands apart.", "**Primase** makes a short **RNA primer**, providing an exposed **3′ end** for DNA polymerase.", "**DNA polymerase** cannot start from scratch. Each **Okazaki fragment** needs its own primer."],
                callout: "A temporary RNA start for a new DNA strand.", playerID: "primase",
                accessibility: "The DNA templates are already separated. Primase lays gold RNA primers on them. The leading primer has its 3 prime end facing the fork; each lagging primer faces away from it."
            )
        case .build:
            return DNAReplicationStepContent(
                slug: "build", title: "DNA polymerase", shortTitle: "Build",
                focus: "DNA polymerase", mnemonic: "Build the copy", asset: "DNAPolymeraseBuilder", duration: 8,
                bullets: ["**DNA polymerase** adds complementary **DNA nucleotides** only to the growing **3′ end**: new DNA grows **5′ → 3′**.", "The **leading strand** grows continuously toward the fork. The **lagging strand** grows away in **Okazaki fragments**, each with a primer.", "**Adenine pairs with thymine (A–T)**; **cytosine pairs with guanine (C–G)**."],
                callout: "Both grow 5′ → 3′. Their paths differ.", playerID: "polymerase",
                accessibility: "Polymerase adds complementary DNA bases at the 3 prime ends. Leading DNA grows toward the fork. Lagging DNA is made in short fragments away from the fork. Both grow 5 prime to 3 prime."
            )
        case .proofread:
            return DNAReplicationStepContent(
                slug: "proofread", title: "Proofreading", shortTitle: "Check",
                focus: "DNA polymerase", mnemonic: "Check as you go", asset: "DNAPolymeraseBuilder", duration: 6,
                bullets: ["During synthesis, **DNA polymerase proofreads** its work, removing a mismatched nucleotide from the growing end and adding the correct one.", "With proofreading and additional repair, the final error rate can be about **one mistake per billion nucleotides**."],
                callout: "Check the growing tip, one base at a time.", playerID: "accuracy",
                accessibility: "An enlarged growing end has a mismatched G opposite A. The mismatch is removed and correct T is inserted. The correction occurs at the growing end during synthesis."
            )
        case .replace:
            return DNAReplicationStepContent(
                slug: "replace", title: "Primer replacement", shortTitle: "Replace",
                focus: "Repair enzymes + DNA polymerase", mnemonic: "Swap RNA for DNA", asset: "DNAPolymeraseBuilder", duration: 7,
                bullets: ["**Repair enzymes** remove temporary **RNA primers** from the newly made strands.", "**DNA polymerase** extends an existing **3′ end**, filling the space with DNA. A **nick** remains between adjacent backbone segments."],
                callout: "Fill the bases first. A nick still needs sealing.", playerID: "ligation",
                accessibility: "At an internal fragment junction, the gold RNA primer is removed. DNA polymerase fills the space with DNA by extending an existing 3 prime end. A backbone nick remains."
            )
        case .seal:
            return DNAReplicationStepContent(
                slug: "seal", title: "DNA ligase", shortTitle: "Seal",
                focus: "DNA ligase", mnemonic: "Seal the backbone", asset: "DNALigaseGlue", duration: 5,
                bullets: ["**DNA ligase** seals remaining **nicks** by forming **covalent bonds** in the **sugar-phosphate backbone**.", "This connects neighboring **Okazaki fragments** into one continuous strand after primer replacement."],
                callout: "Seal a backbone nick, not the space between base pairs.", playerID: "ligation",
                accessibility: "The DNA bases are already present. A glue-bottle memory cue moves to one nick in the new strand's sugar-phosphate backbone. The nick is sealed into a continuous covalent backbone; opposite strands are not glued together."
            )
        case .result:
            return DNAReplicationStepContent(
                slug: "result", title: "Semiconservative", shortTitle: "Result",
                focus: "Semiconservative replication", mnemonic: "One old + one new", asset: nil, duration: 6,
                bullets: ["One DNA molecule produces **two matching double-stranded DNA molecules**.", "Each contains **one parental strand** and **one new complementary strand**: **semiconservative replication**.", "An error that escapes repair can become a **mutation**, a permanent change in DNA sequence."],
                callout: "Two molecules. One original strand in each.", playerID: "result",
                accessibility: "The two original parental strands separate to different daughter DNA molecules. One new complementary strand pairs with each. Both products contain one blue parental strand and one pink new strand, and all paired strands are antiparallel."
            )
        }
    }
}

struct DNAReplicationPlayer: Identifiable, Sendable {
    let id: String
    let title: String
    let tint: DNAReplicationTint
    let asset: String?
    let scene: DNAReplicationStep
    let caption: String
    let bullets: [String]
    static let all: [Self] = [
        DNAReplicationPlayer(
            id: "primase", title: "RNA primer\n& primase", tint: .butter, asset: "DNAPrimaseStarter", scene: .prime,
            caption: "A starting point for DNA polymerase", bullets: ["**Primase** makes a short **RNA primer** on the exposed DNA template.", "The primer provides an exposed **3′ end**. DNA polymerase needs this start and cannot begin a strand from scratch.", "Each **Okazaki fragment** begins with a primer. The temporary RNA is later replaced with DNA."]
        ),
        DNAReplicationPlayer(
            id: "polymerase", title: "DNA polymerase", tint: .blue, asset: "DNAPolymeraseBuilder", scene: .build,
            caption: "Add to 3′ · Build 5′ → 3′ · Proofread", bullets: ["**DNA polymerase** adds complementary DNA nucleotides to an existing **3′ end**, never to the growing strand’s 5′ end.", "New DNA grows only **5′ → 3′**, using the original strand as a **template**.", "The builder also **proofreads**, removing mismatches and adding the correct bases."]
        ),
        DNAReplicationPlayer(
            id: "helicase", title: "Helicase", tint: .peach, asset: "DNAHelicaseZipper", scene: .unzip,
            caption: "Unzip the paired bases", bullets: ["**Helicase** unwinds the DNA double helix.", "It breaks **hydrogen bonds** between complementary bases, separating the strands for copying."]
        ),
        DNAReplicationPlayer(
            id: "ligation", title: "Primer replacement\n& DNA ligase", tint: .peach, asset: "DNALigaseGlue", scene: .seal,
            caption: "Replace the RNA. Then seal the nick.", bullets: ["**Repair enzymes** remove RNA primers; **DNA polymerase** fills the spaces with DNA by extending a 3′ end.", "A **nick** is a break in the backbone with no nucleotide missing at that junction.", "**Ligase** forms the missing **covalent sugar-phosphate bond**, joining adjacent fragments. Glue is the memory cue."]
        ),
        DNAReplicationPlayer(
            id: "binding", title: "Binding proteins", tint: .lavender, asset: nil, scene: .stabilize,
            caption: "Keep the separated strands stable", bullets: ["**Binding proteins** attach to separated single strands of DNA.", "They stabilize the strands and prevent them from rejoining."]
        ),
        DNAReplicationPlayer(
            id: "strands", title: "Leading, lagging\n& Okazaki fragments", tint: .sage, asset: nil, scene: .build,
            caption: "Same synthesis direction. Different routes.", bullets: ["The **leading strand** grows continuously toward the moving replication fork.", "The **lagging strand** grows away from the fork in short **Okazaki fragments**; each begins with an RNA primer.", "Both are built **5′ → 3′**. Priming repeats on the lagging strand as more template is exposed."]
        ),
        DNAReplicationPlayer(
            id: "direction", title: "DNA direction\n& base pairing", tint: .blue, asset: nil, scene: .proofread,
            caption: "Complementary bases · Opposite strand directions", bullets: ["**DNA polymerase** adds to the growing **3′ end**. New DNA is made only **5′ → 3′**.", "**Adenine (A)** pairs with **thymine (T)**; **cytosine (C)** pairs with **guanine (G)**.", "**Hydrogen bonds** hold paired bases together; **covalent bonds** join the **sugar-phosphate backbone**."]
        ),
        DNAReplicationPlayer(
            id: "accuracy", title: "Energy & accuracy", tint: .lavender, asset: "DNAPolymeraseBuilder", scene: .proofread,
            caption: "Energy to build · Proofreading to check", bullets: ["DNA construction requires an energy input (**endergonic**). **ATP** powers enzyme activity, including helicase and ligase.", "**DNA polymerase** proofreads as it builds, removing mismatches and adding the correct bases.", "With proofreading and additional repair, the final error rate can be about **one mistake per billion nucleotides**."]
        ),
        DNAReplicationPlayer(
            id: "result", title: "Semiconservative\nreplication & mutations", tint: .sage, asset: nil, scene: .result,
            caption: "One parental strand + one new strand", bullets: ["Each completed DNA molecule keeps **one original parental strand** and gains **one new complementary strand**: **semiconservative** replication.", "A **mutation** is a permanent DNA sequence change. Copying errors that escape repair can become mutations.", "More frequent **cell divisions** create more opportunities for replication errors, as in rapidly dividing skin cells or bacteria; genes are copied as part of the genome."]
        ),
        DNAReplicationPlayer(
            id: "genome", title: "Genome, chromosomes\n& origins", tint: .sage, asset: nil, scene: .origins,
            caption: "The genetic material and its starting points", bullets: ["The **genome** is the cell’s complete genetic material. An unreplicated **chromosome** contains a continuous DNA molecule plus associated proteins.", "Replication occurs during **S phase of interphase**, before cell division.", "Many **origins of replication** allow parallel copying. The supplied human-cell example copies billions of nucleotides in about **8–10 hours**."]
        ),
    ]
}
