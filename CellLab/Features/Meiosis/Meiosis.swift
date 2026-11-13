//
//  Meiosis.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/12/26.
//
//
//  MeiosisView.swift
//  CellLab
//

import SwiftUI

struct MeiosisView: View {
    init(catalog: BiologyCatalog? = nil) {}

    @State private var detail: MeiDetail?
    @State private var currentPhase: MeiPhase? = .prophaseI

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                MeiPhaseCarousel(selection: $currentPhase)
                MeiCountJourney { detail = .counts }

                Button { detail = .terms } label: {
                    HStack {
                        Label("Meet the key players", systemImage: "text.book.closed.fill")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(.headline, design: .rounded))
                    .padding(18)
                    .foregroundStyle(MeiPalette.ink)
                    .background(MeiPalette.mint, in: RoundedRectangle(cornerRadius: 22))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(MeiPalette.ink.opacity(0.7), lineWidth: 1.5)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(MeiPalette.paper.ignoresSafeArea())
        .foregroundStyle(MeiPalette.text)
        .tint(MeiPalette.teal)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $detail) { MeiDetailSheet(detail: $0) }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Meiosis")
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                    .accessibilityAddTraits(.isHeader)
                Text("Half the chromosomes. A new mix.")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Button { detail = .phase(currentPhase ?? .prophaseI) } label: {
                Label("Explore", systemImage: "arrow.right.circle.fill")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .frame(minHeight: 36)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
    }
}

private struct MeiPhaseCarousel: View {
    @Binding var selection: MeiPhase?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var current: MeiPhase { selection ?? .prophaseI }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(current.second ? "MEIOSIS II" : "MEIOSIS I")
                    .foregroundStyle(current.second ? MeiPalette.teal : MeiPalette.rose)
                Spacer()
                Text(current.second ? "Separate sisters" : "Separate homologs")
            }
            .font(.system(.caption, design: .rounded, weight: .bold))

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(MeiPhase.allCases) { phase in
                        MeiPhaseCard(phase: phase)
                            .containerRelativeFrame(.horizontal)
                            .id(phase)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selection)
            .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 0) {
                ForEach(MeiPhase.allCases) { phase in
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                            selection = phase
                        }
                    } label: {
                        Capsule()
                            .fill(current == phase ? MeiPalette.teal : MeiPalette.text.opacity(0.18))
                            .frame(width: current == phase ? 22 : 7, height: 7)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(phase.title)
                    .accessibilityAddTraits(current == phase ? [.isSelected] : [])

                    if phase == .telophaseI {
                        Rectangle()
                            .fill(MeiPalette.text.opacity(0.2))
                            .frame(width: 1, height: 14)
                            .padding(.horizontal, 4)
                            .accessibilityHidden(true)
                    }
                }
            }
            .accessibilityLabel("Choose a meiosis phase")
        }
    }
}

private struct MeiPhaseCard: View {
    let phase: MeiPhase
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(phase.title)
                    .font(.system(.title, design: .serif, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                Text("\(phase.rawValue + 1) / \(MeiPhase.allCases.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MeiPalette.ink.opacity(0.72))
                    .fixedSize()
            }

            MeiPhaseArt(phase: phase)
                .modifier(MeiSpecimenMotion(amount: 0.45))
                .aspectRatio(340.0 / 190.0, contentMode: .fit)
                .accessibilityHidden(true)

            DisclosureGroup(isExpanded: $expanded) {
                MeiBulletList(text: phase.explanation, color: phase.tint,
                              textColor: MeiPalette.ink.opacity(0.85))
                    .padding(12)
                    .background(.white.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 4)
            } label: {
                Text(phase.cue)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .tint(MeiPalette.ink)

            Text("2 pairs shown · human cells start with 23 pairs")
                .font(.caption2)
                .foregroundStyle(MeiPalette.ink.opacity(0.72))
        }
        .foregroundStyle(MeiPalette.ink)
        .padding(16)
        .background(phase.cardColor, in: RoundedRectangle(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .stroke(MeiPalette.ink.opacity(0.75), lineWidth: 1.5)
        }
    }
}

struct MeiPhaseArt: View {
    let phase: MeiPhase

    var body: some View {
        Canvas { context, size in
            MeiDrawing.fit(&context, size: size, width: 340, height: 190)
            MeiDrawing.phase(phase, in: &context)
        }
    }
}

// MARK: - Chromosome count journey

private struct MeiCountJourney: View {
    let showDetails: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Button(action: showDetails) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Explain chromosome counts")
            }

            ForEach(0..<3, id: \.self) { stage in
                if stage > 0 {
                    HStack(spacing: 12) {
                        Rectangle().frame(height: 1).opacity(0.15)
                        Label(stage == 1 ? "MEIOSIS I" : "MEIOSIS II", systemImage: "arrow.down")
                            .font(.system(.caption2, design: .serif, weight: .bold))
                            .fixedSize()
                        Rectangle().frame(height: 1).opacity(0.15)
                    }
                }
                MeiCountRow(stage: stage)
            }

            Text("Symbols show counts; chromosomes uncoil at the finish.")
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(MeiPalette.ink)
        .padding(16)
        .background(MeiPalette.mint, in: RoundedRectangle(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .stroke(MeiPalette.ink.opacity(0.75), lineWidth: 1.5)
        }
    }
}

private struct MeiCountRow: View {
    let stage: Int

    var body: some View {
        VStack(spacing: 7) {
            Text(["START · 1 DIPLOID CELL (2n)", "AFTER I · 2 HAPLOID CELLS (n)",
                  "FINISH · 4 HAPLOID PRODUCTS (n)"][stage])
                .font(.system(.caption, design: .serif, weight: .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.white.opacity(0.55), in: Capsule())
                .frame(maxWidth: .infinity, alignment: .leading)

            MeiCountArt(stage: stage)
                .aspectRatio(340.0 / 160.0, contentMode: .fit)
                .accessibilityHidden(true)

            HStack(alignment: .top, spacing: 8) {
                VStack(spacing: 3) {
                    Text(stage == 0 ? "46 chromosomes" : "23 chromosomes each").fontWeight(.bold)
                    Text(stage == 0 ? "23 pairs · 92 chromatids"
                         : stage == 1 ? "1 set · 46 chromatids each" : "1 set · 23 chromatids each")
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 3) {
                    Text(stage == 0 ? "1 homologous pair" : "1 chromosome").fontWeight(.bold)
                    Text(stage == 0 ? "2 chromosomes · 4 chromatids"
                         : stage == 1 ? "2 sister chromatids" : "1 chromatid")
                }
                .frame(maxWidth: .infinity)
            }
            .font(.system(.caption, design: .rounded))
            .multilineTextAlignment(.center)
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
            MeiDrawing.fit(&context, size: size, width: 340, height: 160)
            let count = stage == 0 ? 1 : stage == 1 ? 2 : 4
            let radius: CGFloat = stage == 0 ? 62 : stage == 1 ? 39 : 33
            var selected = CGPoint.zero
            var highlighted: [CGPoint] = []

            for cell in 0..<count {
                let center: CGPoint
                if stage == 0 {
                    center = CGPoint(x: 78, y: 78)
                } else if stage == 1 {
                    center = CGPoint(x: cell == 0 ? 45 : 114, y: cell == 0 ? 42 : 118)
                } else {
                    center = CGPoint(x: cell % 2 == 0 ? 41 : 115, y: cell < 2 ? 40 : 116)
                }
                context.draw(context.resolve(Image("CellLabNucleus")), in: CGRect(
                    x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2
                ))

                let total = stage == 0 ? 46 : 23
                for index in 0..<total {
                    let angle = CGFloat(index) * 2.39996323
                    let distance = radius * 0.76 * sqrt((CGFloat(index) + 0.5) / CGFloat(total))
                    let point = CGPoint(x: center.x + cos(angle) * distance,
                                        y: center.y + sin(angle) * distance)
                    let parent = stage == 0 ? index % 2 : (index + cell) % 2
                    let recombinant = index == 0 && (stage == 1 || (stage == 2 && (cell == 1 || cell == 2)))
                    MeiDrawing.chromosome(&context, at: point, length: radius * 0.13,
                                          parent: parent, replicated: stage < 2,
                                          swapped: recombinant, swappedSister: cell % 2 == 0 ? 1 : 0)
                    if cell == count - 1 && index == 0 { selected = point }
                    if cell == count - 1 && (index == 0 || (stage == 0 && index == 1)) {
                        highlighted.append(point)
                    }
                }
            }

            let lens = CGPoint(x: 263, y: 76)
            for (index, offset) in [CGFloat(-23), CGFloat(23)].enumerated() {
                let origin = stage == 0 ? highlighted[index] : selected
                var line = Path()
                line.move(to: origin)
                line.addLine(to: CGPoint(x: lens.x - 55, y: lens.y + offset))
                context.stroke(line, with: .color(MeiPalette.purple.opacity(0.65)),
                               style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            }
            for point in highlighted {
                context.stroke(Path(ellipseIn: CGRect(x: point.x - 6, y: point.y - 6,
                                                      width: 12, height: 12)),
                               with: .color(MeiPalette.gold), lineWidth: 2)
            }

            context.draw(context.resolve(Image("CellLabMagnifier")),
                         in: CGRect(x: 200, y: 13, width: 147, height: 147))
            if stage == 0 {
                MeiDrawing.chromosome(&context, at: CGPoint(x: 242, y: 76), length: 59, parent: 0)
                MeiDrawing.chromosome(&context, at: CGPoint(x: 283, y: 76), length: 59, parent: 1)
            } else {
                MeiDrawing.chromosome(&context, at: lens, length: 78, parent: 1,
                                      replicated: stage == 1, swapped: stage == 1, swappedSister: 0)
            }
        }
    }
}

// MARK: - Reference sheets

private enum MeiDetail: Identifiable {
    case phase(MeiPhase), counts, terms

    var id: String {
        switch self {
        case .phase(let phase): "phase-\(phase.id)"
        case .counts: "counts"
        case .terms: "terms"
        }
    }

    var title: String {
        switch self {
        case .phase(let phase): phase.title
        case .counts: "Count chromosomes, not arms."
        case .terms: "Meet the key players"
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
                    Text(active.title)
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                        .accessibilityAddTraits(.isHeader)
                    content
                }
                .padding(22)
                .frame(maxWidth: 660)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(MeiPalette.paper.ignoresSafeArea())
            .foregroundStyle(MeiPalette.text)
            .tint(MeiPalette.teal)
            .navigationTitle("Meiosis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch active {
        case .phase(let phase):
            MeiPhaseArt(phase: phase)
                .modifier(MeiSpecimenMotion(amount: 0.45))
                .aspectRatio(340.0 / 220.0, contentMode: .fit)
                .padding(12)
                .background(phase.cardColor, in: RoundedRectangle(cornerRadius: 26))
                .overlay {
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(MeiPalette.ink.opacity(0.7), lineWidth: 1.5)
                }
                .accessibilityLabel("\(phase.cue) Simplified model showing two homologous pairs; human cells start with 23 pairs.")

            Text(phase.cue)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            DisclosureGroup("A little more biology") {
                MeiBulletList(text: phase.explanation, color: phase.tint)
                    .padding(.top, 10)
            }
            .padding(18)
            .background(phase.tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 20))
            .id(phase.id)

            HStack {
                Button {
                    phaseOverride = MeiPhase(rawValue: phase.rawValue - 1)
                } label: {
                    Label("Back", systemImage: "arrow.left")
                }
                .disabled(phase == .prophaseI)

                Spacer()
                if phase != .telophaseII {
                    Button {
                        phaseOverride = MeiPhase(rawValue: phase.rawValue + 1)
                    } label: {
                        Label("Next phase", systemImage: "arrow.right")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                } else {
                    Button("Done exploring") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                }
            }

        case .counts:
            MeiCountDetail()

        case .terms:
            MeiosisKeyPlayersView()
        }
    }
}

private struct MeiCountDetail: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Before meiosis, a diploid germ-cell precursor grows and copies its DNA during S phase of interphase.")
                    MeiCountArt(stage: 0)
                        .aspectRatio(340.0 / 160.0, contentMode: .fit)
                        .accessibilityHidden(true)
                    MeiNote(text: "46 chromosomes → 46 replicated chromosomes\n46 chromatids → 92 chromatids")
                    Text("Each chromosome now has two sister chromatids joined at a centromere. Centrosomes also duplicate, and the cell makes proteins needed for division.")
                    Text("DNA replication doubles the DNA amount—not the chromosome count.")
                        .font(.headline)
                }
                .padding(.top, 12)
            } label: {
                Text("Copy once. Divide twice.")
                    .font(.system(.headline, design: .rounded))
            }
            .padding(16)
            .background(MeiPalette.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))

            ForEach(0..<3, id: \.self) { stage in
                VStack(alignment: .leading, spacing: 8) {
                    Text(["Start · diploid (2n)", "After I · haploid (n)", "After II · haploid (n)"][stage])
                        .font(.system(.headline, design: .rounded))
                    Text(["1 cell: 46 chromosomes, 92 chromatids.",
                          "2 cells: each has 23 chromosomes, 46 chromatids.",
                          "4 products: each has 23 chromosomes, 23 chromatids."][stage])
                }
            }

            MeiNote(text: "23 pairs = 46 chromosomes.\nOne haploid set = 23 chromosomes, not 23 pairs.")
            Text("A replicated chromosome counts as one while its sisters remain joined. In anaphase II, sisters become separate chromosomes: briefly 46 chromosomes in each still-dividing cell, with 23 moving to each pole.")

            DisclosureGroup("A pause—not a copy round.") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Some species have a brief interval called interkinesis between meiosis I and II. Chromosomes may relax, but there is no S phase and no DNA replication.")
                    MeiNote(text: "Already haploid. Still two chromatids per chromosome.")
                }
                .padding(.top, 12)
            }
            .padding(16)
            .background(MeiPalette.teal.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))

            Text("The four-product model shows chromosome segregation. In sperm formation, the four products can develop into sperm. In egg formation, unequal cytoplasm division produces one large egg and small polar bodies; four functional eggs are not produced.")
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("Meiosis • Light") {
    NavigationStack { MeiosisView() }
        .preferredColorScheme(.light)
}

#Preview("Meiosis • Dark") {
    NavigationStack { MeiosisView() }
        .preferredColorScheme(.dark)
}
