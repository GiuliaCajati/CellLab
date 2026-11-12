//
//  Mitosis.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/12/26.
//
import SwiftUI

/// Mitosis entry screen. RootView owns navigation and catalog loading.
/// Biology copy below is adapted only from the supplied McGraw-Hill notes.
struct MitosisView: View {
    let catalog: BiologyCatalog

    var body: some View {
        MitosisOverview()
    }
}

// Kept independent of catalog decoding so previews need no JSON fixture.
private struct MitosisOverview: View {
    @State private var selectedPhase: MitosisPreviewPhase?
    @Environment(\.colorScheme) private var colorScheme

    private var background: Color {
        colorScheme == .dark
            ? Color(red: 0.07, green: 0.12, blue: 0.16)
            : Color(red: 0.95, green: 0.98, blue: 0.96)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heading
                ChromosomePortrait()
                phaseGuide
            }
            .padding(20)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .background(background.ignoresSafeArea())
        .navigationTitle("Mitosis")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedPhase) { phase in
            PhaseDetail(phase: phase)
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("The Big Split")
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .accessibilityAddTraits(.isHeader)
            Text("One cell → two daughter cells.")
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var phaseGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meet the phases")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Text("Pick a phase. Peek inside.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(MitosisPreviewPhase.allCases) { phase in
                Button {
                    selectedPhase = phase
                } label: {
                    HStack(spacing: 14) {
                        PhaseCellArt(phase: phase)
                            .frame(width: 86, height: 70)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(phase.rawValue)
                                .font(.system(.headline, design: .rounded))
                            Text(phase.mission)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.primary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 22))
                    .contentShape(RoundedRectangle(cornerRadius: 22))
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the phase explanation")
            }
            Text("Mitosis: split the nucleus. Cytokinesis: split the cell.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }
}

private struct ChromosomePortrait: View {
    @State private var showInterphaseConnection = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let ink = Color(red: 0.13, green: 0.16, blue: 0.29)

    var body: some View {
        VStack(spacing: 16) {
            Text(showInterphaseConnection ? "“DNA twins! We’re identical copies made during S phase.”" : "“Before Mitosis gets started meet my sister chromatid!”")
                .font(.system(.headline, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 22))
                .fixedSize(horizontal: false, vertical: true)

            ZStack {
                VStack {
                    HStack {
                        Text("Identical Chromatid").offset(x: -12)
                        Spacer()
                        Text("Copy Chromatid").offset(x: 12)
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(ink)
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.horizontal, 40)
                Circle()
                    .fill(.white.opacity(0.38))
                    .frame(width: 200, height: 200)
                Circle()
                    .stroke(.white.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [5, 7]))
                    .frame(width: 216, height: 216)
                // Each bowed side is one sister chromatid, joined centrally.
                chromatid(left: true)
                    .stroke(Color(red: 0.46, green: 0.33, blue: 0.81), style: StrokeStyle(lineWidth: 25, lineCap: .round, lineJoin: .round))
                chromatid(left: false)
                    .stroke(Color(red: 0.64, green: 0.46, blue: 0.91), style: StrokeStyle(lineWidth: 25, lineCap: .round, lineJoin: .round))
                Ellipse()
                    .fill(Color(red: 1, green: 0.79, blue: 0.35))
                    .frame(width: 42, height: 22)
                HStack(spacing: 9) {
                    Capsule().frame(width: 4, height: 8)
                    Capsule().frame(width: 4, height: 8)
                }
                .foregroundStyle(ink)
            }
            .frame(width: 230, height: 230)
            .accessibilityHidden(true)

            Text("2 sister chromatids.\n1 replicated chromosome.")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(ink)
                .multilineTextAlignment(.center)
            Button(showInterphaseConnection ? "Got it!" : "Thank you, Interphase!") {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                    showInterphaseConnection.toggle()
                }
            }
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .foregroundStyle(ink)
            .padding(.horizontal, 18)
            .frame(minHeight: 44)
            .background(.white.opacity(0.7), in: Capsule())
            .buttonStyle(.plain)
            .accessibilityHint(showInterphaseConnection ? "Returns to the chromosome introduction" : "Explains how S phase produces sister chromatids")
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 32)
                .fill(LinearGradient(colors: [Color(red: 0.72, green: 0.94, blue: 0.86), Color(red: 0.86, green: 0.82, blue: 0.98)], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }

    private func chromatid(left: Bool) -> Path {
        let outer: CGFloat = left ? 72 : 158
        let inner: CGFloat = left ? 109 : 121
        return Path { path in
            path.move(to: CGPoint(x: outer, y: 53))
            path.addQuadCurve(to: CGPoint(x: inner, y: 115), control: CGPoint(x: inner, y: 90))
            path.addQuadCurve(to: CGPoint(x: outer, y: 177), control: CGPoint(x: inner, y: 140))
        }
    }
}

/// Temporary presentation copy, not a second reference database or game engine.
/// Migrate to catalog-backed entries when the catalog schema is available.
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
                    Text(phase.mission)
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
