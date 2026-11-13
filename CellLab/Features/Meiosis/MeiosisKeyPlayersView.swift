//
//  MeiosisKeyPlayersView.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/13/26.
//
import SwiftUI

struct MeiTerm: Identifiable {
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

struct MeiCrossingDemo: View {
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

struct MeiAssortmentDemo: View {
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

enum MeiDrawing {
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

enum MeiPhase: Int, CaseIterable, Identifiable {
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
            return """
            • Chromosomes condense into visible chromosomes, each with two sister chromatids joined at a centromere.
            • Synapsis: Homologous chromosomes pair, forming tetrads (four chromatids).
            • Crossing over: Non-sister chromatids exchange matching DNA segments at chiasmata (crossover points).
            • Genetic variation: New allele combinations are created.
            • Nuclear envelope breaks down, centrosomes move apart, and the spindle forms.
            """

        case .metaphaseI:
            return """
            • Homologous chromosome pairs (tetrads) align at the cell equator.
            • Spindle fibers attach to kinetochores on homologous chromosomes.
            • Each pair orients independently, called independent assortment, creating genetic variation.
            """

        case .anaphaseI:
            return """
            • Spindle fibers pull homologous chromosomes to opposite poles.
            • Sister chromatids remain joined at their centromeres.
            • Homologs separate, reducing the chromosome sets by half.
            """

        case .telophaseI:
            return """
            • Homologous chromosomes reach opposite poles; nuclear envelopes may re-form.
            • Cytokinesis divides the cell into two haploid cells.
            • Each cell has 23 replicated chromosomes (46 chromatids).
            • Haploid means one set of chromosomes.
            """

        case .prophaseII:
            return """
            • Spindles form in both haploid cells.
            • Chromosomes re-condense if needed, and nuclear envelopes break down.
            • No DNA replication occurs between meiosis I and meiosis II.
            """

        case .metaphaseII:
            return """
            • Chromosomes align single-file at the cell equator.
            • Spindle fibers attach to sister kinetochores from opposite poles.
            • Each cell has 23 chromosomes, each containing two sister chromatids.
            """

        case .anaphaseII:
            return """
            • Centromeres divide, and sister chromatids separate toward opposite poles.
            • Each separated chromatid is now an individual chromosome.
            • Crossing over may make sister chromatids genetically different.
            """

        case .telophaseII:
            return """
            • Nuclear envelopes re-form, and chromosomes uncoil.
            • Cytokinesis produces four haploid cells, each with 23 single-chromatid chromosomes.
            • In egg formation (oogenesis), unequal cytokinesis produces one large egg and small polar bodies.
            """
        }
    }
}

enum MeiPalette {
    static let purple = Color(red: 0.47, green: 0.32, blue: 0.80)
    static let rose = Color(red: 0.86, green: 0.24, blue: 0.48)
    static let teal = Color(red: 0.04, green: 0.57, blue: 0.57)
    static let gold = Color(red: 1, green: 0.75, blue: 0.28)
    static let ink = Color(red: 0.13, green: 0.16, blue: 0.29)
}
