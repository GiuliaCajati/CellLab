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
                diversity
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
                Button("Notes & video") { detail = .sources }
                    .font(.caption).padding(.bottom, 8)
            }
            .padding(18).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }
        .background((scheme == .dark ? Color(red: 0.07, green: 0.12, blue: 0.16) : Color(red: 0.96, green: 0.97, blue: 1)).ignoresSafeArea())
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .sheet(item: $detail) { MeiDetailSheet(detail: $0) }
    }

    private var diversity: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Where the mix happens")
                .font(.system(.title2, design: .rounded, weight: .heavy))
            diversityButton("Crossing over", subtitle: "Swap DNA · prophase I", icon: "arrow.triangle.swap", color: MeiPalette.rose, target: .crossing)
            diversityButton("Independent assortment", subtitle: "Shuffle pairs · metaphase I", icon: "shuffle", color: MeiPalette.teal, target: .assortment)
            diversityButton("Random fertilization", subtitle: "Combine gametes · after meiosis", icon: "plus.circle.fill", color: MeiPalette.purple, target: .fertilization)
        }
    }

    private func diversityButton(_ title: String, subtitle: String, icon: String, color: Color, target: MeiDetail) -> some View {
        Button { detail = target } label: {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.title2).foregroundStyle(color).frame(width: 38)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(.subheadline, design: .rounded, weight: .bold))
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.secondary)
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.09), in: RoundedRectangle(cornerRadius: 20))
        }.buttonStyle(.plain)
    }
}

private enum MeiPalette {
    static let purple = Color(red: 0.47, green: 0.32, blue: 0.80)
    static let rose = Color(red: 0.86, green: 0.24, blue: 0.48)
    static let teal = Color(red: 0.04, green: 0.57, blue: 0.57)
    static let gold = Color(red: 1, green: 0.75, blue: 0.28)
    static let ink = Color(red: 0.13, green: 0.16, blue: 0.29)
}

private enum MeiPhase: Int, CaseIterable, Identifiable {
    case prophaseI, metaphaseI, anaphaseI, telophaseI
    case prophaseII, metaphaseII, anaphaseII, telophaseII
    var id: Int { rawValue }
    var second: Bool { rawValue >= 4 }
    var title: String {
        ["Prophase I", "Metaphase I", "Anaphase I", "Telophase I", "Prophase II", "Metaphase II", "Anaphase II", "Telophase II"][rawValue]
    }
    var cue: String {
        ["Pair up. Trade a little DNA.", "Pairs line up. Coin-flip energy.", "Homologs part. Sisters stay.", "Two cells. Half the sets.", "Round two. No copying!", "Single file, please.", "Sisters go their own way.", "Four haploid products. New mixes."][rawValue]
    }
    var tint: Color {
        [MeiPalette.rose, MeiPalette.teal, Color.orange, MeiPalette.purple, MeiPalette.purple, MeiPalette.teal, Color.orange, MeiPalette.rose][rawValue]
    }
    var explanation: String {
        switch self {
        case .prophaseI:
            return "Chromosomes condense. Homologs pair (synapsis); non-sister chromatids exchange matching DNA segments at crossover sites marked by chiasmata. This creates new allele combinations. The nuclear envelope breaks down, centrosomes move apart, and the spindle forms."
        case .metaphaseI:
            return "Homologous pairs align at the equator. Spindle fibers attach at kinetochores, connecting homologs to opposite poles. Each pair orients independently—independent assortment."
        case .anaphaseI:
            return "Spindle fibers pull homologs to opposite poles, one from each pair. Sisters stay joined at their centromeres. This division halves the chromosome sets."
        case .telophaseI:
            return "Chromosomes reach the poles; nuclear envelopes may re-form. Cytokinesis produces two haploid cells: each has 23 replicated chromosomes and 46 chromatids. Haploid means one chromosome set."
        case .prophaseII:
            return "Spindles form in both haploid cells. Chromosomes re-condense if needed, and any nuclear envelopes break down. No DNA replication occurs between meiosis I and II."
        case .metaphaseII:
            return "Chromosomes align single-file. Sister kinetochores attach to opposite spindle poles. Each cell has 23 chromosomes, each with two chromatids."
        case .anaphaseII:
            return "Sisters separate at their centromeres and move to opposite poles. Each is now an individual chromosome. Crossing over may have made sisters genetically different."
        case .telophaseII:
            return "Nuclei re-form; chromosomes uncoil. Cytokinesis produces four haploid products, each with 23 single-chromatid chromosomes. In egg formation, unequal divisions produce one large egg and small polar bodies."
        }
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

private enum MeiDrawing {
    /// Parent color is not a sex or gender code. A contrasting tip marks exchanged DNA.
    static func chromosome(_ c: inout GraphicsContext, at point: CGPoint, length: CGFloat = 44,
                           parent: Int, replicated: Bool = true, swapped: Bool = false,
                           swappedSister: Int = 1, face: Bool = true) {
        let base = parent == 0 ? MeiPalette.rose : MeiPalette.teal
        let other = parent == 0 ? MeiPalette.teal : MeiPalette.rose
        let half = length / 2
        let arm: CGFloat = replicated ? length * 0.16 : 0
        let width = max(2, length * 0.14)
        let sisters = replicated ? 2 : 1
        for sister in 0..<sisters {
            let x = point.x + (sister == 0 ? -arm : arm)
            var path = Path()
            path.move(to: CGPoint(x: x, y: point.y - half))
            path.addQuadCurve(to: point, control: CGPoint(x: point.x, y: point.y - half * 0.35))
            path.addQuadCurve(to: CGPoint(x: x, y: point.y + half), control: CGPoint(x: point.x, y: point.y + half * 0.35))
            c.stroke(path, with: .color(base), style: StrokeStyle(lineWidth: width, lineCap: .round))
            if swapped && (!replicated || sister == swappedSister) {
                // Replace the distal part of this same arm, not a second floating segment.
                var tip = Path()
                let t: CGFloat = 0.64
                tip.move(to: CGPoint(x: point.x + (x - point.x) * t * t,
                                     y: point.y + half * (0.7 * t * (1 - t) + t * t)))
                tip.addQuadCurve(to: CGPoint(x: x, y: point.y + half),
                                 control: CGPoint(x: point.x + (x - point.x) * t, y: point.y + half * (0.35 + 0.65 * t)))
                c.stroke(tip, with: .color(other), style: StrokeStyle(lineWidth: width, lineCap: .round))
            }
        }
        c.fill(Path(ellipseIn: CGRect(x: point.x - width, y: point.y - width * 0.48, width: width * 2, height: width * 0.96)), with: .color(MeiPalette.gold))
        if face && length >= 36 {
            for dx in [-width * 0.38, width * 0.38] {
                c.fill(Path(ellipseIn: CGRect(x: point.x + dx - 0.8, y: point.y - 1.2, width: 1.6, height: 2.6)), with: .color(MeiPalette.ink))
            }
        }
    }

    static func cell(_ c: inout GraphicsContext, _ rect: CGRect, nucleus: Bool = false) {
        let path = Path(ellipseIn: rect)
        c.fill(path, with: .color(Color(red: 0.85, green: 0.96, blue: 0.94)))
        c.stroke(path, with: .color(MeiPalette.teal.opacity(0.6)), lineWidth: 2.5)
        if nucleus {
            let inner = Path(ellipseIn: rect.insetBy(dx: rect.width * 0.17, dy: rect.height * 0.13))
            c.fill(inner, with: .color(MeiPalette.purple.opacity(0.08)))
            c.stroke(inner, with: .color(MeiPalette.purple.opacity(0.3)), style: StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
        }
    }

    static func fiber(_ c: inout GraphicsContext, from: CGPoint, to: CGPoint) {
        var path = Path(); path.move(to: from); path.addLine(to: to)
        c.stroke(path, with: .color(MeiPalette.purple.opacity(0.40)), lineWidth: 1.1)
    }

    static func poles(_ c: inout GraphicsContext, left: CGPoint, right: CGPoint) {
        for p in [left, right] {
            for i in 0..<8 {
                let angle = Double(i) * .pi / 4
                fiber(&c, from: p, to: CGPoint(x: p.x + CGFloat(cos(angle)) * 9, y: p.y + CGFloat(sin(angle)) * 9))
            }
            c.fill(Path(ellipseIn: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6)), with: .color(MeiPalette.gold))
        }
    }

    static func phase(_ phase: MeiPhase, in c: inout GraphicsContext) {
        if !phase.second && phase != .telophaseI {
            cell(&c, CGRect(x: 15, y: 8, width: 310, height: 174), nucleus: phase == .prophaseI)
            let left = CGPoint(x: 35, y: 95), right = CGPoint(x: 305, y: 95)
            poles(&c, left: left, right: right)
            for pair in 0..<2 {
                let y: CGFloat = pair == 0 ? 60 : 130
                let length: CGFloat = pair == 0 ? 48 : 34
                for homolog in 0..<2 {
                    let x: CGFloat = phase == .anaphaseI ? (homolog == 0 ? 85 : 255) : (homolog == 0 ? 152 : 188)
                    // Opposite orientation of the short pair illustrates independent assortment.
                    let parent = pair == 0 ? homolog : 1 - homolog
                    let point = CGPoint(x: x, y: y)
                    if phase != .prophaseI { fiber(&c, from: homolog == 0 ? left : right, to: point) }
                    chromosome(&c, at: point, length: length, parent: parent, swapped: pair == 0, swappedSister: homolog == 0 ? 1 : 0)
                }
            }
            if phase == .prophaseI {
                var bridge = Path(); bridge.move(to: CGPoint(x: 159, y: 76)); bridge.addLine(to: CGPoint(x: 181, y: 76))
                c.stroke(bridge, with: .color(MeiPalette.gold), style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
            }
        } else if phase == .telophaseII {
            for product in 0..<4 {
                let cx: CGFloat = product % 2 == 0 ? 85 : 255
                let cy: CGFloat = product < 2 ? 48 : 142
                cell(&c, CGRect(x: cx - 70, y: cy - 43, width: 140, height: 86), nucleus: true)
                let firstCell = product % 2 == 0
                chromosome(&c, at: CGPoint(x: cx - 20, y: cy), length: 35, parent: firstCell ? 0 : 1, replicated: false, swapped: firstCell ? product >= 2 : product < 2)
                chromosome(&c, at: CGPoint(x: cx + 20, y: cy), length: 25, parent: firstCell ? 1 : 0, replicated: false)
            }
        } else {
            for daughter in 0..<2 {
                let cx: CGFloat = daughter == 0 ? 85 : 255
                cell(&c, CGRect(x: cx - 77, y: 12, width: 154, height: 166), nucleus: phase == .telophaseI || phase == .prophaseII)
                let left = CGPoint(x: cx - 64, y: 95), right = CGPoint(x: cx + 64, y: 95)
                if phase != .telophaseI { poles(&c, left: left, right: right) }
                for pair in 0..<2 {
                    let y: CGFloat = pair == 0 ? 62 : 128
                    let length: CGFloat = pair == 0 ? 40 : 28
                    let parent = pair == 0 ? daughter : 1 - daughter
                    if phase == .anaphaseII {
                        for sister in 0..<2 {
                            let p = CGPoint(x: cx + (sister == 0 ? -37 : 37), y: y)
                            fiber(&c, from: sister == 0 ? left : right, to: p)
                            chromosome(&c, at: p, length: length, parent: parent, replicated: false,
                                       swapped: pair == 0 && sister == (daughter == 0 ? 1 : 0))
                        }
                    } else {
                        let p = CGPoint(x: cx, y: y)
                        if phase == .metaphaseII {
                            fiber(&c, from: left, to: CGPoint(x: cx - 3, y: y))
                            fiber(&c, from: right, to: CGPoint(x: cx + 3, y: y))
                        }
                        chromosome(&c, at: p, length: length, parent: parent, swapped: pair == 0, swappedSister: daughter == 0 ? 1 : 0)
                    }
                }
            }
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
                Text(["START · 1 DIPLOID CELL", "AFTER I · 2 HAPLOID CELLS", "FINISH · 4 HAPLOID PRODUCTS"][stage])
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
    case phase(MeiPhase), preparation, interkinesis, counts, crossing, assortment, fertilization, terms, sources
    var id: String {
        switch self {
        case .phase(let phase): return "phase-\(phase.id)"
        case .preparation: return "preparation"
        case .interkinesis: return "interkinesis"
        case .counts: return "counts"
        case .crossing: return "crossing"
        case .assortment: return "assortment"
        case .fertilization: return "fertilization"
        case .terms: return "terms"
        case .sources: return "sources"
        }
    }
    var title: String {
        switch self {
        case .phase(let phase): return phase.title
        case .preparation: return "Copy once. Divide twice."
        case .interkinesis: return "A pause—not a copy round."
        case .counts: return "Count chromosomes, not arms."
        case .crossing: return "A fair DNA swap."
        case .assortment: return "Every pair gets a coin flip."
        case .fertilization: return "Two gametes. One new mix."
        case .terms: return "Meet the key players"
        case .sources: return "Notes & video"
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
        case .crossing:
            MeiCrossingDemo()
            Text("In prophase I, homologs align gene by gene (synapsis). Corresponding DNA segments are exchanged between non-sister chromatids. Chiasmata are the visible crossover connections.")
            note("One crossover involves two of the four chromatids: two recombinant chromatids and two unchanged parental chromatids in this example.")
            Text("Sisters start as identical copies. After crossing over, they can carry different allele combinations. A crossover does not guarantee that all four products are genetically distinct in every possible case.")
        case .assortment:
            MeiAssortmentDemo()
            Text("Each homologous pair faces the poles independently at metaphase I. A maternal homolog of one pair can travel with a paternal homolog of another.")
            note("2ⁿ combinations · n = chromosome pairs\nHumans: 2²³ = 8,388,608")
            Text("That is the number of possible maternal/paternal chromosome combinations across many meioses, before counting crossing over—not millions of products from one division.")
        case .fertilization:
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
        case .terms:
            ForEach(MeiTerm.all) { term in
                DisclosureGroup {
                    Text(term.definition).padding(.top, 8).frame(maxWidth: .infinity, alignment: .leading)
                } label: { Text(term.name).font(.system(.headline, design: .rounded)) }
                .padding(14).background(MeiPalette.purple.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
            }
        case .sources:
            Text("Based on the McGraw-Hill course notes supplied for this project. Wording is condensed for learning; the original numbered source markers were not complete references.")
            Link(destination: URL(string: "https://www.youtube.com/watch?v=I-sucvMV0Ng")!) {
                Label("Open supplied meiosis video", systemImage: "play.rectangle.fill")
            }
            Text("The linked video’s contents were not retrievable when this view was created. It is provided as a companion reference.").font(.caption).foregroundStyle(.secondary)
            Text("Model notes").font(.headline)
            Text("Human animal-cell counts are used. Phase drawings show two homologous pairs; count diagrams show all 46 or 23 chromosomes. Colors track chromosome origin and exchanged segments, not sex or gender. Chromosome shapes are schematic, and condensed symbols at the finish clarify counts rather than depicting decondensed chromatin.")
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

private struct MeiCrossingDemo: View {
    @State private var swapped = false
    var body: some View {
        VStack(spacing: 14) {
            Canvas { context, size in
                let scale = min(size.width / 300, size.height / 170)
                context.translateBy(x: (size.width - 300 * scale) / 2, y: (size.height - 170 * scale) / 2)
                context.scaleBy(x: scale, y: scale)
                MeiDrawing.chromosome(&context, at: CGPoint(x: 110, y: 80), length: 120, parent: 0, swapped: swapped, swappedSister: 1)
                MeiDrawing.chromosome(&context, at: CGPoint(x: 190, y: 80), length: 120, parent: 1, swapped: swapped, swappedSister: 0)
            }.frame(height: 190).accessibilityHidden(true)
            Text(swapped ? "Two chromatids traded matching segments." : "One homologous pair. Four chromatids.")
                .font(.system(.subheadline, design: .rounded, weight: .bold)).multilineTextAlignment(.center)
            Button(swapped ? "Reset the swap" : "Swap DNA segments") { swapped.toggle() }
                .buttonStyle(.borderedProminent).tint(MeiPalette.rose)
            Text("Rose + teal = different parental origins").font(.caption).foregroundStyle(.secondary)
        }.padding(16).frame(maxWidth: .infinity)
            .background(MeiPalette.rose.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
    }
}

private struct MeiAssortmentDemo: View {
    @State private var flipLong = false
    @State private var flipShort = false
    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Label("Pole A", systemImage: "arrow.left")
                Spacer()
                Label("Pole B", systemImage: "arrow.right")
            }.font(.caption.bold())
            Canvas { context, size in
                let scale = min(size.width / 300, size.height / 175)
                context.translateBy(x: (size.width - 300 * scale) / 2, y: (size.height - 175 * scale) / 2)
                context.scaleBy(x: scale, y: scale)
                for pair in 0..<2 {
                    let flip = pair == 0 ? flipLong : flipShort
                    for side in 0..<2 {
                        MeiDrawing.chromosome(&context, at: CGPoint(x: side == 0 ? 120 : 180, y: pair == 0 ? 48 : 128),
                                              length: pair == 0 ? 60 : 40, parent: flip ? 1 - side : side)
                    }
                }
            }.frame(height: 175).accessibilityHidden(true)
            HStack {
                Button("Flip long pair") { flipLong.toggle() }
                Button("Flip short pair") { flipShort.toggle() }
            }.buttonStyle(.bordered).tint(MeiPalette.teal)
            Text("Pole A: \(flipLong ? "teal" : "rose") long + \(flipShort ? "teal" : "rose") short")
                .font(.caption.bold()).accessibilityAddTraits(.updatesFrequently)
            Text("2 pairs → 2² = 4 possible combinations")
                .font(.system(.subheadline, design: .rounded, weight: .bold)).multilineTextAlignment(.center)
        }.padding(16).background(MeiPalette.teal.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
    }
}

private struct MeiTerm: Identifiable {
    let name: String
    let definition: String
    var id: String { name }
    static let all: [MeiTerm] = [
        .init(name: "Meiosis I vs. meiosis II", definition: "Meiosis I is reduction division: homologous chromosomes separate, reducing two chromosome sets to one. Meiosis II is equational division: sister chromatids separate while each final product retains one chromosome set."),
        .init(name: "Diploid · 2n", definition: "Two chromosome sets, one inherited from each biological parent. In humans, 2n = 46 chromosomes, arranged as 23 pairs."),
        .init(name: "Haploid · n", definition: "One chromosome set. Human gametes have n = 23 chromosomes. A cell can be haploid while its chromosomes still have two chromatids, as after meiosis I."),
        .init(name: "Somatic vs. germ cells", definition: "Somatic cells are body cells; mitosis supports growth and repair. Germ-line cells give rise to gametes. In animals, specialized diploid precursors in ovaries or testes enter meiosis; not every germ-line cell is always undergoing meiosis."),
        .init(name: "Homologous chromosomes", definition: "The two members of a chromosome pair, with corresponding genes at corresponding locations. They can carry the same or different alleles. One came from each parent. Human X and Y chromosomes are a special case: they share only limited homologous regions."),
        .init(name: "Allele", definition: "A version of a gene. Homologs have corresponding gene locations, but the versions at those locations may differ."),
        .init(name: "Sister chromatids", definition: "The two copies of a replicated chromosome, initially identical and joined at a centromere. Crossing over can make sister chromatids genetically different."),
        .init(name: "Centromere & kinetochore", definition: "The centromere is the chromosome region where sisters are joined. A kinetochore is a protein complex assembled there that binds spindle microtubules."),
        .init(name: "Spindle fibers & centrosomes", definition: "Spindle fibers are microtubules that move chromosomes through kinetochore attachments. Centrosomes organize the animal-cell spindle and move toward opposite poles."),
        .init(name: "Synapsis & tetrad", definition: "Synapsis is the close alignment of homologs during prophase I. Two replicated homologs together contain four chromatids, called a tetrad."),
        .init(name: "Chiasma · plural chiasmata", definition: "A visible connection between homologs at a crossover site involving non-sister chromatids."),
        .init(name: "Recombinant vs. parental", definition: "Recombinant chromatids contain new mixtures of parental alleles following crossing over. Parental chromatids retain their original allele arrangement."),
        .init(name: "Independent assortment", definition: "Each homologous pair orients independently at metaphase I, creating different combinations of maternal and paternal chromosomes in meiotic products."),
        .init(name: "Interkinesis", definition: "An interval between meiosis I and II in many species. No DNA replication occurs."),
        .init(name: "Cytokinesis", definition: "Division of the cytoplasm. In animal cells, a contractile ring produces a cleavage furrow. Nuclear division and cytoplasm division are distinct processes."),
        .init(name: "Karyotype", definition: "An ordered display of chromosomes grouped by size and other features. A typical human diploid karyotype shows 22 autosome pairs and one sex-chromosome pair, commonly XX or XY—not always XY."),
        .init(name: "Gamete & fertilization", definition: "A gamete is a haploid reproductive cell, such as an egg or sperm. Fertilization combines two gametes to form a diploid zygote. It occurs after meiosis.")
    ]
}

#Preview("Meiosis · Light") {
    NavigationStack { MeiosisView() }.preferredColorScheme(.light)
}

#Preview("Meiosis · Dark") {
    NavigationStack { MeiosisView() }.preferredColorScheme(.dark)
}

