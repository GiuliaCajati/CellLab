import Foundation

struct DNACopyTerm: Identifiable {
    let id: String
    let title: String
    let memory: String
    let body: String
    var tool: DNACopyTool? = nil
    static let all: [Self] = [
        .init(id: "timing", title: "S phase", memory: "Copy before division", body: "DNA replication occurs during the S (synthesis) phase of interphase, before the cell divides. The game takes place in the nucleus."),
        .init(id: "genome", title: "Genome & chromosome", memory: "The library and its DNA molecules", body: "The genome is a cell’s complete set of genetic material. Before copying, a chromosome contains a continuous DNA molecule with associated proteins. This game uses a short DNA section."),
        .init(id: "origin", title: "Origins of replication", memory: "Many starting lines", body: "Replication begins at specific DNA locations. Hundreds of origins help a human cell copy billions of nucleotides in about 8–10 hours."),
        .init(id: "helicase", title: "Helicase", memory: "The zipper", body: "Unwinds and unzips DNA by breaking hydrogen bonds between complementary base pairs.", tool: .helicase),
        .init(id: "binding", title: "Binding proteins", memory: "Hold the strands open", body: "Attach to separated DNA strands, stabilizing them and preventing them from rejoining.", tool: .binding),
        .init(id: "primase", title: "Primase & RNA primer", memory: "The starting flag", body: "Primase builds a short complementary RNA primer. Its exposed 3′ end gives DNA polymerase a starting point. Each Okazaki fragment needs its own primer.", tool: .primase),
        .init(id: "polymerase", title: "DNA polymerase", memory: "The builder and proofreader", body: "Adds complementary DNA nucleotides to an exposed 3′ end and checks for mismatches. It cannot start a strand from scratch. New DNA grows only 5′ → 3′.", tool: .polymerase),
        .init(id: "pairing", title: "Complementary base pairing", memory: "A–T · C–G", body: "Adenine (A) pairs with thymine (T). Cytosine (C) pairs with guanine (G). The template determines which DNA nucleotide is added."),
        .init(id: "leading", title: "Leading strand", memory: "A continuous build", body: "New DNA grows continuously 5′ → 3′ toward the unwinding replication fork."),
        .init(id: "lagging", title: "Lagging strand & Okazaki fragments", memory: "A series of short builds", body: "New DNA is built discontinuously in short Okazaki fragments. Each has its own RNA primer and grows 5′ → 3′ away from the fork."),
        .init(id: "repair", title: "Primer removal & replacement", memory: "Swap RNA for DNA", body: "Repair enzymes remove RNA primers from both strands. DNA polymerase fills the gaps with DNA from a neighboring 3′ end. A backbone nick remains to be sealed.", tool: .repair),
        .init(id: "ligase", title: "Ligase", memory: "The glue bottle", body: "Seals remaining nicks by forming covalent bonds in the sugar-phosphate backbone. It joins neighboring DNA segments after primer replacement.", tool: .ligase),
        .init(id: "accuracy", title: "Proofreading & mutation", memory: "Check as you build", body: "DNA polymerase removes mismatches and inserts correct nucleotides. With additional repair, final errors can be as low as one per billion nucleotides. An uncorrected permanent DNA sequence change is a mutation. More rounds of copying create more opportunities for mutations."),
        .init(id: "energy", title: "ATP & energy", memory: "Enzymes need energy", body: "DNA construction requires an energy input. ATP powers enzyme work, including helicase and ligase."),
        .init(id: "result", title: "Semiconservative replication", memory: "Keep one, build one", body: "Each resulting DNA molecule contains one original parental strand and one newly made complementary strand.")
    ]
}
