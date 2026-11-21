import SwiftUI

@MainActor struct CentralDogmaGameBoard: View {
    @Bindable var session: CentralDogmaGameSession
    let step: CentralDogmaGameStep
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingExport = false

    private var chapter: Int {
        ["Transcribe", "Process", "Translate", "Finish"].firstIndex(of: step.group) ?? 0
    }
    private var location: String { chapter < 2 ? "Nucleus" : "Cytoplasm" }
    var body: some View {
        VStack(spacing: 8) {
            route
            HStack {
                Label(location, systemImage: chapter < 2 ? "circle.dotted.circle" : "circle")
                Spacer()
                if step.kind == "rna" { Text("\(session.rnaCount) / \(session.mission.preRNA.count)") }
                if chapter == 2 { Text("\(session.chainCount) amino acids") }
            }
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(CentralDogmaGameTheme.muted)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Current scene")
            .accessibilityValue("\(location); \(session.rnaCount) RNA bases; \(session.chainCount) amino acids")
            .accessibilityIdentifier("rna-relay-stage")

            Group {
                switch step.kind {
                case "factors", "polymerase", "open", "terminate": dnaScene
                case "rna": transcriptionScene
                case "cap", "tail", "splice", "join": processingScene
                case "export": exportScene
                case "small", "initiator", "large", "deliver", "bond", "move", "recycle", "release": translationScene
                case "fold": foldingScene
                case "cleave": cleavageScene
                case "assemble": assemblyScene
                default: EmptyView()
                }
            }
            .overlay {
                if showingExport {
                    CentralDogmaGameExportFlight(sequence: session.mission.matureRNA)
                        .background(CentralDogmaGameTheme.paper, in: RoundedRectangle(cornerRadius: 20))
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
        }
        .padding(12)
        .background(CentralDogmaGameTheme.paper, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(CentralDogmaGameTheme.edge.opacity(0.18)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("rna-relay-board")
        .onChange(of: session.has("export")) { _, exported in
            if exported && !reduceMotion { showingExport = true }
        }
        .task(id: showingExport) {
            guard showingExport else { return }
            do { try await Task.sleep(for: .milliseconds(1000)) } catch { return }
            withAnimation(.easeOut(duration: 0.2)) { showingExport = false }
        }
    }
    private var route: some View {
        HStack(spacing: 3) {
            ForEach(Array(["Copy", "Edit", "Build", "Finish"].enumerated()), id: \.offset) { i, name in
                if i > 0 { Image(systemName: "chevron.right").font(.system(size: 8, weight: .bold)).foregroundStyle(CentralDogmaGameTheme.edge.opacity(0.4)) }
                HStack(spacing: 4) {
                    Image(systemName: i < chapter ? "checkmark.circle.fill" : ["doc.on.doc", "scissors", "link", "sparkles"][i])
                    Text(name)
                }
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .padding(.horizontal, 6).padding(.vertical, 7)
                .foregroundStyle(i == chapter ? CentralDogmaGameTheme.paper : CentralDogmaGameTheme.muted)
                .background(i == chapter ? CentralDogmaGameTheme.teal : .clear, in: Capsule())
                .frame(maxWidth: .infinity)
            }
        }.accessibilityElement(children: .ignore).accessibilityLabel("Stage \(chapter + 1) of 4: \(step.group)")
    }
    private func spot<Artwork: View>(_ id: String, _ title: String, automatic: String? = nil,
                                    solved: Bool = false, @ViewBuilder artwork: @escaping () -> Artwork) -> some View {
        CentralDogmaGameTarget(session: session, step: step, target: id, title: title,
                              automatic: automatic, solved: solved, artwork: artwork)
    }
    private func tag(_ text: String) -> some View {
        Text(text).font(.system(.caption2, design: .rounded, weight: .semibold))
            .foregroundStyle(CentralDogmaGameTheme.muted)
    }
    private var dnaScene: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            ZStack {
                Ellipse().fill(CentralDogmaGameTheme.blue.opacity(0.35))
                Ellipse().strokeBorder(CentralDogmaGameTheme.teal.opacity(0.3), lineWidth: 2).padding(6)
                CentralDogmaGameHelix(height: 66).padding(.horizontal, 10).position(x: w / 2, y: 111)
                if session.has("factors") {
                    CentralDogmaGameToolArt(payload: "tool:factors").frame(width: 38, height: 35).position(x: w * 0.19, y: 74)
                }
                if step.kind == "open" {
                    spot("enzyme:polymerase", "Unzip DNA with RNA polymerase", automatic: "action:open") {
                        Image("CentralRNAWriter").resizable().scaledToFit().frame(height: 77)
                    }.frame(width: 117).position(x: w * 0.43, y: 93)
                    tag("Tap the writer").position(x: w / 2, y: 175)
                } else {
                    if session.has("polymerase") {
                        Image("CentralRNAWriter").resizable().scaledToFit().frame(width: 72, height: 48).position(x: w * 0.33, y: 97)
                    }
                    HStack(spacing: 5) {
                        spot("dna:promoter", "Promoter") {
                            VStack(spacing: 3) { Image(systemName: "flag.fill").font(.title3); tag("Promoter") }
                        }
                        spot("dna:gene", "Gene") {
                            VStack(spacing: 3) { CentralDogmaGameHelix(height: 22).frame(width: 40); tag("Gene") }
                        }
                        spot("dna:terminator", "Terminator") {
                            VStack(spacing: 3) { Image(systemName: "stop.circle.fill").font(.title3); tag("Terminator") }
                        }
                    }.position(x: w / 2, y: 157)
                }
                tag("DNA").position(x: w / 2, y: 34)
            }
        }.frame(height: 205)
    }
    private var transcriptionScene: some View {
        let i = step.sequenceIndex ?? 0
        let dna = Array(session.mission.template).map(String.init)
        let rna = Array(session.mission.preRNA).map(String.init)
        let start = min(max(0, i - 1), dna.count - 4)
        return VStack(spacing: 5) {
            HStack {
                tag("DNA · 3′ → 5′")
                Spacer()
                Image("CentralRNAWriter").resizable().scaledToFit().frame(width: 52, height: 35).accessibilityHidden(true)
            }
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(start..<(start + 4), id: \.self) { position in
                    VStack(spacing: 4) {
                        CentralDogmaGameNucleotide(base: dna[position]).padding(3)
                            .background(position == i ? CentralDogmaGameTheme.butter : .clear, in: RoundedRectangle(cornerRadius: 12))
                        Image(systemName: position == i ? "arrow.down" : "line.3.horizontal")
                            .font(.caption2.bold()).foregroundStyle(CentralDogmaGameTheme.teal.opacity(position == i ? 1 : 0.25))
                        if position < session.rnaCount {
                            CentralDogmaGameNucleotide(base: rna[position]).padding(3).transition(.scale.combined(with: .opacity))
                        } else if position == i {
                            spot("rna:\(i)", "Growing RNA end") {
                                Image(systemName: "plus.circle.fill").font(.title2).frame(maxWidth: .infinity, minHeight: 48)
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 10).strokeBorder(CentralDogmaGameTheme.edge.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [3, 3])).frame(height: 57)
                        }
                    }.frame(maxWidth: .infinity)
                }
            }
            HStack { tag("RNA · 5′ → 3′"); Spacer(); tag((i >= 3 && i <= 6) ? "Intron" : "Exon") }
        }
    }
    private var processingScene: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            ZStack {
                CentralDogmaGameMessenger(sequence: session.has("join") ? session.mission.matureRNA : session.mission.preRNA,
                                         cap: session.has("cap"), tail: session.has("tail"))
                    .frame(height: 55).padding(.horizontal, 21).position(x: w / 2, y: 62)
                spot("rna:end5", "5′ cap", solved: session.has("cap")) {
                    ZStack { Circle().fill(CentralDogmaGameTheme.blue); Text(session.has("cap") ? "✓" : "5′").font(.headline) }.frame(width: 33, height: 33)
                }.frame(width: 51).position(x: w * 0.08, y: 59)
                spot("rna:end3", "3′ tail", solved: session.has("tail")) {
                    VStack(spacing: 2) { Text("AAA").font(.system(.caption, design: .rounded, weight: .bold)); tag(session.has("tail") ? "✓" : "3′") }
                }.frame(width: 57).position(x: w * 0.91, y: 65)
                HStack(spacing: 6) {
                    ForEach(session.mission.regions) { region in
                        if region.kind == "intron" && session.has("splice") {
                            if step.kind == "join" {
                                spot("rna:join", "Join exons", automatic: "action:join") { Image(systemName: "link").font(.title).frame(width: 45, height: 44) }
                            } else { Image(systemName: "checkmark").foregroundStyle(CentralDogmaGameTheme.teal).frame(width: 50) }
                        } else {
                            spot("region:" + region.id, region.kind == "intron" ? "Intron" : "Exon") {
                                VStack(spacing: 3) {
                                    CentralDogmaGameMessenger(sequence: region.sequence).frame(height: 30)
                                    tag(region.kind == "intron" ? "Cut intron" : "Exon")
                                }.padding(3).background(region.kind == "intron" ? CentralDogmaGameTheme.lavender : CentralDogmaGameTheme.pink, in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }.position(x: w / 2, y: 145)
            }
        }.frame(height: 190)
    }
    private var exportScene: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                CentralDogmaGameJourney(rnaCount: session.mission.matureRNA.count, rnaSequence: session.mission.matureRNA)
                spot("nucleus:exit", "Nuclear pore") {
                    Image(systemName: "arrow.right").font(.system(size: 25, weight: .bold)).frame(width: 39, height: 39)
                }.frame(width: 58).position(x: geometry.size.width * 0.45, y: 130)
            }
        }.frame(height: 200)
    }
    private var translationScene: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let moved = min(2, session.records.filter { $0.kind == "move" }.count)
            let x = w * CGFloat(moved + 1) / 4
            ZStack(alignment: .topLeading) {
                if session.has("small") {
                    CentralDogmaGameRibosome(large: session.has("large"))
                        .frame(width: w * 0.48, height: 113)
                        .position(x: x, y: 138)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.45), value: moved)
                } else {
                    CentralDogmaGameRibosome().opacity(0.15).frame(width: w * 0.48, height: 113).position(x: x, y: 138)
                }
                if session.has("initiator") {
                    HStack(spacing: 3) {
                        CentralDogmaGameBeads(count: max(1, session.chainCount))
                        if step.kind == "bond" {
                            spot("protein:bond", "Join these amino acids", automatic: "action:bond") {
                                Image(systemName: "link").font(.title3).frame(width: 32, height: 34)
                            }.frame(width: 46)
                            CentralDogmaGameBeads(count: 1)
                        }
                    }
                    .position(x: min(max(x, w * 0.37), w * 0.63), y: 44)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("rna-relay-amino-chain")
                }
                if ["initiator", "deliver"].contains(step.kind) {
                    CentralDogmaGameToolArt(payload: "trna:UAC").frame(width: 38, height: 55)
                        .position(x: min(w * 0.86, x + w * 0.19), y: 92).opacity(0.75)
                }
                if step.kind == "large" {
                    spot("ribosome:assembly", "Add large ribosome subunit") {
                        CentralDogmaGameRibosome(large: true, small: false).frame(width: w * 0.43, height: 72).opacity(0.7)
                            .overlay(Image(systemName: "plus.circle.fill").font(.title3), alignment: .top)
                    }.frame(width: w * 0.49).position(x: x, y: 112)
                }
                HStack(spacing: 4) {
                    ForEach(Array(session.mission.codons.enumerated()), id: \.offset) { i, codon in
                        spot("codon:\(i)", codon) {
                            VStack(spacing: 2) {
                                Capsule().fill(CentralDogmaGameTheme.teal).frame(height: 2)
                                HStack(spacing: 2) {
                                    ForEach(Array(codon.enumerated()), id: \.offset) { _, base in
                                        Text(String(base)).font(.system(.caption, design: .rounded, weight: .bold))
                                            .frame(maxWidth: .infinity, minHeight: 25)
                                            .background(CentralDogmaGameTheme.nucleotide(String(base)), in: RoundedRectangle(cornerRadius: 5))
                                    }
                                }
                            }
                        }
                    }
                }.position(x: w / 2, y: 171)
                if step.kind == "small" {
                    spot("rna:end5", "5′ cap") { Text("5′").font(.headline).padding(5).background(CentralDogmaGameTheme.blue, in: Circle()) }
                        .frame(width: 50).position(x: w * 0.09, y: 130)
                }
                HStack { tag("mRNA · 5′ → 3′"); Spacer(); tag(session.mission.stop + " = stop") }.position(x: w / 2, y: 209)
                if step.kind == "move" {
                    HStack {
                        spot("ribosome:move", "5′ direction", automatic: "move:3to5") { Image(systemName: "arrow.left").font(.title2).frame(width: 66, height: 35) }
                        Spacer()
                        spot("ribosome:move", "3′ direction", automatic: "move:5to3") { Image(systemName: "arrow.right").font(.title2).frame(width: 66, height: 35) }
                    }.position(x: w / 2, y: 247)
                }
                if step.kind == "recycle" {
                    spot("cytosol:recycle", "Recycle empty tRNA") {
                        Image(systemName: "arrow.triangle.2.circlepath").font(.title2).frame(width: 45, height: 45)
                    }.frame(width: 60).position(x: w * 0.85, y: 85)
                }
            }
        }.frame(height: step.kind == "move" ? 276 : 226)
    }
    private var foldingScene: some View {
        VStack(spacing: 4) {
            tag("A separate full-length chain")
            spot("protein:fold", "Full-length chain: add a chaperone") { CentralDogmaGameChain(height: 150) }
        }
    }
    private var cleavageScene: some View {
        spot("protein:cleave", "Proinsulin cleavage site") {
            ZStack {
                CentralDogmaGameChain(foldProgress: 0.4, height: 155)
                Image(systemName: "scissors").font(.system(size: 33)).padding(9).background(CentralDogmaGameTheme.paper, in: Circle())
            }
        }.overlay(alignment: .bottom) { tag("Proinsulin → insulin").allowsHitTesting(false) }
    }
    private var assemblyScene: some View {
        VStack(spacing: 8) {
            tag("Hemoglobin · \(session.usedSlots.count) / 4 chains")
            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { i in
                    spot("hemoglobin:\(i)", "Hemoglobin subunit \(i + 1)", solved: session.usedSlots.contains("hemoglobin:\(i)")) {
                        ZStack {
                            Circle().fill(i.isMultiple(of: 2) ? CentralDogmaGameTheme.pink : CentralDogmaGameTheme.blue)
                            if session.usedSlots.contains("hemoglobin:\(i)") { CentralDogmaGameToolArt(payload: "subunit:\(i)") }
                            else { Image(systemName: "plus").font(.title3) }
                        }.frame(height: 65)
                    }
                }
            }.padding(.vertical, 28)
        }
    }
}

private struct CentralDogmaGameExportFlight: View {
    let sequence: String
    @State private var outside = false
    var body: some View {
        CentralDogmaGameJourney(rnaCount: sequence.count, exported: outside, rnaSequence: sequence)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { outside = true }
    }
}
