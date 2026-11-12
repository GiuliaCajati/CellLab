//
//  Mitosis.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/12/26.
//
import SwiftUI

struct MitosisView: View {
    let catalog: BiologyCatalog
    var body: some View { MitosisOverview() }
}

private struct MitosisOverview: View {
    @ScaledMetric(relativeTo: .title2) private var carouselHeight: CGFloat = 278
    @State private var currentPhase = MitosisPreviewPhase.prophase
    @State private var selectedPhase: MitosisPreviewPhase?
    @State private var showingCounts = false
    @State private var referenceSheet: MitosisReferenceSheet?
    @Environment(\.colorScheme) private var colorScheme
    private let phases = MitosisPreviewPhase.allCases.filter { $0 != .cytokinesis }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                phaseCarousel
                ChromosomeJourneyCard { showingCounts = true }
                Button { referenceSheet = .players } label: {
                    HStack {
                        Label("Meet the key players", systemImage: "text.book.closed.fill")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(.headline, design: .rounded))
                    .padding(18)
                    .background(Color.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 22))
                }
                .buttonStyle(.plain)
                Button("Notes & video") { referenceSheet = .sources }
                    .font(.caption)
                    .padding(.bottom, 8)
            }
            .padding(18)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background((colorScheme == .dark ? Color(red: 0.07, green: 0.12, blue: 0.16) : Color(red: 0.95, green: 0.98, blue: 0.96)).ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedPhase) { PhaseDetail(phase: $0) }
        .sheet(isPresented: $showingCounts) { ChromosomeCountDetail() }
        .sheet(item: $referenceSheet) { MitosisReferenceView(section: $0) }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Mitosis")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .accessibilityAddTraits(.isHeader)
                Text("One nucleus → two nuclei")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            NavigationLink { MitosisGameView() } label: {
                Label("Play", systemImage: "play.fill")
                    .font(.system(.headline, design: .rounded))
                    .frame(minHeight: 36)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.39, green: 0.26, blue: 0.70))
        }
    }

    private var phaseCarousel: some View {
        VStack(spacing: 8) {
            TabView(selection: $currentPhase) {
                ForEach(phases) { phase in
                    Button { selectedPhase = phase } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(phase.rawValue)
                                    .font(.system(.title2, design: .rounded, weight: .heavy))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Spacer()
                                Text("\((phases.firstIndex(of: phase) ?? 0) + 1) / 5")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                            PhaseCellArt(phase: phase)
                                .frame(maxWidth: .infinity)
                                .frame(height: 174)
                                .accessibilityHidden(true)
                            HStack {
                                Text(phase.mission)
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                Spacer()
                                Image(systemName: "info.circle")
                            }
                            .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.primary)
                        .padding(16)
                        .background(phase.color.opacity(0.11), in: RoundedRectangle(cornerRadius: 26))
                        .overlay(RoundedRectangle(cornerRadius: 26).stroke(phase.color.opacity(0.22), lineWidth: 1.5))
                        .padding(.horizontal, 2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens the phase explanation. Swipe to explore other phases.")
                    .tag(phase)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: carouselHeight)

            HStack(spacing: 4) {
                ForEach(phases) { phase in
                    Button { currentPhase = phase } label: {
                        Capsule()
                            .fill(currentPhase == phase ? phase.color : Color.secondary.opacity(0.22))
                            .frame(width: currentPhase == phase ? 22 : 7, height: 7)
                            .frame(width: 40, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(phase.rawValue)
                    .accessibilityAddTraits(currentPhase == phase ? .isSelected : [])
                }
            }
            .accessibilityLabel("Choose a mitosis phase")
        }
    }

}

/// Both lenses point to one symbol in a complete 46-chromosome nucleus.
private struct ChromosomeJourneyCard: View {
    let showDetails: () -> Void
    private let ink = Color(red: 0.13, green: 0.16, blue: 0.29)

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("IN EACH NUCLEUS")
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                    Text("46 chromosomes · 23 pairs")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Button(action: showDetails) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Explain chromosome and chromatid counts")
            }
            ChromosomeJourneyRow(replicated: true)
            HStack(spacing: 12) {
                Rectangle().frame(height: 1).opacity(0.15)
                Label("MITOSIS", systemImage: "arrow.down")
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .fixedSize()
                Rectangle().frame(height: 1).opacity(0.15)
            }
            ChromosomeJourneyRow(replicated: false)
        }
        .foregroundStyle(ink)
        .padding(16)
        .background(LinearGradient(colors: [Color(red: 0.72, green: 0.94, blue: 0.86), Color(red: 0.86, green: 0.82, blue: 0.98)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 26))
    }
}

private struct ChromosomeJourneyRow: View {
    let replicated: Bool
    private let purple = Color(red: 0.46, green: 0.33, blue: 0.81)

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(replicated ? "START" : "FINISH")
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.55), in: Capsule())
                Spacer()
            }
            GeometryReader { geometry in
                let side = min(geometry.size.width * 0.40, 138)
                let left = CGPoint(x: geometry.size.width * 0.23, y: 74)
                let right = CGPoint(x: geometry.size.width * 0.76, y: 74)
                let nucleusSide = replicated ? side : side * 0.60
                let source = replicated ? left : CGPoint(x: left.x + side * 0.17, y: left.y + side * 0.27)
                // Row 2, column 6: the same selected chromosome in both lenses.
                let selected = CGPoint(x: source.x + nucleusSide * 0.1875, y: source.y - nucleusSide * 0.105)
                ZStack {
                    if !replicated {
                        FullChromosomeNucleus(replicated: false)
                            .frame(width: nucleusSide, height: nucleusSide)
                            .position(x: left.x - side * 0.17, y: left.y - side * 0.27)
                    }
                    FullChromosomeNucleus(replicated: replicated)
                        .frame(width: nucleusSide, height: nucleusSide)
                        .position(source)
                    Path { path in
                        path.move(to: selected)
                        path.addLine(to: CGPoint(x: right.x - side * 0.45, y: right.y - side * 0.20))
                        path.move(to: selected)
                        path.addLine(to: CGPoint(x: right.x - side * 0.45, y: right.y + side * 0.20))
                    }
                    .stroke(purple.opacity(0.65), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    Circle()
                        .fill(.yellow.opacity(0.25))
                        .overlay(Circle().stroke(Color(red: 0.79, green: 0.44, blue: 0.06), lineWidth: 2))
                        .frame(width: 11, height: 11)
                        .position(selected)
                    Path { path in
                        path.move(to: CGPoint(x: right.x + side * 0.30, y: right.y + side * 0.30))
                        path.addLine(to: CGPoint(x: right.x + side * 0.46, y: right.y + side * 0.48))
                    }
                    .stroke(purple, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    Circle()
                        .fill(.white.opacity(0.85))
                        .frame(width: side, height: side)
                        .position(right)
                    MagnifiedChromosomeCharacter(replicated: replicated)
                        .frame(width: side * 0.9, height: side * 0.9)
                        .position(right)
                    Circle()
                        .stroke(purple, lineWidth: 3.5)
                        .frame(width: side, height: side)
                        .position(right)
                }
            }
            .frame(height: 160)
            .accessibilityHidden(true)
            HStack(alignment: .top, spacing: 8) {
                VStack(spacing: 3) {
                    Text(replicated ? "1 nucleus" : "2 matching nuclei")
                        .fontWeight(.bold)
                    Text(replicated ? "92 chromatids" : "46 chromatids each")
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 3) {
                    Text("1 chromosome").fontWeight(.bold)
                    Text(replicated ? "2 sister chromatids" : "1 chromatid")
                }
                .frame(maxWidth: .infinity)
            }
            .font(.system(.caption, design: .rounded))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(replicated
            ? "Start: one nucleus, 46 chromosomes in 23 pairs, 92 chromatids. The magnifier shows one replicated chromosome with two identical sister chromatids."
            : "Finish: two matching nuclei, each with 46 chromosomes in 23 pairs and 46 chromatids. The magnifier shows one single-chromatid chromosome. Chromosomes decondense at the end; symbols show their count.")
    }
}

/// The familiar character, shown with two sisters at the start and one at the end.
private struct MagnifiedChromosomeCharacter: View {
    let replicated: Bool

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            context.translateBy(x: (size.width - side) / 2, y: (size.height - side) / 2)
            context.scaleBy(x: side / 230, y: side / 230)
            if replicated {
                for left in [true, false] {
                    let outer: CGFloat = left ? 72 : 158
                    let inner: CGFloat = left ? 109 : 121
                    var path = Path()
                    path.move(to: CGPoint(x: outer, y: 53))
                    path.addQuadCurve(to: CGPoint(x: inner, y: 115), control: CGPoint(x: inner, y: 90))
                    path.addQuadCurve(to: CGPoint(x: outer, y: 177), control: CGPoint(x: inner, y: 140))
                    context.stroke(path, with: .color(left ? Color(red: 0.46, green: 0.33, blue: 0.81) : Color(red: 0.64, green: 0.46, blue: 0.91)), style: StrokeStyle(lineWidth: 25, lineCap: .round, lineJoin: .round))
                }
            } else {
                var path = Path()
                path.move(to: CGPoint(x: 103, y: 53))
                path.addQuadCurve(to: CGPoint(x: 115, y: 115), control: CGPoint(x: 115, y: 90))
                path.addQuadCurve(to: CGPoint(x: 103, y: 177), control: CGPoint(x: 115, y: 140))
                context.stroke(path, with: .color(Color(red: 0.46, green: 0.33, blue: 0.81)), style: StrokeStyle(lineWidth: 25, lineCap: .round, lineJoin: .round))
            }
            let face = CGRect(x: replicated ? 94 : 102, y: 104, width: replicated ? 42 : 26, height: 22)
            context.fill(Path(ellipseIn: face), with: .color(Color(red: 1, green: 0.79, blue: 0.35)))
            for x in [CGFloat(106.5), CGFloat(119.5)] {
                context.fill(Path(roundedRect: CGRect(x: x, y: 111, width: 4, height: 8), cornerRadius: 2), with: .color(Color(red: 0.13, green: 0.16, blue: 0.29)))
            }
        }
        .accessibilityHidden(true)
    }
}

/// Exactly 46 chromosome symbols. The layout is for counting, not a karyotype;
/// homologous chromosomes are not shown pairing during mitosis.
private struct FullChromosomeNucleus: View {
    let replicated: Bool
    private let rows = [4, 6, 8, 10, 8, 6, 4]

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            context.translateBy(x: (size.width - side) / 2, y: (size.height - side) / 2)
            let boundary = Path(ellipseIn: CGRect(x: side * 0.035, y: side * 0.035, width: side * 0.93, height: side * 0.93))
            let purple = Color(red: 0.43, green: 0.29, blue: 0.73)
            context.fill(boundary, with: .color(Color(red: 0.89, green: 0.85, blue: 0.98)))
            context.stroke(boundary, with: .color(purple.opacity(0.7)), lineWidth: side * 0.012)
            for row in rows.indices {
                for column in 0..<rows[row] {
                    let x = side * (0.5 + (CGFloat(column) - CGFloat(rows[row] - 1) / 2) * 0.075)
                    let y = side * (0.5 + CGFloat(row - 3) * 0.105)
                    let arm = side * 0.014
                    let height = side * 0.024
                    var symbol = Path()
                    if replicated {
                        symbol.move(to: CGPoint(x: x - arm, y: y - height))
                        symbol.addLine(to: CGPoint(x: x + arm, y: y + height))
                        symbol.move(to: CGPoint(x: x + arm, y: y - height))
                        symbol.addLine(to: CGPoint(x: x - arm, y: y + height))
                    } else {
                        symbol.move(to: CGPoint(x: x, y: y - height))
                        symbol.addLine(to: CGPoint(x: x, y: y + height))
                    }
                    context.stroke(symbol, with: .color(purple), style: StrokeStyle(lineWidth: side * 0.009, lineCap: .round))
                }
            }
        }
        .accessibilityLabel(replicated ? "One nucleus containing 46 replicated chromosomes, totaling 92 sister chromatids" : "One daughter nucleus containing 46 single-chromatid chromosomes")
    }
}

private struct ChromosomeCountDetail: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Same chromosome number.\nTwo matching nuclei.")
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .multilineTextAlignment(.center)
                    Text("Human somatic cell · 46 chromosomes = 23 pairs")
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                    VStack(spacing: 8) {
                        Text("START OF MITOSIS").font(.caption.weight(.bold))
                        FullChromosomeNucleus(replicated: true).frame(width: 190, height: 190)
                        Text("1 nucleus").font(.headline)
                        Text("46 replicated chromosomes\n92 sister chromatids")
                            .multilineTextAlignment(.center)
                    }
                    Image(systemName: "arrow.down").font(.title2.bold()).accessibilityHidden(true)
                    VStack(spacing: 8) {
                        Text("END OF MITOSIS").font(.caption.weight(.bold))
                        HStack(spacing: 14) {
                            FullChromosomeNucleus(replicated: false).aspectRatio(1, contentMode: .fit)
                            FullChromosomeNucleus(replicated: false).aspectRatio(1, contentMode: .fit)
                        }
                        .frame(maxWidth: 380)
                        Text("2 nuclei — each with:").font(.headline)
                        Text("46 single-chromatid chromosomes\n46 chromatids · still 23 pairs")
                            .multilineTextAlignment(.center)
                        Text("Chromosomes loosen into chromatin in telophase. These symbols make the counts visible.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    DisclosureGroup("Why 23 pairs, but 46 chromosomes?") {
                        Text("A pair contains two chromosomes. In a human somatic cell, 23 pairs means 46 chromosomes. Copying DNA makes two sister chromatids per chromosome; it does not change 46 chromosomes into 23. When the sisters separate in anaphase, each becomes a chromosome: 92 in the cell, with 46 moving toward each future nucleus.")
                            .font(.body)
                            .padding(.top, 10)
                    }
                    .padding(16)
                    .background(.purple.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
                    Text("Mitosis divides the nucleus. Cytokinesis divides the cytoplasm separately.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Count the chromosomes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

private enum MitosisPreviewPhase: String, CaseIterable, Identifiable {

    case prophase = "Prophase"

    case prometaphase = "Prometaphase"

    case metaphase = "Metaphase"

    case anaphase = "Anaphase"

    case telophase = "Telophase"

    case cytokinesis = "Cytokinesis"

    var id: String { rawValue }

    var color: Color {

        switch self {

        case .prophase: .purple

        case .prometaphase: .blue

        case .metaphase: .teal

        case .anaphase: .orange

        case .telophase: .pink

        case .cytokinesis: .green

        }

    }

    var mission: String {

        switch self {

        case .prophase: "Pack it up"

        case .prometaphase: "Make connections"

        case .metaphase: "Get in line"

        case .anaphase: "Sister send-off"

        case .telophase: "Build two nuclei"

        case .cytokinesis: "Finish the split"

        }

    }

    var explanation: String {

        switch self {

        case .prophase:

            "Chromatin condenses into visible chromosomes. Centrosomes move apart and the mitotic spindle begins to form."

        case .prometaphase:

            "The nuclear envelope fragments. Spindle microtubules attach to kinetochores, protein complexes at chromosome centromeres."

        case .metaphase:

            "Replicated chromosomes align at the cell’s equator. The checkpoint prevents separation before chromosomes are properly attached to the spindle."

        case .anaphase:

            "Sister chromatids separate and move toward opposite poles. Each separated chromatid is now an individual chromosome."

        case .telophase:

            "Nuclear envelopes re-form around the two chromosome sets. Chromosomes decondense and the spindle disassembles."

        case .cytokinesis:

            "In animal cells, an actin-and-myosin contractile ring creates a cleavage furrow that divides the cytoplasm. Plant cells form a cell plate instead."

        }

    }

}

private struct PhaseDetail: View {

    let phase: MitosisPreviewPhase

    @Environment(\.dismiss) private var dismiss

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 24) {

                    Text(phase.rawValue)

                        .font(.system(.largeTitle, design: .rounded, weight: .heavy))

                        .accessibilityAddTraits(.isHeader)

                    PhaseCellArt(phase: phase)

                        .aspectRatio(1.25, contentMode: .fit)

                        .padding(12)

                        .background(phase.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 32))

                        .accessibilityLabel(phase.visualDescription)

                    Text(phase.caption)

                        .font(.system(.title3, design: .rounded, weight: .semibold))

                        .frame(maxWidth: .infinity, alignment: .center)

                        .multilineTextAlignment(.center)

                    DisclosureGroup("A little more biology") {

                        Text(phase.explanation)

                            .font(.body)

                            .foregroundStyle(.secondary)

                            .padding(.top, 10)

                    }

                    .tint(.primary)

                    .padding(18)

                    .background(phase.color.opacity(0.09), in: RoundedRectangle(cornerRadius: 20))

                }

                .padding(24)

                .frame(maxWidth: 620, alignment: .leading)

                .frame(maxWidth: .infinity)

            }

            .navigationTitle(phase.rawValue)

            .navigationBarTitleDisplayMode(.inline)

            .toolbar {

                ToolbarItem(placement: .confirmationAction) {

                    Button("Done") { dismiss() }

                }

            }

        }

    }

}

#Preview("Mitosis • Light") {

    NavigationStack { MitosisOverview() }

        .preferredColorScheme(.light)

}

#Preview("Mitosis • Dark") {

    NavigationStack { MitosisOverview() }

        .preferredColorScheme(.dark)

}

private extension MitosisPreviewPhase {

    var caption: String {

        switch self {

        case .prophase: "Pack the DNA. Time to travel."

        case .prometaphase: "Envelope opens. Spindle connects."

        case .metaphase: "Everyone to the middle!"

        case .anaphase: "Sisters separate. Chromosomes on the move."

        case .telophase: "Two nuclei. Unpacking time."

        case .cytokinesis: "A little pinch. Two new cells."

        }

    }

    var visualDescription: String {

        switch self {

        case .prophase: "Animal cell with condensed replicated chromosomes inside the nucleus and centrosomes moving apart."

        case .prometaphase: "Fragmented nuclear envelope with spindle fibers reaching chromosome attachment sites."

        case .metaphase: "Three illustrative replicated chromosomes aligned at the equator, attached to opposite spindle poles."

        case .anaphase: "Three separated chromosomes move to each pole."

        case .telophase: "Two nuclei form around matching chromosome sets as DNA loosens."

        case .cytokinesis: "Two daughter animal cells, each containing a nucleus and matching chromatin."

        }

    }

}

/// Simplified animal-cell diagrams. Three chromosomes keep the visual readable;

/// they are not a species-specific chromosome count. Colors track chromosome identity.

private struct PhaseCellArt: View {

    let phase: MitosisPreviewPhase

    var body: some View {

        Canvas { context, size in

            let scale = min(size.width / 300, size.height / 240)

            context.translateBy(x: (size.width - 300 * scale) / 2,

                                y: (size.height - 240 * scale) / 2)

            context.scaleBy(x: scale, y: scale)

            let purple = Color(red: 0.48, green: 0.32, blue: 0.82)

            let colors: [Color] = [purple, .pink, .teal]

            let split = phase == .anaphase || phase == .telophase || phase == .cytokinesis

            func line(_ points: [CGPoint], color: Color, width: CGFloat) {

                guard let first = points.first else { return }

                var path = Path()

                path.move(to: first)

                for point in points.dropFirst() { path.addLine(to: point) }

                context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))

            }

            func ellipse(_ rect: CGRect, fill: Color, stroke: Color) {

                let path = Path(ellipseIn: rect)

                context.fill(path, with: .color(fill))

                context.stroke(path, with: .color(stroke), lineWidth: 3)

            }

            func nucleus(_ x: CGFloat, width: CGFloat) {

                ellipse(CGRect(x: x - width / 2, y: 65, width: width, height: 110),

                        fill: purple.opacity(0.09), stroke: purple.opacity(0.5))

            }

            func chromosome(_ x: CGFloat, _ y: CGFloat, _ color: Color, replicated: Bool) {

                line([CGPoint(x: x - 9, y: y - 15), CGPoint(x: x - 2, y: y), CGPoint(x: x - 9, y: y + 15)], color: color, width: 7)

                if replicated {

                    line([CGPoint(x: x + 9, y: y - 15), CGPoint(x: x + 2, y: y), CGPoint(x: x + 9, y: y + 15)], color: color, width: 7)

                    context.fill(Path(ellipseIn: CGRect(x: x - 5, y: y - 4, width: 10, height: 8)), with: .color(.yellow))

                }

            }

            if phase == .cytokinesis {

                for x in [CGFloat(8), CGFloat(158)] {

                    ellipse(CGRect(x: x, y: 34, width: 134, height: 172), fill: .mint.opacity(0.23), stroke: .teal.opacity(0.6))

                }

            } else {

                ellipse(CGRect(x: 10, y: 25, width: 280, height: 190), fill: .mint.opacity(0.23), stroke: .teal.opacity(0.6))

            }

            if phase == .prophase { nucleus(150, width: 150) }

            if phase == .prometaphase {

                let boundary = Path(ellipseIn: CGRect(x: 75, y: 65, width: 150, height: 110))

                context.stroke(boundary, with: .color(purple.opacity(0.45)), style: StrokeStyle(lineWidth: 3, dash: [12, 14]))

            }

            if phase == .telophase || phase == .cytokinesis {

                nucleus(75, width: 90)

                nucleus(225, width: 90)

                // Loose chromatin replaces X-shaped chromosomes in daughter nuclei.

                for center in [CGFloat(75), CGFloat(225)] {

                    for i in 0..<3 {

                        let y = CGFloat(92 + i * 27)

                        var thread = Path()

                        thread.move(to: CGPoint(x: center - 25, y: y))

                        thread.addCurve(to: CGPoint(x: center + 25, y: y + 3),

                                        control1: CGPoint(x: center - 8, y: y - 18),

                                        control2: CGPoint(x: center + 5, y: y + 20))

                        context.stroke(thread, with: .color(colors[i]), style: StrokeStyle(lineWidth: 4, lineCap: .round))

                    }

                }

            } else {

                for i in 0..<3 {

                    let y = CGFloat(82 + i * 38)

                    let x: CGFloat = phase == .prophase || phase == .prometaphase ? [125, 172, 138][i] : 150

                    if phase != .prophase {

                        let leftX: CGFloat = split ? 88 : x - 5

                        let rightX: CGFloat = split ? 212 : x + 5

                        line([CGPoint(x: 35, y: 120), CGPoint(x: leftX, y: y)], color: .teal.opacity(0.65), width: 2)

                        line([CGPoint(x: 265, y: 120), CGPoint(x: rightX, y: y)], color: .teal.opacity(0.65), width: 2)

                    }

                    if split {

                        chromosome(88, y, colors[i], replicated: false)

                        chromosome(212, y, colors[i], replicated: false)

                    } else {

                        chromosome(x, y, colors[i], replicated: true)

                    }

                }

                for x in [CGFloat(35), CGFloat(265)] {

                    ellipse(CGRect(x: x - 6, y: 114, width: 12, height: 12), fill: .orange, stroke: .orange)

                }

            }

        }

    }

}


// MARK: - Key players and companion references

private enum MitosisReferenceSheet: String, Identifiable {
    case players, sources
    var id: String { rawValue }
    var title: String { self == .players ? "Meet the key players" : "Notes & video" }
}

private struct MitosisReferenceView: View {
    let section: MitosisReferenceSheet
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(section.title)
                        .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        .accessibilityAddTraits(.isHeader)
                    if section == .players {
                        Text("Tap a name. Meet the division crew.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        ForEach(MitosisKeyPlayer.all) { player in
                            DisclosureGroup {
                                Text(player.definition)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } label: {
                                Text(player.name)
                                    .font(.system(.headline, design: .rounded))
                            }
                            .padding(16)
                            .background(Color.purple.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
                        }
                        Text("CYTOKINESIS · DIVIDING THE CYTOPLASM")
                            .font(.caption2.weight(.heavy)).foregroundStyle(.secondary)
                        DisclosureGroup {
                            Text("Actin and myosin form a contractile ring beneath the animal cell’s membrane. The ring tightens, creating a cleavage furrow that divides the cytoplasm. This is cytokinesis, a process distinct from mitosis that can begin before mitosis finishes.")
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 8)
                        } label: {
                            Text("Actin & myosin")
                                .font(.system(.headline, design: .rounded))
                        }
                        .padding(16)
                        .background(Color.teal.opacity(0.09), in: RoundedRectangle(cornerRadius: 18))
                    } else {
                        Text("Study notes")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                        Text("Based on the McGraw-Hill study notes supplied for CellLab. Explanations are shortened for learning; the supplied numbered markers were not complete textbook citations.")
                        Link(destination: URL(string: "https://youtu.be/ShEzlXZPpPM")!) {
                            Label("Watch the mitosis video", systemImage: "play.rectangle.fill")
                                .font(.system(.headline, design: .rounded))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.purple.opacity(0.09), in: RoundedRectangle(cornerRadius: 18))
                        }
                        Text("The video is the companion reference you supplied; its contents were not independently retrieved for this page.")
                            .font(.caption).foregroundStyle(.secondary)
                        Text("Reading the drawings")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                        Text("This page focuses on human animal cells. Phase drawings show fewer chromosomes to make the movements clear. The count comparison shows all 46 chromosomes in each nucleus.")
                        Text("At the start: 46 replicated chromosomes, 92 chromatids. At the finish: two nuclei, each with 46 single-chromatid chromosomes—still 23 pairs.")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .padding(16)
                            .background(Color.teal.opacity(0.09), in: RoundedRectangle(cornerRadius: 18))
                        Text("Chromosomes uncoil during telophase. Condensed symbols in the final comparison clarify the count; they do not depict the final texture of chromatin.")
                        Text("Mitosis divides the nucleus. Cytokinesis divides the cytoplasm.")
                            .font(.headline)
                    }
                }
                .padding(22)
                .frame(maxWidth: 660)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .navigationTitle("Mitosis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct MitosisKeyPlayer: Identifiable {
    let name: String
    let definition: String
    var id: String { name }

    static let all: [MitosisKeyPlayer] = [
        .init(name: "Chromosomes & sister chromatids", definition: "After DNA replication, one chromosome has two identical sister chromatids joined at the centromere. In anaphase, they separate; each is now an individual chromosome. Two chromatids do not mean two chromosomes while they remain joined."),
        .init(name: "Centromere & kinetochore", definition: "The centromere is the chromosome region where sister chromatids are joined. Kinetochores are protein complexes assembled at this region; spindle microtubules attach there to move the chromosomes."),
        .init(name: "Centrosomes & centrioles", definition: "Centrosomes organize the spindle in animal cells. Each contains a pair of barrel-shaped centrioles. The two centrosomes move toward opposite poles as the spindle forms."),
        .init(name: "Spindle fibers", definition: "These microtubules form the mitotic spindle. Kinetochore microtubules move chromosomes and shorten during anaphase. Other spindle microtubules help push the cell’s poles apart."),
        .init(name: "Nuclear envelope & nucleolus", definition: "The nuclear envelope surrounds the nucleus. It breaks down during prometaphase so spindle fibers can reach chromosomes, then re-forms around each chromosome set in telophase. The nucleolus disappears during prophase and reappears as the new nuclei form."),
        .init(name: "Chromatin & histones", definition: "Chromatin is DNA together with its associated proteins. DNA wraps around histone proteins to form nucleosomes—beads on a string. Chromatin condenses into compact chromosomes for division and loosens again during telophase.")
    ]
}
