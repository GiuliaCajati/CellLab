//
//  MeiosisKeyPlayersView.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/13/26.
//
//
import SwiftUI
import UIKit

struct MeiosisKeyPlayersView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedPlayer: String? = MeiCrewPage.all.first?.id

    private let pages = MeiCrewPage.all
    private var selectedIndex: Int {
        pages.firstIndex { $0.id == selectedPlayer } ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(pages) { page in
                        MeiPlayerCard(page: page)
                            .containerRelativeFrame(.horizontal)
                            .id(page.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selectedPlayer)
            .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button { move(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .disabled(selectedIndex == 0)
                .accessibilityLabel("Previous player")

                Text("\(selectedIndex + 1) / \(pages.count)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .accessibilityLabel("Player \(selectedIndex + 1) of \(pages.count)")

                Button { move(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .disabled(selectedIndex == pages.count - 1)
                .accessibilityLabel("Next player")
            }
            .buttonStyle(.plain)
            .foregroundStyle(MeiPalette.teal)
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }

    private func move(by offset: Int) {
        let index = selectedIndex + offset
        guard pages.indices.contains(index) else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
            selectedPlayer = pages[index].id
        }
    }
}

private enum MeiCrewPage: Identifiable {
    case crossing, assortment, fertilization, term(Int)

    static let all: [MeiCrewPage] = [.crossing, .assortment, .fertilization]
        + MeiTerm.all.indices.map { .term($0) }

    var id: String {
        switch self {
        case .crossing: "crossing"
        case .assortment: "assortment"
        case .fertilization: "fertilization"
        case .term(let index): MeiTerm.all[index].id
        }
    }

    var title: String {
        switch self {
        case .crossing: "Crossing over"
        case .assortment: "Independent assortment"
        case .fertilization: "Random fertilization"
        case .term(let index): MeiTerm.all[index].name
        }
    }

    var color: Color {
        switch self {
        case .crossing: MeiPalette.rose
        case .assortment: MeiPalette.teal
        case .fertilization: MeiPalette.purple
        case .term(let index):
            [Color.blue, .orange, .green, .red, .purple, .cyan][index % 6]
        }
    }
}

private struct MeiPlayerCard: View {
    let page: MeiCrewPage

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            illustration
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(page.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))

            Text(page.title)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            switch page {
            case .crossing:
                MeiBulletList(text: "In prophase I, homologs align gene by gene (synapsis). Corresponding DNA segments are exchanged between non-sister chromatids. Chiasmata are the visible crossover connections.", color: page.color)
                MeiNote(text: "One crossover involves two of the four chromatids: two recombinant chromatids and two unchanged parental chromatids in this example.")
                MeiBulletList(text: "Sisters start as identical copies. After crossing over, they can carry different allele combinations. A crossover does not guarantee that all four products are genetically distinct in every possible case.", color: page.color)

            case .assortment:
                MeiBulletList(text: "Each homologous pair faces the poles independently at metaphase I. A maternal homolog of one pair can travel with a paternal homolog of another.", color: page.color)
                MeiNote(text: "2ⁿ combinations · n = chromosome pairs\nHumans: 2²³ = 8,388,608")
                MeiBulletList(text: "That is the number of possible maternal/paternal chromosome combinations across many meioses, before counting crossing over—not millions of products from one division.", color: page.color)

            case .fertilization:
                MeiBulletList(text: "Fertilization happens after meiosis. Any one egg can combine with any one sperm, restoring the diploid chromosome number.", color: page.color)
                MeiNote(text: "8,388,608 × 8,388,608\n= 70,368,744,177,664 combinations")
                MeiBulletList(text: "Over 70 trillion possible chromosome combinations for a couple—even before adding crossing over.", color: page.color)

            case .term(let index):
                MeiBulletList(text: MeiTerm.all[index].definition, color: page.color)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .stroke(page.color.opacity(0.20), lineWidth: 1)
        }
    }

    @ViewBuilder private var illustration: some View {
        switch page {
        case .crossing:
            MeiCrossingDemo()
        case .assortment:
            MeiAssortmentDemo()
        case .fertilization:
            MeiFertilizationArt()
                .aspectRatio(1, contentMode: .fit)
        case .term(let index):
            MeiTermIllustration(name: MeiTerm.all[index].name)
                .aspectRatio(1, contentMode: .fit)
                .accessibilityHidden(true)
        }
    }
}

struct MeiBulletList: View {
    let text: String
    let color: Color
    var textColor: Color = .secondary

    private var points: [String] {
        if text.contains("\n") {
            return text.split(separator: "\n").map {
                let line = $0.trimmingCharacters(in: .whitespaces)
                return line.hasPrefix("• ") ? String(line.dropFirst(2)) : line
            }
        }
        let sentences = text.components(separatedBy: ". ")
        return sentences.enumerated().map { index, sentence in
            index < sentences.count - 1 ? sentence + "." : sentence
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("•")
                        .font(.body.weight(.bold))
                        .foregroundStyle(color)
                        .accessibilityHidden(true)
                    Text(point)
                        .font(.subheadline)
                        .foregroundStyle(textColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct MeiNote: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(MeiPalette.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(MeiPalette.butter, in: RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Interactive illustrations

struct MeiCrossingDemo: View {
    @State private var swapped = false

    var body: some View {
        VStack(spacing: 14) {
            Canvas { context, size in
                MeiDrawing.fit(&context, size: size, width: 300, height: 170)
                MeiDrawing.chromosome(&context, at: CGPoint(x: 110, y: 80), length: 120,
                                      parent: 0, swapped: swapped, swappedSister: 1)
                MeiDrawing.chromosome(&context, at: CGPoint(x: 190, y: 80), length: 120,
                                      parent: 1, swapped: swapped, swappedSister: 0)
            }
            .aspectRatio(300.0 / 170.0, contentMode: .fit)
            .accessibilityHidden(true)

            Text(swapped ? "Two chromatids traded matching segments." : "One homologous pair. Four chromatids.")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.updatesFrequently)

            Button(swapped ? "Reset the swap" : "Swap DNA segments") { swapped.toggle() }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(MeiPalette.rose)

            Text("Pink + blue = different parental origins")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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
            }
            .font(.caption.bold())

            Canvas { context, size in
                MeiDrawing.fit(&context, size: size, width: 300, height: 175)
                for pair in 0..<2 {
                    let flip = pair == 0 ? flipLong : flipShort
                    for side in 0..<2 {
                        MeiDrawing.chromosome(&context,
                                              at: CGPoint(x: side == 0 ? 120 : 180, y: pair == 0 ? 48 : 128),
                                              length: pair == 0 ? 60 : 40,
                                              parent: flip ? 1 - side : side)
                    }
                }
            }
            .aspectRatio(300.0 / 175.0, contentMode: .fit)
            .accessibilityHidden(true)

            HStack {
                Button("Flip long pair") { flipLong.toggle() }
                Button("Flip short pair") { flipShort.toggle() }
            }
            .buttonStyle(.bordered)
            .tint(MeiPalette.teal)

            Text("Pole A: \(flipLong ? "blue" : "pink") long + \(flipShort ? "blue" : "pink") short")
                .font(.caption.bold())
                .accessibilityAddTraits(.updatesFrequently)
            Text("2 pairs → 2² = 4 possible combinations")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
        }
    }
}

private struct MeiFertilizationArt: View {
    var body: some View {
        HStack(spacing: 6) {
            badge("23", "egg")
            Text("+").font(.title2.bold())
            badge("23", "sperm")
            Text("=").font(.title2.bold())
            badge("46", "zygote")
        }
        .foregroundStyle(MeiPalette.ink)
        .accessibilityElement(children: .combine)
    }

    private func badge(_ number: String, _ title: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Image("CellLabCellShell").resizable().scaledToFit()
                Text(number)
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .padding(8)
            }
            .aspectRatio(1, contentMode: .fit)
            Text(title).font(.caption)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MeiTermIllustration: View {
    let name: String

    @ViewBuilder var body: some View {
        switch name {
        case "Sister chromatids":
            Image("ChromosomesSisterChromatids").resizable().scaledToFit()
        case "Centromere & kinetochore":
            Image("CentromereKinetochore").resizable().scaledToFit()
        case "Spindle fibers & centrosomes":
            HStack(spacing: 8) {
                Image("SpindleFibers").resizable().scaledToFit()
                Image("CentrosomesCentrioles").resizable().scaledToFit()
            }
        case "Gamete & fertilization":
            MeiFertilizationArt()
        case "Independent assortment":
            MeiPhaseArt(phase: .metaphaseI)
        case "Interkinesis":
            MeiPhaseArt(phase: .telophaseI)
        case "Cytokinesis":
            MeiPhaseArt(phase: .telophaseII)
        case "Meiosis I vs. meiosis II":
            VStack(spacing: 12) {
                HStack {
                    Text("I").frame(maxWidth: .infinity)
                    Text("II").frame(maxWidth: .infinity)
                }
                .font(.system(.title2, design: .serif, weight: .bold))
                .foregroundStyle(MeiPalette.ink)
                HStack(spacing: 8) {
                    MeiPhaseArt(phase: .anaphaseI)
                    MeiPhaseArt(phase: .anaphaseII)
                }
                .aspectRatio(680.0 / 190.0, contentMode: .fit)
            }
        default:
            Canvas { context, size in
                MeiDrawing.fit(&context, size: size, width: 300, height: 190)
                switch name {
                case "Diploid · 2n", "Haploid · n", "Somatic vs. germ cells":
                    let haploid = name == "Haploid · n"
                    MeiDrawing.cell(&context, CGRect(x: 20, y: 10, width: 260, height: 170), nucleus: true)
                    for pair in 0..<2 {
                        for homolog in 0..<(haploid ? 1 : 2) {
                            let x: CGFloat = haploid ? 150 : (homolog == 0 ? 119 : 181)
                            MeiDrawing.chromosome(&context, at: CGPoint(x: x, y: pair == 0 ? 60 : 130),
                                                  length: pair == 0 ? 56 : 38,
                                                  parent: haploid ? pair : homolog)
                        }
                    }

                case "Recombinant vs. parental":
                    for index in 0..<4 {
                        MeiDrawing.chromosome(&context, at: CGPoint(x: 60 + CGFloat(index) * 60, y: 95),
                                              length: 130, parent: index < 2 ? 0 : 1,
                                              replicated: false, swapped: index == 1 || index == 2)
                    }

                case "Karyotype":
                    // A schematic XX example: 23 pairs, 46 replicated chromosomes.
                    for pair in 0..<23 {
                        let x = CGFloat(20 + (pair % 8) * 36)
                        let y = CGFloat(32 + (pair / 8) * 60)
                        let length = 22 - CGFloat(pair % 8) * 0.8
                        MeiDrawing.chromosome(&context, at: CGPoint(x: x - 8, y: y), length: length, parent: 0)
                        MeiDrawing.chromosome(&context, at: CGPoint(x: x + 8, y: y), length: length, parent: 1)
                    }

                default:
                    let exchanged = name == "Chiasma · plural chiasmata"
                    MeiDrawing.chromosome(&context, at: CGPoint(x: 110, y: 95), length: 120,
                                          parent: 0, swapped: exchanged, swappedSister: 1)
                    MeiDrawing.chromosome(&context, at: CGPoint(x: 190, y: 95), length: 120,
                                          parent: 1, swapped: exchanged, swappedSister: 0)
                    if exchanged || name == "Synapsis & tetrad" {
                        var bridge = Path()
                        bridge.move(to: CGPoint(x: 133, y: 128))
                        bridge.addLine(to: CGPoint(x: 167, y: 128))
                        context.stroke(bridge, with: .color(MeiPalette.gold),
                                       style: StrokeStyle(lineWidth: 3, dash: [3, 3]))
                    }
                }
            }
        }
    }
}

// MARK: - Shared Mitosis assets

enum MeiDrawing {
    static func fit(_ context: inout GraphicsContext, size: CGSize, width: CGFloat, height: CGFloat) {
        let scale = min(size.width / width, size.height / height)
        context.translateBy(x: (size.width - width * scale) / 2, y: (size.height - height * scale) / 2)
        context.scaleBy(x: scale, y: scale)
    }

    /// Same chromosome characters as Mitosis. Only one distal arm changes color
    /// in each replicated homolog; the other two chromatids remain parental.
    static func chromosome(_ context: inout GraphicsContext, at point: CGPoint, length: CGFloat = 44,
                           parent: Int, replicated: Bool = true, swapped: Bool = false,
                           swappedSister: Int = 1) {
        let side = length * 840 / 726
        let rect = CGRect(x: point.x - side / 2, y: point.y - side / 2, width: side, height: side)
        let base = replicated
            ? (parent == 0 ? "CellLabPinkReplicated" : "CellLabBlueReplicated")
            : (parent == 0 ? "CellLabPinkSingle" : "CellLabBlueSingle")
        context.draw(context.resolve(Image(base)), in: rect)

        if swapped {
            let other = replicated
                ? (parent == 0 ? "CellLabBlueReplicated" : "CellLabPinkReplicated")
                : (parent == 0 ? "CellLabBlueSingle" : "CellLabPinkSingle")
            var segment = context
            let x = replicated && swappedSister == 1 ? point.x : rect.minX
            let width = replicated ? side / 2 : side
            segment.clip(to: Path(CGRect(x: x, y: rect.minY + side * 0.68,
                                         width: width, height: side * 0.32)))
            segment.draw(context.resolve(Image(other)), in: rect)
        }
    }

    static func cell(_ context: inout GraphicsContext, _ rect: CGRect, nucleus: Bool = false) {
        context.draw(context.resolve(Image("CellLabCellShell")), in: rect)
        if nucleus {
            context.draw(context.resolve(Image("CellLabPhaseNucleus")),
                         in: rect.insetBy(dx: rect.width * 0.17, dy: rect.height * 0.13))
        }
    }

    static func fiber(_ context: inout GraphicsContext, from start: CGPoint, to end: CGPoint) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        var fiber = context
        fiber.opacity = 0.7
        fiber.translateBy(x: start.x, y: start.y)
        fiber.rotate(by: .radians(atan2(dy, dx)))
        fiber.draw(context.resolve(Image("CellLabSpindleFiber")),
                   in: CGRect(x: 0, y: -1.5, width: hypot(dx, dy), height: 3))
    }

    static func poles(_ context: inout GraphicsContext, left: CGPoint, right: CGPoint) {
        for point in [left, right] {
            context.draw(context.resolve(Image("CellLabCentrosome")),
                         in: CGRect(x: point.x - 15, y: point.y - 15, width: 30, height: 30))
            for index in 0..<2 {
                var barrel = context
                barrel.translateBy(x: point.x + (index == 0 ? -2 : 3),
                                   y: point.y + (index == 0 ? -2 : 2))
                barrel.rotate(by: .degrees(index == 0 ? -35 : 55))
                barrel.draw(context.resolve(Image("CellLabCentriole")),
                            in: CGRect(x: -7, y: -9, width: 14, height: 18))
            }
        }
    }

    static func phase(_ phase: MeiPhase, in context: inout GraphicsContext) {
        if !phase.second && phase != .telophaseI {
            cell(&context, CGRect(x: 15, y: 8, width: 310, height: 174), nucleus: phase == .prophaseI)
            let left = CGPoint(x: 35, y: 95)
            let right = CGPoint(x: 305, y: 95)
            poles(&context, left: left, right: right)

            for pair in 0..<2 {
                let y: CGFloat = pair == 0 ? 60 : 130
                let length: CGFloat = pair == 0 ? 48 : 34
                for homolog in 0..<2 {
                    let x: CGFloat = phase == .anaphaseI
                        ? (homolog == 0 ? 85 : 255) : (homolog == 0 ? 152 : 188)
                    let parent = pair == 0 ? homolog : 1 - homolog
                    let point = CGPoint(x: x, y: y)
                    if phase != .prophaseI {
                        fiber(&context, from: homolog == 0 ? left : right, to: point)
                    }
                    chromosome(&context, at: point, length: length, parent: parent,
                               swapped: pair == 0, swappedSister: homolog == 0 ? 1 : 0)
                }
            }
            if phase == .prophaseI {
                var bridge = Path()
                bridge.move(to: CGPoint(x: 159, y: 76))
                bridge.addLine(to: CGPoint(x: 181, y: 76))
                context.stroke(bridge, with: .color(MeiPalette.gold),
                               style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
            }

        } else if phase == .telophaseII {
            for product in 0..<4 {
                let x: CGFloat = product % 2 == 0 ? 85 : 255
                let y: CGFloat = product < 2 ? 48 : 142
                cell(&context, CGRect(x: x - 70, y: y - 43, width: 140, height: 86), nucleus: true)
                let parent = product % 2
                chromatin(&context, at: CGPoint(x: x, y: y - 10), parent: parent,
                          swapped: product == 1 || product == 2)
                chromatin(&context, at: CGPoint(x: x, y: y + 12), parent: 1 - parent, swapped: false)
            }

        } else {
            for daughter in 0..<2 {
                let center: CGFloat = daughter == 0 ? 85 : 255
                cell(&context, CGRect(x: center - 77, y: 12, width: 154, height: 166),
                     nucleus: phase == .telophaseI)
                let left = CGPoint(x: center - 64, y: 95)
                let right = CGPoint(x: center + 64, y: 95)
                if phase != .telophaseI { poles(&context, left: left, right: right) }

                for pair in 0..<2 {
                    let y: CGFloat = pair == 0 ? 62 : 128
                    let length: CGFloat = pair == 0 ? 40 : 28
                    let parent = pair == 0 ? daughter : 1 - daughter
                    if phase == .anaphaseII {
                        for sister in 0..<2 {
                            let point = CGPoint(x: center + (sister == 0 ? -37 : 37), y: y)
                            fiber(&context, from: sister == 0 ? left : right, to: point)
                            chromosome(&context, at: point, length: length, parent: parent,
                                       replicated: false,
                                       swapped: pair == 0 && sister == (daughter == 0 ? 1 : 0))
                        }
                    } else {
                        let point = CGPoint(x: center, y: y)
                        if phase == .metaphaseII {
                            fiber(&context, from: left, to: CGPoint(x: center - 3, y: y))
                            fiber(&context, from: right, to: CGPoint(x: center + 3, y: y))
                        }
                        chromosome(&context, at: point, length: length, parent: parent,
                                   swapped: pair == 0, swappedSister: daughter == 0 ? 1 : 0)
                    }
                }
            }
        }
    }

    private static func chromatin(_ context: inout GraphicsContext, at point: CGPoint,
                                  parent: Int, swapped: Bool) {
        var thread = Path()
        thread.move(to: CGPoint(x: point.x - 27, y: point.y))
        thread.addCurve(to: CGPoint(x: point.x + 27, y: point.y),
                        control1: CGPoint(x: point.x - 8, y: point.y - 17),
                        control2: CGPoint(x: point.x + 8, y: point.y + 17))
        let base = parent == 0 ? MeiPalette.rose : MeiPalette.blue
        let other = parent == 0 ? MeiPalette.blue : MeiPalette.rose
        context.stroke(thread, with: .color(MeiPalette.ink.opacity(0.65)),
                       style: StrokeStyle(lineWidth: 5, lineCap: .round))
        context.stroke(thread, with: .color(base), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        if swapped {
            var segment = context
            segment.clip(to: Path(CGRect(x: point.x + 10, y: point.y - 20, width: 24, height: 40)))
            segment.stroke(thread, with: .color(other), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }
}

enum MeiPalette {
    static let ink = Color(red: 0.07, green: 0.25, blue: 0.23)
    static let teal = Color(red: 0.06, green: 0.49, blue: 0.48)
    static let rose = Color(red: 0.78, green: 0.35, blue: 0.51)
    static let blue = Color(red: 0.25, green: 0.55, blue: 0.72)
    static let purple = Color(red: 0.48, green: 0.32, blue: 0.82)
    static let gold = Color(red: 0.79, green: 0.44, blue: 0.06)
    static let butter = Color(red: 0.99, green: 0.87, blue: 0.56)
    static let lilac = Color(red: 0.89, green: 0.82, blue: 0.91)
    static let mint = Color(red: 0.81, green: 0.90, blue: 0.77)
    static let blush = Color(red: 0.98, green: 0.81, blue: 0.79)
    static let paper = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.16, blue: 0.15, alpha: 1)
            : UIColor(red: 0.99, green: 0.96, blue: 0.92, alpha: 1)
    })
    static let text = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.96, green: 0.94, blue: 0.86, alpha: 1)
            : UIColor(red: 0.07, green: 0.25, blue: 0.23, alpha: 1)
    })
}

/// Decorative movement; it never advances the biological stage.
struct MeiSpecimenMotion: ViewModifier {
    var amount: Double = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drifting = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(reduceMotion ? 0 : (drifting ? 1.8 : -1.8) * amount))
            .offset(y: reduceMotion ? 0 : (drifting ? -1.5 : 1.5) * amount)
            .animation(reduceMotion ? nil : .easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: drifting)
            .onAppear { drifting = !reduceMotion }
            .onDisappear { drifting = false }
            .onChange(of: reduceMotion) { _, reduced in drifting = !reduced }
    }
}


// MARK: - Course content

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
    var cardColor: Color {
        [MeiPalette.butter, MeiPalette.mint, MeiPalette.blush, MeiPalette.lilac,
         MeiPalette.lilac, MeiPalette.mint, MeiPalette.blush, MeiPalette.butter][rawValue]
    }
    var explanation: String {
        switch self {
        case .prophaseI:
            return """
            • Chromatin condenses into visible chromosomes, each with two sister chromatids joined at a centromere.
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

