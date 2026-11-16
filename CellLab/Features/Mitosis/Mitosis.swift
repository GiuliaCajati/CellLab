//
//  Mitosis.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/12/26.
//
import AVFAudio
import SwiftUI
import UIKit

struct MitosisView: View {

    let catalog: BiologyCatalog

    var body: some View { MitosisOverview() }

}

private struct MitosisOverview: View {

    @StateObject private var narration = MitosisNarrationPlayer()
    @State private var showingGame = false
    @Environment(\.scenePhase) private var scenePhase

    @ScaledMetric(relativeTo: .title2) private var carouselHeight: CGFloat = 290
    @ScaledMetric(relativeTo: .body) private var expandedHeight: CGFloat = 200
    @State private var expandedPhase: MitosisPreviewPhase?

    @State private var currentPhase = MitosisPreviewPhase.prophase

    @State private var selectedPhase: MitosisPreviewPhase?

    @State private var referenceSheet: MitosisReferenceSheet?

    @Environment(\.colorScheme) private var colorScheme

    private let phases = MitosisPreviewPhase.allCases.filter { $0 != .cytokinesis }

    var body: some View {

        ScrollView {

            VStack(spacing: 18) {

                header

                phaseCarousel

                ChromosomeJourneyCard()

                Button { referenceSheet = .players } label: {

                    HStack {

                        Label("Meet the key players", systemImage: "text.book.closed.fill")

                        Spacer()

                        Image(systemName: "chevron.right")

                    }

                    .font(.system(.headline, design: .rounded))

                    .padding(18)

                    .background(MitosisLabStyle.mint, in: RoundedRectangle(cornerRadius: 22))
                    .foregroundStyle(MitosisLabStyle.ink)
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(MitosisLabStyle.ink.opacity(0.7), lineWidth: 1.5))

                }

                .buttonStyle(.plain)

            }

            .padding(18)

            .frame(maxWidth: 680)

            .frame(maxWidth: .infinity)

        }

        .background(MitosisLabStyle.paper.ignoresSafeArea())
        .foregroundStyle(MitosisLabStyle.text)
        .tint(MitosisLabStyle.teal)

        .navigationTitle("")

        .navigationBarTitleDisplayMode(.inline)

        .sheet(item: $selectedPhase) { PhaseDetail(phase: $0) }

//        .sheet(isPresented: $showingCounts) { ChromosomeCountDetail() }

        .sheet(item: $referenceSheet) { MitosisReferenceView(section: $0) }
        .navigationDestination(isPresented: $showingGame) { MitosisGameView() }
        .onDisappear { narration.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { narration.stop() }
        }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { _ in
            narration.stop()
        }
        .alert("Unable to play audio", isPresented: Binding(
            get: { narration.errorMessage != nil },
            set: { if !$0 { narration.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { narration.errorMessage = nil }
        } message: {
            Text(narration.errorMessage ?? "Please try again.")
        }

    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                headerTitle
                Spacer(minLength: 12)
                headerActions
            }
            VStack(alignment: .leading, spacing: 12) {
                headerTitle
                HStack {
                    Spacer()
                    headerActions
                }
            }
        }
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 3) {

                Text("Mitosis")

                    .font(.system(.largeTitle, design: .serif, weight: .bold))

                    .accessibilityAddTraits(.isHeader)

                Text("One nucleus → two nuclei")

                    .font(.system(.caption, design: .rounded, weight: .medium))

                    .foregroundStyle(.secondary)

        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var headerActions: some View {
        HStack(spacing: 8) {
            Button { narration.toggle() } label: {
                Label(narration.isPlaying ? "Stop" : "Listen",
                      systemImage: narration.isPlaying ? "stop.fill" : "speaker.wave.2.fill")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .frame(minHeight: 36)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .accessibilityIdentifier("mitosisListenButton")
            .accessibilityHint(narration.isPlaying ? "Stops the opening narration." : "Plays the opening narration.")

            Button {
                narration.stop()
                showingGame = true
            } label: {

                Label("Play", systemImage: "play.fill")

                    .font(.system(.headline, design: .rounded))

                    .frame(minHeight: 36)

            }

            .buttonStyle(.borderedProminent)

            .tint(MitosisLabStyle.teal)
            .buttonBorderShape(.capsule)
            .accessibilityIdentifier("mitosisPlayButton")

        }
        .fixedSize(horizontal: true, vertical: false)

    }

    private var phaseCarousel: some View {

        VStack(spacing: 8) {

            TabView(selection: $currentPhase) {

                ForEach(phases) { phase in

                    VStack(alignment: .leading, spacing: 12) {

                        HStack {

                            Text(phase.rawValue)

                                .font(.system(.title, design: .serif, weight: .bold))

                                .lineLimit(1)

                                .minimumScaleFactor(0.8)

                            Spacer()

                            Text("\((phases.firstIndex(of: phase) ?? 0) + 1) / 5")

                                .font(.caption.weight(.bold))

                                .foregroundStyle(MitosisLabStyle.ink.opacity(0.72))

                        }

                        PhaseCellArt(phase: phase)
                            .modifier(MitosisSpecimenMotion(amount: 0.45))

                            .frame(maxWidth: .infinity)

                            .frame(height: 174)

                            .accessibilityHidden(true)

                        DisclosureGroup(isExpanded: Binding(
                            get: { expandedPhase == phase },
                            set: { expandedPhase = $0 ? phase : nil }
                        )) {

                            Text(phase.explanation)

                                .font(.body)

                                .foregroundStyle(MitosisLabStyle.ink.opacity(0.72))

                                .frame(maxWidth: .infinity, alignment: .leading)

                                .fixedSize(horizontal: false, vertical: true)

                                .padding(12)

                                .background(.white.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))

                                .padding(.top, 4)

                        } label: {

                            HStack(spacing: 8) {

                                Text(phase.mission)

                                    .font(.system(.subheadline, design: .rounded, weight: .medium))

                                    .lineLimit(1)

                                    .minimumScaleFactor(0.85)

                                Spacer(minLength: 0)

                            }

                        }

                        .tint(MitosisLabStyle.ink)

                        .contentShape(Rectangle())

                    }

                    .foregroundStyle(MitosisLabStyle.ink)

                    .padding(16)

                    .background(MitosisLabStyle.card(phase), in: RoundedRectangle(cornerRadius: 26))

                    .overlay(RoundedRectangle(cornerRadius: 26).stroke(MitosisLabStyle.ink.opacity(0.75), lineWidth: 1.5))

                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, 2)

                    .tag(phase)

                }

            }

            .tabViewStyle(.page(indexDisplayMode: .never))

            .frame(height: carouselHeight + (expandedPhase == currentPhase ? expandedHeight : 0))

            HStack(spacing: 4) {

                ForEach(phases) { phase in

                    Button { currentPhase = phase } label: {

                        Capsule()

                            .fill(currentPhase == phase ? MitosisLabStyle.teal : MitosisLabStyle.text.opacity(0.15))

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

//    let showDetails: () -> Void

    private let ink = MitosisLabStyle.ink

    var body: some View {

        VStack(spacing: 14) {

//            ZStack {

//

//            }

//            .overlay(alignment: .topTrailing) {

//                Button(action: showDetails) {

//                    Image(systemName: "info.circle")

//                        .font(.title3)

//                        .frame(width: 44, height: 44)

//                        .contentShape(Rectangle())

//                }

//                .buttonStyle(.plain)

//                .accessibilityLabel("Explain chromosome and chromatid counts")

//            }

            ChromosomeJourneyRow(replicated: true)

            HStack(spacing: 12) {

                Rectangle().frame(height: 1).opacity(0.15)

                Label("MITOSIS", systemImage: "arrow.down")

                    .font(.system(.caption2, design: .serif, weight: .bold))

                    .fixedSize()

                Rectangle().frame(height: 1).opacity(0.15)

            }

            ChromosomeJourneyRow(replicated: false)

        }

        .foregroundStyle(ink)

        .padding(16)

        .background(MitosisLabStyle.mint, in: RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(MitosisLabStyle.ink.opacity(0.75), lineWidth: 1.5))

    }

}

private struct ChromosomeJourneyRow: View {

    let replicated: Bool

    private let purple = Color(red: 0.46, green: 0.33, blue: 0.81)

    var body: some View {

        VStack(spacing: 5) {

            HStack {

                Text(replicated ? "START - 1 Nucleus" : "FINISH - 2 Matching Nuclei")

                    .font(.system(.caption, design: .serif, weight: .bold))

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

                    Image("CellLabMagnifier")
                        .resizable()
                        .scaledToFit()
                        .frame(width: side * 280 / 216, height: side * 280 / 216)
                        .position(x: right.x + side * 20 / 216, y: right.y + side * 20 / 216)

                    MagnifiedChromosomeCharacter(replicated: replicated)
                        .frame(width: side * 0.9, height: side * 0.9)
                        .position(right)

                }

            }

            .frame(height: 160)

            .accessibilityHidden(true)

            HStack(alignment: .top, spacing: 8) {

                VStack(spacing: 3) {

                    Text(replicated ? "46 chromosomes" : "46 chromosomes")

                    Text(replicated ? "92 sister chromatids" : "46 chromatids each")

                }

                .frame(maxWidth: .infinity)

                VStack(spacing: 3) {

                    Text("1 chromosome").fontWeight(.bold)

                    Text(replicated ? "2 sister chromatids (nearly identical, were copied doring S phase)" : "1 chromatid")

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
        // Row 2, column 6 is index 16: pink in both the source and lens.
        Image(replicated ? "CellLabPinkReplicated" : "CellLabPinkSingle")
            .resizable()
            .scaledToFit()
            .modifier(MitosisSpecimenMotion())
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

            context.draw(context.resolve(Image("CellLabNucleus")),
                         in: CGRect(x: 0, y: 0, width: side, height: side))
            let pink = context.resolve(Image(replicated ? "CellLabPinkReplicated" : "CellLabPinkSingle"))
            let blue = context.resolve(Image(replicated ? "CellLabBlueReplicated" : "CellLabBlueSingle"))
            var chromosomeIndex = 0
            for row in rows.indices {
                for column in 0..<rows[row] {
                    let x = side * (0.5 + (CGFloat(column) - CGFloat(rows[row] - 1) / 2) * 0.075)
                    let y = side * (0.5 + CGFloat(row - 3) * 0.105)
                    // 46 chromosomes: 23 maternal-color, 23 paternal-color.
                    // Both sisters share their parent's color; mitosis does not swap DNA.
                    let chromosome = chromosomeIndex.isMultiple(of: 2) ? pink : blue
                    context.draw(chromosome, in: CGRect(x: x - side * 0.035,
                                                       y: y - side * 0.035,
                                                       width: side * 0.07, height: side * 0.07))
                    chromosomeIndex += 1
                }
            }
        }

        .accessibilityLabel(replicated ? "One nucleus containing 46 replicated chromosomes, totaling 92 sister chromatids" : "One daughter nucleus containing 46 single-chromatid chromosomes")

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

    var explanationPoints: [String] {

        switch self {

        case .prophase:

            [

                "Chromatin condenses into visible chromosomes.",

                "Centrosomes move apart.",

                "The mitotic spindle begins to form."

            ]

        case .prometaphase:

            [

                "The nuclear envelope fragments.",

                "Spindle microtubules attach to kinetochores, protein complexes at chromosome centromeres."

            ]

        case .metaphase:

            [

                "Replicated chromosomes align at the cell’s equator.",

                "The checkpoint prevents separation before chromosomes are properly attached to the spindle."

            ]

        case .anaphase:

            [

                "Sister chromatids separate and move toward opposite poles.",

                "Each separated chromatid is now an individual chromosome."

            ]

        case .telophase:

            [

                "Nuclear envelopes re-form around the two chromosome sets.",

                "Chromosomes decondense.",

                "The spindle disassembles."

            ]

        case .cytokinesis:

            [

                "In animal cells, an actin-and-myosin contractile ring creates a cleavage furrow that divides the cytoplasm.",

                "Plant cells form a cell plate instead."

            ]

        }

    }

    var explanation: String {

        explanationPoints

            .map { "• \($0)" }

            .joined(separator: "\n")

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

                        .font(.system(.largeTitle, design: .serif, weight: .bold))

                        .accessibilityAddTraits(.isHeader)

                    PhaseCellArt(phase: phase)
                            .modifier(MitosisSpecimenMotion(amount: 0.45))

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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0,
                                paused: reduceMotion)) { timeline in
            artwork(time: reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 120))
        }
    }

    private func artwork(time: Double) -> some View {
        let movement = reduceMotion ? 0.0 : 1.0
        let pulse = 0.78 + 0.22 * sin(time * 2.1) * movement

        return Canvas { context, size in

            let scale = min(size.width / 300, size.height / 240)

            context.translateBy(x: (size.width - 300 * scale) / 2,

                                y: (size.height - 240 * scale) / 2)

            context.scaleBy(x: scale, y: scale)

            let purple = Color(red: 0.48, green: 0.32, blue: 0.82)

            let colors: [Color] = [Color(red: 0.25, green: 0.55, blue: 0.72), Color(red: 0.78, green: 0.35, blue: 0.51), Color(red: 0.25, green: 0.55, blue: 0.72)]

            let split = phase == .anaphase || phase == .telophase || phase == .cytokinesis

            func line(_ points: [CGPoint], color: Color, width: CGFloat) {

                guard let first = points.first else { return }

                var path = Path()

                path.move(to: first)

                for point in points.dropFirst() { path.addLine(to: point) }

                if width >= 7 {
                    context.stroke(path, with: .color(MitosisLabStyle.ink.opacity(0.65)), style: StrokeStyle(lineWidth: width + 1.5, lineCap: .round, lineJoin: .round))
                }
                context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))

            }

            func ellipse(_ rect: CGRect, fill: Color, stroke: Color) {

                let path = Path(ellipseIn: rect)

                context.fill(path, with: .color(fill))

                context.stroke(path, with: .color(stroke), lineWidth: 3)

            }

            func nucleus(_ x: CGFloat, width: CGFloat) {
                let breath = CGFloat(1 + 0.035 * sin(time * 1.8) * movement)
                let w = width * breath
                let h: CGFloat = 132 * breath
                context.draw(context.resolve(Image("CellLabPhaseNucleus")),
                             in: CGRect(x: x - w / 2, y: 120 - h / 2, width: w, height: h))
            }

            func spindle(from start: CGPoint, to end: CGPoint) {
                let dx = end.x - start.x
                let dy = end.y - start.y
                var fiber = context
                fiber.opacity = pulse
                fiber.translateBy(x: start.x, y: start.y)
                fiber.rotate(by: .radians(atan2(dy, dx)))
                fiber.draw(context.resolve(Image("CellLabSpindleFiber")),
                           in: CGRect(x: 0, y: -3, width: hypot(dx, dy), height: 6))
            }

            func centrosome(at x: CGFloat) {
                var halo = context
                halo.opacity = 0.65 + 0.35 * pulse
                let radius = CGFloat(24 + 4 * sin(time * 2.1) * movement)
                halo.draw(context.resolve(Image("CellLabCentrosome")),
                          in: CGRect(x: x - radius, y: 120 - radius, width: radius * 2, height: radius * 2))
                // Two distinct perpendicular barrels within one centrosome.
                for index in 0..<2 {
                    var barrel = context
                    barrel.translateBy(x: x + (index == 0 ? -4 : 5),
                                       y: 120 + (index == 0 ? -3 : 4))
                    barrel.rotate(by: .degrees(index == 0 ? -35 : 55))
                    barrel.draw(context.resolve(Image("CellLabCentriole")),
                                in: CGRect(x: -8, y: -10, width: 16, height: 20))
                }
            }

            func chromosome(_ x: CGFloat, _ y: CGFloat, _ color: Color, replicated: Bool) {
                let pink = color == colors[1]
                let name = replicated
                    ? (pink ? "CellLabPinkReplicated" : "CellLabBlueReplicated")
                    : (pink ? "CellLabPinkSingle" : "CellLabBlueSingle")
                context.draw(context.resolve(Image(name)),
                             in: CGRect(x: x - 21, y: y - 21, width: 42, height: 42))
            }

            if phase == .cytokinesis {

                for x in [CGFloat(8), CGFloat(158)] {

                    context.draw(context.resolve(Image("CellLabCellShell")), in: CGRect(x: x, y: 34, width: 134, height: 172))

                }

            } else {

                context.draw(context.resolve(Image("CellLabCellShell")), in: CGRect(x: 10, y: 25, width: 280, height: 190))

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

                                        control1: CGPoint(x: center - 8, y: y - 18 + CGFloat(5 * sin(time * 1.8 + Double(i)) * movement)),

                                        control2: CGPoint(x: center + 5, y: y + 20 - CGFloat(5 * sin(time * 1.8 + Double(i)) * movement)))

                        context.stroke(thread, with: .color(colors[i]), style: StrokeStyle(lineWidth: 4, lineCap: .round))

                    }

                }

            } else {

                for i in 0..<3 {

                    let y = CGFloat(82 + i * 38) + CGFloat(6 * sin(time * 1.8 + Double(i) * 1.4) * movement)

                    let x: CGFloat = phase == .prophase || phase == .prometaphase ? [125, 172, 138][i] : 150

                    if phase != .prophase {

                        let leftX: CGFloat = split ? 88 : x - 5

                        let rightX: CGFloat = split ? 212 : x + 5

                        spindle(from: CGPoint(x: 35, y: 120), to: CGPoint(x: leftX, y: y))

                        spindle(from: CGPoint(x: 265, y: 120), to: CGPoint(x: rightX, y: y))

                    }

                    if split {

                        chromosome(88, y, colors[i], replicated: false)

                        chromosome(212, y, colors[i], replicated: false)

                    } else {

                        chromosome(x, y, colors[i], replicated: true)

                    }

                }

                for x in [CGFloat(35), CGFloat(265)] {

                    centrosome(at: x)

                }

            }

        }

    }

}

// MARK: - Key players and companion references

private enum MitosisReferenceSheet: String, Identifiable {

    case players, sources

    var id: String { rawValue }

    var title: String { "Meet the key players" }

}

private struct MitosisReferenceView: View {

    let section: MitosisReferenceSheet

    @Environment(\.dismiss) private var dismiss

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 18) {

                    Text(section.title)

                        .font(.system(.largeTitle, design: .serif, weight: .bold))

                        .accessibilityAddTraits(.isHeader)

                    if section == .players {

                        Text("Tap a name. Meet the division crew.")

                            .font(.subheadline).foregroundStyle(.secondary)

                        MitosisKeyPlayersView()

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

                    }

                }

                .padding(22)

                .frame(maxWidth: 660)

                .frame(maxWidth: .infinity, alignment: .center)

            }

            .background(MitosisLabStyle.paper.ignoresSafeArea())
            .foregroundStyle(MitosisLabStyle.text)
            .tint(MitosisLabStyle.teal)
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



/// Presentation colors only; all learning content stays in the existing models.
private enum MitosisLabStyle {
    static let ink = Color(red: 0.07, green: 0.25, blue: 0.23)
    static let teal = Color(red: 0.06, green: 0.49, blue: 0.48)
    static let butter = Color(red: 0.99, green: 0.87, blue: 0.56)
    static let lilac = Color(red: 0.89, green: 0.82, blue: 0.91)
    static let mint = Color(red: 0.81, green: 0.90, blue: 0.77)
    static let rose = Color(red: 0.98, green: 0.81, blue: 0.79)
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
    static func card(_ phase: MitosisPreviewPhase) -> Color {
        switch phase {
        case .prophase: butter
        case .prometaphase: lilac
        case .metaphase: mint
        case .anaphase: rose
        case .telophase: lilac
        case .cytokinesis: mint
        }
    }
}


/// Decorative movement only. It does not advance the biological stage.
private struct MitosisSpecimenMotion: ViewModifier {
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
