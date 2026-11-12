//
//  Mitosis.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/12/26.
//
import SwiftUI


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
                preparation
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
            Label("CELL DIVISION CENTRAL", systemImage: "sparkles")
                .font(.caption.weight(.bold))
                .tracking(1.4)
                .foregroundStyle(.secondary)
            Text("The Big Split")
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .accessibilityAddTraits(.isHeader)
            Text("One cell. Two new beginnings.")
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var preparation: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(.teal)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text("DNA copied. Let's get organized.")
                    .font(.system(.headline, design: .rounded))
                Text("S phase has already duplicated the DNA. Each replicated chromosome has two sister chromatids joined at a centromere.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 22))
    }

    private var phaseGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meet the phases")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Text("Tap a phase for its mission.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(MitosisPreviewPhase.allCases) { phase in
                Button {
                    selectedPhase = phase
                } label: {
                    HStack(spacing: 14) {
                        Text(phase.badge)
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundStyle(.primary)
                            .frame(width: 46, height: 46)
                            .background(phase.color.opacity(0.24), in: RoundedRectangle(cornerRadius: 15))
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
            Text("Mitosis divides the nucleus. Cytokinesis divides the cytoplasm. The stages are shown in learning order; some events overlap.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }
}

private struct ChromosomePortrait: View {
    private let ink = Color(red: 0.13, green: 0.16, blue: 0.29)

    var body: some View {
        VStack(spacing: 16) {
            Text("“Same DNA. Still attached.”")
                .font(.system(.headline, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.white.opacity(0.85), in: Capsule())

            ZStack {
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

            Text("One replicated chromosome · two sister chromatids")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(ink)
                .multilineTextAlignment(.center)
            Text("Character illustration • condensed form")
                .font(.caption)
                .foregroundStyle(ink.opacity(0.75))
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
    var badge: String {
        switch self {
        case .prophase: "01"
        case .prometaphase: "02"
        case .metaphase: "03"
        case .anaphase: "04"
        case .telophase: "05"
        case .cytokinesis: "+"
        }
    }
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
    var takeaway: String {
        switch self {
        case .prophase: "Condensing is packing—not copying. DNA was copied in S phase."
        case .prometaphase: "Spindle attachment point: the kinetochore."
        case .metaphase: "Connect first. Separate later."
        case .anaphase: "Sister chromatids separate; the name changes to chromosomes."
        case .telophase: "Two nuclei are forming inside the dividing cell."
        case .cytokinesis: "Nuclear division and cytoplasmic division are different jobs."
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
                    Text(phase.badge)
                        .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        .padding(24)
                        .background(phase.color.opacity(0.2), in: RoundedRectangle(cornerRadius: 24))
                    Text(phase.mission)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .accessibilityAddTraits(.isHeader)
                    Text(phase.explanation)
                        .font(.title3)
                    Label {
                        Text(phase.takeaway)
                    } icon: {
                        Image(systemName: "lightbulb.fill")
                    }
                    .font(.headline)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(phase.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 22))
                    Text("Based on your supplied McGraw-Hill notes.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
