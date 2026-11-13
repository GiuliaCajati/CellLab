//
//  Meiosis.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/12/26.
//
import SwiftUI

/// Add this file to CellLab. Open with MeiosisView() or MeiosisView(catalog: catalog).
/// Content is based on the supplied course notes. Illustrations are schematic.
struct MeiosisView: View {
    init(catalog: BiologyCatalog? = nil) {}
    @State private var detail: MeiDetail?
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Meiosis").font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        Text("Half the chromosomes. A new mix.")
                            .font(.system(.caption, design: .rounded)).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    Button { detail = .phase(.prophaseI) } label: {
                        Label("Explore", systemImage: "arrow.right.circle.fill")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .frame(minHeight: 36)
                    }
                    .buttonStyle(.borderedProminent).tint(MeiPalette.purple)
                }
                MeiPhaseCarousel { detail = .phase($0) }
                MeiCountJourney { detail = .counts }
                Button { detail = .terms } label: {
                    HStack {
                        Label("Meet the key players", systemImage: "text.book.closed.fill")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(.headline, design: .rounded))
                    .padding(18).background(MeiPalette.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 22))
                }
                .buttonStyle(.plain)
            }
            .padding(18).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }
        .background((scheme == .dark ? Color(red: 0.07, green: 0.12, blue: 0.16) : Color(red: 0.96, green: 0.97, blue: 1)).ignoresSafeArea())
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .sheet(item: $detail) { MeiDetailSheet(detail: $0) }
    }
}



private struct MeiPhaseCarousel: View {
    let select: (MeiPhase) -> Void
    @State private var page = 0
    @ScaledMetric(relativeTo: .title2) private var cardHeight: CGFloat = 300
    private let phases = MeiPhase.allCases
    private var second: Bool { phases[page].second }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(second ? "MEIOSIS II" : "MEIOSIS I")
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(second ? MeiPalette.teal : MeiPalette.rose)
                Spacer()
                Text(second ? "Separate sisters" : "Separate homologs")
                    .font(.system(.caption, design: .rounded, weight: .bold))
            }
            TabView(selection: $page) {
                ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
                    Button { select(phase) } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(phase.title).font(.system(.title, design: .rounded, weight: .heavy))
                                    .lineLimit(1).minimumScaleFactor(0.75)
                                Spacer(minLength: 4)
                                Text("\(index + 1)/8").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                            }
                            MeiPhaseArt(phase: phase).frame(height: 170).accessibilityHidden(true)
                            HStack {
                                Text(phase.cue).font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 4)
                                Image(systemName: "info.circle")
                            }
                            Text("2 pairs shown · human cells start with 23 pairs")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(16).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .background(phase.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 26))
                        .overlay(RoundedRectangle(cornerRadius: 26).stroke(phase.tint.opacity(0.22), lineWidth: 1.5))
                        .padding(.horizontal, 2)
                    }
                    .buttonStyle(.plain).tag(index)
                    .accessibilityLabel("\(phase.title). \(phase.cue)")
                    .accessibilityHint("Opens phase illustration and steps")
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never)).frame(height: cardHeight)
            HStack(spacing: 0) {
                ForEach(phases.indices, id: \.self) { index in
                    Button { page = index } label: {
                        Capsule().fill(page == index ? phases[index].tint : Color.secondary.opacity(0.25))
                            .frame(width: page == index ? 24 : 7, height: 7)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain).accessibilityLabel(phases[index].title)
                    .accessibilityAddTraits(page == index ? .isSelected : [])
                    if index == 3 {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.25))
                            .frame(width: 1, height: 14)
                            .padding(.horizontal, 7)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
    }
}

// MARK: - Native vector art (two homologous pairs: one long, one short)

private struct MeiPhaseArt: View {
    let phase: MeiPhase
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 340, size.height / 190)
            context.translateBy(x: (size.width - 340 * scale) / 2, y: (size.height - 190 * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            MeiDrawing.phase(phase, in: &context)
        }
    }
}


// MARK: - Full chromosome count journey

private struct MeiCountJourney: View {
    let showDetails: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Button(action: showDetails) {
                    Image(systemName: "info.circle").font(.title3).frame(width: 44, height: 44)
                }.buttonStyle(.plain).accessibilityLabel("Explain chromosome counts")
            }
            ForEach(0..<3, id: \.self) { stage in
                if stage > 0 {
                    HStack {
                        Rectangle().frame(height: 1).opacity(0.15)
                        Label(stage == 1 ? "MEIOSIS I" : "MEIOSIS II", systemImage: "arrow.down")
                            .font(.caption2.weight(.heavy)).fixedSize()
                        Rectangle().frame(height: 1).opacity(0.15)
                    }
                }
                MeiCountRow(stage: stage)
            }
            Text("Symbols show counts; chromosomes uncoil at the finish.")
                .font(.caption2).multilineTextAlignment(.center)
        }
        .foregroundStyle(MeiPalette.ink).padding(16)
        .background(LinearGradient(colors: [Color(red: 0.97, green: 0.85, blue: 0.91), Color(red: 0.84, green: 0.82, blue: 0.98), Color(red: 0.76, green: 0.94, blue: 0.89)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 26))
    }
}

private struct MeiCountRow: View {
    let stage: Int
    var body: some View {
        VStack(spacing: 7) {
            HStack {
                Text(["START · 1 DIPLOID CELL (2n)", "AFTER I · 2 HAPLOID CELLS (n)", "FINISH · 4 HAPLOID PRODUCTS (n)"][stage])
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.55), in: Capsule())
                Spacer()
            }
            MeiCountArt(stage: stage).frame(height: 152).accessibilityHidden(true)
            HStack(alignment: .top) {
                VStack(spacing: 3) {
                    Text(stage == 0 ? "46 chromosomes" : "23 chromosomes each").fontWeight(.bold)
                    Text(stage == 0 ? "23 pairs · 92 chromatids" : stage == 1 ? "1 set · 46 chromatids each" : "1 set · 23 chromatids each")
                }.frame(maxWidth: .infinity)
                VStack(spacing: 3) {
                    Text(stage == 0 ? "1 homologous pair" : "1 chromosome").fontWeight(.bold)
                    Text(stage == 0 ? "2 chromosomes · 4 chromatids" : stage == 1 ? "2 sister chromatids" : "1 chromatid")
                }.frame(maxWidth: .infinity)
            }
            .font(.system(.caption2, design: .rounded)).multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([
            "Start: one diploid human cell, 46 chromosomes in 23 pairs, 92 chromatids. The lens shows two homologous replicated chromosomes: four chromatids.",
            "After meiosis I: two haploid cells, each with 23 replicated chromosomes and 46 chromatids. The lens shows one chromosome with two sisters, which may differ after crossing over.",
            "Finish: four haploid products, each with 23 single-chromatid chromosomes. The lens shows one chromosome with one chromatid."
        ][stage])
    }
}

private struct MeiCountArt: View {
    let stage: Int
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 340, size.height / 160)
            context.translateBy(x: (size.width - 340 * scale) / 2, y: (size.height - 160 * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            let count = stage == 0 ? 1 : stage == 1 ? 2 : 4
            let radius: CGFloat = stage == 0 ? 62 : stage == 1 ? 39 : 33
            var selected = CGPoint.zero
            var highlighted: [CGPoint] = []
            for cell in 0..<count {
                let p: CGPoint
                if stage == 0 { p = CGPoint(x: 78, y: 78) }
                else if stage == 1 { p = CGPoint(x: cell == 0 ? 45 : 114, y: cell == 0 ? 42 : 118) }
                else { p = CGPoint(x: cell % 2 == 0 ? 41 : 115, y: cell < 2 ? 40 : 116) }
                let rect = CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)
                MeiDrawing.cell(&context, rect)
                let total = stage == 0 ? 46 : 23
                // Deterministic golden-angle packing gives exactly 46 or 23 separate symbols.
                for i in 0..<total {
                    let angle = CGFloat(i) * 2.39996323
                    let r = radius * 0.76 * sqrt((CGFloat(i) + 0.5) / CGFloat(total))
                    let q = CGPoint(x: p.x + cos(angle) * r, y: p.y + sin(angle) * r)
                    let parent = stage == 0 ? i % 2 : (i + cell) % 2
                    MeiDrawing.chromosome(&context, at: q, length: radius * 0.13, parent: parent,
                                          replicated: stage < 2, swapped: stage > 0 && i == 0, swappedSister: 0, face: false)
                    if cell == count - 1 && i == 0 { selected = q }
                    if cell == count - 1 && (i == 0 || (stage == 0 && i == 1)) { highlighted.append(q) }
                }
            }
            let lens = CGPoint(x: 263, y: 76)
            for (index, dy) in [CGFloat(-23), CGFloat(23)].enumerated() {
                let origin = stage == 0 ? highlighted[index] : selected
                var line = Path(); line.move(to: origin); line.addLine(to: CGPoint(x: lens.x - 51, y: lens.y + dy))
                context.stroke(line, with: .color(MeiPalette.purple.opacity(0.65)), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            }
            for point in highlighted {
                context.stroke(Path(ellipseIn: CGRect(x: point.x - 6, y: point.y - 6, width: 12, height: 12)), with: .color(MeiPalette.gold), lineWidth: 2)
            }
            var handle = Path(); handle.move(to: CGPoint(x: 300, y: 116)); handle.addLine(to: CGPoint(x: 320, y: 139))
            context.stroke(handle, with: .color(MeiPalette.purple), style: StrokeStyle(lineWidth: 10, lineCap: .round))
            let circle = Path(ellipseIn: CGRect(x: lens.x - 57, y: lens.y - 57, width: 114, height: 114))
            context.fill(circle, with: .color(.white.opacity(0.92)))
            context.stroke(circle, with: .color(MeiPalette.purple), lineWidth: 3)
            if stage == 0 {
                MeiDrawing.chromosome(&context, at: CGPoint(x: 242, y: 76), length: 59, parent: 0)
                MeiDrawing.chromosome(&context, at: CGPoint(x: 283, y: 76), length: 59, parent: 1)
            } else {
                MeiDrawing.chromosome(&context, at: lens, length: 78, parent: 1, replicated: stage == 1, swapped: true, swappedSister: 0)
            }
        }
    }
}

// MARK: - Details, vocabulary, and small interactive explanations

private enum MeiDetail: Identifiable {
    case phase(MeiPhase), preparation, interkinesis, counts, terms
    var id: String {
        switch self {
        case .phase(let phase): return "phase-\(phase.id)"
        case .preparation: return "preparation"
        case .interkinesis: return "interkinesis"
        case .counts: return "counts"
        case .terms: return "terms"
        }
    }
    var title: String {
        switch self {
        case .phase(let phase): return phase.title
        case .preparation: return "Copy once. Divide twice."
        case .interkinesis: return "A pause—not a copy round."
        case .counts: return "Count chromosomes, not arms."
        case .terms: return "Meet the key players"
        }
    }
}

private struct MeiDetailSheet: View {
    let detail: MeiDetail
    @Environment(\.dismiss) private var dismiss
    @State private var phaseOverride: MeiPhase?
    private var active: MeiDetail { phaseOverride.map { .phase($0) } ?? detail }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(active.title).font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        .accessibilityAddTraits(.isHeader)
                    content
                }.padding(22).frame(maxWidth: 660).frame(maxWidth: .infinity, alignment: .center)
            }
            .navigationTitle("Meiosis").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    @ViewBuilder private var content: some View {
        switch active {
        case .phase(let phase):
            MeiPhaseArt(phase: phase).frame(height: 220)
                .background(phase.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
                .accessibilityLabel("\(phase.cue) Simplified model showing two homologous pairs; human cells start with 23 pairs.")
            Text(phase.cue)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            DisclosureGroup("A little more biology") {
                Text(phase.explanation)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
            }
            .tint(.primary)
            .padding(18)
            .background(phase.tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 20))
            .id(phase.id)
            HStack {
                Button { phaseOverride = MeiPhase(rawValue: phase.rawValue - 1) } label: { Label("Back", systemImage: "arrow.left") }
                    .disabled(phase == .prophaseI)
                Spacer()
                if phase != .telophaseII {
                    Button { phaseOverride = MeiPhase(rawValue: phase.rawValue + 1) } label: { Label("Next phase", systemImage: "arrow.right") }
                        .buttonStyle(.borderedProminent).tint(phase.tint)
                } else { Button("Done exploring") { dismiss() }.buttonStyle(.borderedProminent) }
            }
        case .preparation:
            Text("Before meiosis, a diploid germ-cell precursor grows and copies its DNA during S phase of interphase.")
            MeiCountArt(stage: 0).frame(height: 180).accessibilityHidden(true)
            note("46 chromosomes → 46 replicated chromosomes\n46 chromatids → 92 chromatids")
            Text("Each chromosome now has two sister chromatids joined at a centromere. Centrosomes also duplicate, and the cell makes proteins needed for division.")
            Text("DNA replication doubles the DNA amount—not the chromosome count.").font(.headline)
        case .interkinesis:
            Image(systemName: "pause.circle.fill").font(.system(size: 68)).foregroundStyle(MeiPalette.purple).frame(maxWidth: .infinity)
            Text("Some species have a brief interval called interkinesis between meiosis I and II. Chromosomes may relax, but there is no S phase and no DNA replication.")
            note("Already haploid. Still two chromatids per chromosome.")
        case .counts:
            ForEach(0..<3, id: \.self) { stage in
                Text(["Start · diploid (2n)", "After I · haploid (n)", "After II · haploid (n)"][stage]).font(.headline)
                Text(["1 cell: 46 chromosomes, 92 chromatids.", "2 cells: each has 23 chromosomes, 46 chromatids.", "4 products: each has 23 chromosomes, 23 chromatids."][stage])
            }
            note("23 pairs = 46 chromosomes.\nOne haploid set = 23 chromosomes, not 23 pairs.")
            Text("A replicated chromosome counts as one while its sisters remain joined. In anaphase II, sisters become separate chromosomes: briefly 46 chromosomes in each still-dividing cell, with 23 moving to each pole.")
            Text("The four-product model shows chromosome segregation. In sperm formation, the four products can develop into sperm. In egg formation, unequal cytoplasm division produces one large egg and small polar bodies; four functional eggs are not produced.")
        case .terms:
            TabView {
                // Crossing over page
                VStack(alignment: .leading, spacing: 12) {
                    Text("Crossing over").font(.system(.title2, design: .rounded, weight: .heavy))
                    MeiCrossingDemo()
                    Text("In prophase I, homologs align gene by gene (synapsis). Corresponding DNA segments are exchanged between non-sister chromatids. Chiasmata are the visible crossover connections.")
                    note("One crossover involves two of the four chromatids: two recombinant chromatids and two unchanged parental chromatids in this example.")
                    Text("Sisters start as identical copies. After crossing over, they can carry different allele combinations. A crossover does not guarantee that all four products are genetically distinct in every possible case.")
                }
                .padding(16)
                .background(MeiPalette.purple.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 4)

                // Independent assortment page
                VStack(alignment: .leading, spacing: 12) {
                    Text("Independent assortment").font(.system(.title2, design: .rounded, weight: .heavy))
                    MeiAssortmentDemo()
                    Text("Each homologous pair faces the poles independently at metaphase I. A maternal homolog of one pair can travel with a paternal homolog of another.")
                    note("2ⁿ combinations · n = chromosome pairs\nHumans: 2²³ = 8,388,608")
                    Text("That is the number of possible maternal/paternal chromosome combinations across many meioses, before counting crossing over—not millions of products from one division.")
                }
                .padding(16)
                .background(MeiPalette.purple.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 4)

                // Random fertilization page
                VStack(alignment: .leading, spacing: 12) {
                    Text("Random fertilization").font(.system(.title2, design: .rounded, weight: .heavy))
                    HStack {
                        fertilizationBadge("23", "egg")
                        Text("+").font(.largeTitle.bold())
                        fertilizationBadge("23", "sperm")
                        Text("=").font(.largeTitle.bold())
                        fertilizationBadge("46", "zygote")
                    }
                    Text("Fertilization happens after meiosis. Any one egg can combine with any one sperm, restoring the diploid chromosome number.")
                    note("8,388,608 × 8,388,608\n= 70,368,744,177,664 combinations")
                    Text("Over 70 trillion possible chromosome combinations for a couple—even before adding crossing over.")
                }
                .padding(16)
                .background(MeiPalette.purple.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 4)

                // Terms pages
                ForEach(MeiTerm.all) { term in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(term.name).font(.system(.title2, design: .rounded, weight: .heavy))
                        Text(term.definition)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(MeiPalette.purple.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 4)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 420)
        }
    }

    private func note(_ text: String) -> some View {
        Text(text).font(.system(.subheadline, design: .rounded, weight: .semibold))
            .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
            .padding(16).background(MeiPalette.gold.opacity(0.17), in: RoundedRectangle(cornerRadius: 18))
    }
    private func fertilizationBadge(_ number: String, _ title: String) -> some View {
        VStack {
            Text(number).font(.system(.title, design: .rounded, weight: .heavy))
            Text(title).font(.caption)
        }.frame(maxWidth: .infinity).padding(.vertical, 18)
            .background(MeiPalette.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 20))
    }
}




