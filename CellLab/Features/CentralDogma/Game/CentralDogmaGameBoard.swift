import SwiftUI

@MainActor struct CentralDogmaGameBoard: View {
    @Bindable var session: CentralDogmaGameSession
    let step: CentralDogmaGameStep
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 16) {
            switch step.kind {
            case "factors", "polymerase", "open", "terminate": dnaBoard
            case "rna": transcriptionBoard
            case "cap", "tail", "splice", "join": processingBoard
            case "export": exportBoard
            case "small", "initiator", "large", "deliver", "bond", "move", "recycle", "release": translationBoard
            case "fold": foldingBoard
            case "cleave": cleavageBoard
            case "assemble": assemblyBoard
            default: EmptyView()
            }
        }
        .centralDogmaGamePanel(boardTint)
        .accessibilityIdentifier("rna-relay-board")
    }
    private var boardTint: Color {
        switch step.group {
        case "Transcribe": return CentralDogmaGameTheme.blue.opacity(0.35)
        case "Process": return CentralDogmaGameTheme.butter
        case "Translate": return CentralDogmaGameTheme.lavender.opacity(0.35)
        default: return CentralDogmaGameTheme.sage.opacity(0.45)
        }
    }
    private func target(_ id: String, _ title: String, _ detail: String = "", automatic: String? = nil, solved: Bool = false, tint: Color = CentralDogmaGameTheme.sage) -> some View {
        CentralDogmaGameTarget(session: session, step: step, target: id, title: title,
                              detail: detail, automatic: automatic, solved: solved, tint: tint)
    }
    private func caption(_ value: String) -> some View {
        Text(value).font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(CentralDogmaGameTheme.muted).multilineTextAlignment(.center)
    }
    private var dnaBoard: some View {
        VStack(spacing: 14) {
            caption("NUCLEUS · EUKARYOTIC CELL")
            CentralDogmaGameHelix(open: session.has("open") && !session.has("terminate"))
            HStack(spacing: 8) {
                target("dna:promoter", "Promoter", "Start here")
                target("dna:gene", "Gene", "DNA recipe")
                target("dna:terminator", "Terminator", "Finish here")
            }
            if session.has("polymerase") || step.kind == "open" {
                CentralDogmaGameArt(name: "CentralRNAWriter", height: 86)
                if step.kind == "open" { target("enzyme:polymerase", "RNA polymerase", "Tap to open DNA", automatic: "action:open") }
                else { caption(session.has("terminate") ? "RNA released · DNA rewinds" : "RNA polymerase") }
            }
        }
    }
    private var transcriptionBoard: some View {
        let i = step.sequenceIndex ?? 0
        let dna = Array(session.mission.template).map(String.init)
        let rna = Array(session.mission.preRNA).map(String.init)
        let start = min(max(0, i - 1), dna.count - 4)
        return VStack(spacing: 10) {
            caption("NUCLEUS · RNA SYNTHESIS")
            HStack {
                caption("Template DNA")
                Spacer()
                Text("read 3′ → 5′").font(.system(.caption, design: .rounded, weight: .bold))
            }
            HStack { caption(start == 0 ? "3′" : "…"); Spacer(); caption(start + 4 == dna.count ? "5′" : "…") }
            HStack(spacing: 6) {
                ForEach(start..<(start + 4), id: \.self) { position in
                    Text(dna[position]).font(.system(size: 25, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 49)
                        .background(position == i ? CentralDogmaGameTheme.blue : CentralDogmaGameTheme.paper, in: RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(CentralDogmaGameTheme.edge.opacity(position == i ? 0.8 : 0.2), lineWidth: position == i ? 2 : 1))
                }
            }
            Image(systemName: "arrow.down").foregroundStyle(CentralDogmaGameTheme.teal).accessibilityHidden(true)
            HStack(spacing: 6) {
                ForEach(start..<(start + 4), id: \.self) { position in
                    if position < session.rnaCount {
                        Text(rna[position]).font(.system(size: 24, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 62)
                            .background(CentralDogmaGameTheme.nucleotide(rna[position]), in: RoundedRectangle(cornerRadius: 15))
                    } else if position == i {
                        target("rna:\(i)", "+", "add at 3′")
                    } else {
                        Text("·").font(.title).foregroundStyle(CentralDogmaGameTheme.edge.opacity(0.4))
                            .frame(maxWidth: .infinity, minHeight: 62)
                    }
                }
            }
            HStack { caption(start == 0 ? "5′ · RNA" : "… RNA"); Spacer(); caption("grows 5′ → 3′") }
            CentralDogmaGameToolbox(session: session, step: step)
            caption((i >= 3 && i <= 6) ? "Intron window · this region is copied too" : "Exon window")
            ProgressView(value: Double(session.rnaCount), total: Double(rna.count)).tint(CentralDogmaGameTheme.teal)
            caption("Selected sequence windows · not a complete gene")
        }
    }
    private var processingBoard: some View {
        VStack(spacing: 14) {
            caption("NUCLEUS · pre-mRNA PROCESSING")
            HStack(spacing: 10) {
                target("rna:end5", session.has("cap") ? "5′ cap ✓" : "5′ end", "Modified cap", solved: session.has("cap"), tint: CentralDogmaGameTheme.blue)
                target("rna:end3", session.has("tail") ? "Tail ✓" : "3′ end", "100–200 A’s", solved: session.has("tail"), tint: CentralDogmaGameTheme.butter)
            }
            if !session.has("join") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(session.mission.regions) { region in
                        if region.kind == "intron" && session.has("splice") {
                            VStack(spacing: 4) { Image(systemName: "checkmark"); Text("Intron removed").font(.caption) }
                                .foregroundStyle(CentralDogmaGameTheme.muted).frame(maxWidth: .infinity, minHeight: 76)
                        } else {
                            target("region:" + region.id, region.kind == "intron" ? "…CGUC…" : region.sequence,
                                   region.label, tint: region.kind == "intron" ? CentralDogmaGameTheme.lavender : CentralDogmaGameTheme.pink)
                        }
                    }
                }
                if session.has("splice") { target("rna:join", "Join exons", "Complete splicing", automatic: "action:join", tint: CentralDogmaGameTheme.pink) }
            } else { codonStrip }
            caption("Ellipses mark omitted intron sequence. Regions shown as practice windows.")
        }
    }
    private var exportBoard: some View {
        VStack(spacing: 16) {
            caption("NUCLEUS → CYTOPLASM")
            Text("5′ cap  ·  joined exons  ·  poly A tail")
                .font(.system(.subheadline, design: .rounded, weight: .semibold)).multilineTextAlignment(.center)
            Image(systemName: "envelope.fill").font(.system(size: 52)).foregroundStyle(CentralDogmaGameTheme.teal)
            target("nucleus:exit", "Nucleus exit", "Send mature mRNA")
        }
    }
    private var codonStrip: some View {
        HStack(spacing: 6) {
            ForEach(Array(session.mission.codons.enumerated()), id: \.offset) { i, codon in
                target("codon:\(i)", codon, i == 3 ? "stop" : "codon", tint: CentralDogmaGameTheme.butter)
            }
        }
    }
    private var translationBoard: some View {
        VStack(spacing: 15) {
            caption("CYTOPLASM · TRANSLATION")
            if step.kind == "small" {
                target("rna:end5", "5′ cap", "Small subunit binds here", tint: CentralDogmaGameTheme.blue)
            }
            if session.has("initiator") {
                HStack(spacing: 10) {
                    ForEach(0..<max(1, session.chainCount), id: \.self) { _ in
                        Text("Met").font(.system(.caption, design: .rounded, weight: .bold))
                            .frame(width: 46, height: 46).background(CentralDogmaGameTheme.pink, in: Circle())
                    }
                }
                caption("Growing practice amino acid chain")
            }
            if session.has("small") {
                VStack(spacing: 5) {
                    if session.has("large") {
                        Capsule().fill(CentralDogmaGameTheme.lavender).frame(width: 166, height: 48)
                            .overlay(Text("Large subunit").font(.system(.caption, design: .rounded, weight: .semibold)))
                    }
                    Capsule().fill(CentralDogmaGameTheme.sage).frame(width: 140, height: 31)
                        .overlay(Text("Small subunit").font(.system(.caption2, design: .rounded, weight: .semibold)))
                }
            }
            HStack { caption("5′ → 3′ · mRNA"); Spacer(); caption("… poly A · 3′") }
            codonStrip
            if session.has("large") {
                let position = min(2, session.records.filter { $0.kind == "move" }.count)
                GeometryReader { proxy in
                    let cell = (proxy.size.width - 18) / 4
                    Text("ribosome").font(.system(.caption2, design: .rounded, weight: .bold))
                        .frame(width: cell * 2 + 6, height: 22)
                        .background(CentralDogmaGameTheme.sage, in: Capsule())
                        .offset(x: CGFloat(position) * (cell + 6))
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: position)
                }.frame(height: 22).accessibilityLabel("Ribosome shifts one codon at each translocation")
            }
            if ["initiator", "deliver", "bond", "large"].contains(step.kind) {
                caption("codon   5′-AUG-3′\nanticodon   3′-UAC-5′")
            }
            if step.kind == "large" { target("ribosome:assembly", "Add large subunit", "Complete the ribosome") }
            if step.kind == "bond" {
                Text("Incoming Met").font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .padding(10).background(CentralDogmaGameTheme.peach, in: Capsule())
                target("protein:bond", "Connect amino acids", "Ribosome forms the peptide bond", automatic: "action:bond", tint: CentralDogmaGameTheme.pink)
            }
            if step.kind == "move" {
                HStack(spacing: 10) {
                    target("ribosome:move", "← 3′ → 5′", "Reverse", automatic: "move:3to5", tint: CentralDogmaGameTheme.paper)
                    target("ribosome:move", "5′ → 3′ →", "One codon forward", automatic: "move:5to3")
                }
            }
            if step.kind == "recycle" { target("cytosol:recycle", "Back to the cytosol", "Empty tRNA can pick up another amino acid") }
            if step.kind == "release" { caption("UGA · UAA · UAG\nStop codons have no matching tRNA.") }
            if ["deliver", "bond", "move", "recycle"].contains(step.kind) { caption("Elongation factors help delivery and movement.") }
        }
    }
    private var foldingBoard: some View {
        VStack(spacing: 13) {
            caption("FULL-LENGTH POLYPEPTIDE · A SEPARATE EXAMPLE")
            CentralDogmaGameChain()
            target("protein:fold", "Help it fold", "Chaperone proteins aid and stabilize folding")
            caption("The short three-Met practice fragment is not shown as a functional protein.")
        }
    }
    private var cleavageBoard: some View {
        VStack(spacing: 13) {
            caption("SEPARATE FINISHING EXAMPLE · CLEAVAGE")
            Text("Proinsulin").font(.system(.title3, design: .rounded, weight: .bold))
            CentralDogmaGameChain()
            target("protein:cleave", "Cleavage site", "Enzymes produce 51-amino-acid insulin", tint: CentralDogmaGameTheme.peach)
            caption("Different proteins use different finishing steps.")
        }
    }
    private var assemblyBoard: some View {
        VStack(spacing: 15) {
            caption("SEPARATE FINISHING EXAMPLE · ASSEMBLY")
            Text("Hemoglobin").font(.system(.title2, design: .serif, weight: .bold))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<4, id: \.self) { i in
                    target("hemoglobin:\(i)", session.usedSlots.contains("hemoglobin:\(i)") ? "Connected" : "+", "One separate subunit", solved: session.usedSlots.contains("hemoglobin:\(i)"), tint: i.isMultiple(of: 2) ? CentralDogmaGameTheme.pink : CentralDogmaGameTheme.blue)
                }
            }
            caption("\(session.usedPieces.count) of 4 separate chains connected")
        }
    }
}
