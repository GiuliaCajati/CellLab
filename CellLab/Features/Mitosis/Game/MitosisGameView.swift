//
//  MitosisGameView.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/12/26.
//

import SwiftUI
import Foundation

/// Fixed gameplay layout: portrait stacks the cell above its controls;

/// landscape puts the controls beside the cell. Only modal explanations can scroll.

struct MitosisGameView: View {

    @State private var session = MitosisSession()

    @State private var popup: MitosisPopup?

    @State private var confirmingRestart = false
    @State private var showsParts = false

    @State private var motionInProgress = false

    @State private var motionTask: Task<Void, Never>?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Environment(\.colorScheme) private var colorScheme

    private var accent: Color {

        phaseColor(session.stage)

    }

    private var background: Color {

        colorScheme == .dark

            ? Color(red: 0.08, green: 0.16, blue: 0.15)

            : Color(red: 0.99, green: 0.96, blue: 0.92)

    }

    var body: some View {

        GeometryReader { geometry in

            let landscape = geometry.size.width > geometry.size.height * 1.2

            let compact = geometry.size.height < 620

            VStack(spacing: compact ? 8 : 14) {

                heading(compact: compact)

                if landscape {

                    HStack(spacing: 18) {

                        playfield

                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        dashboard(compact: true)

                            .frame(width: min(320, geometry.size.width * 0.40))

                    }

                } else {

                    playfield

                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    dashboard(compact: compact)

                }

            }

            .padding(landscape ? 12 : 16)

            .frame(maxWidth: 1100)

            .frame(maxWidth: .infinity, maxHeight: .infinity)

        }

        .background(background.ignoresSafeArea())

        .navigationTitle("Mitosis")

        .navigationBarTitleDisplayMode(.inline)

        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showsParts.toggle() } label: {
                    Label("Hint", systemImage: showsParts ? "tag.fill" : "tag")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                }
                .tint(accent)
                .accessibilityAddTraits(showsParts ? .isSelected : [])
                .accessibilityIdentifier("mitosis-parts-hint")
                .disabled(motionInProgress)
            }

            ToolbarItem(placement: .topBarTrailing) {

                Menu {

                    Button("What is happening?", systemImage: "lightbulb") {

                        popup = MitosisPopup.explanation(session)

                    }

                    .disabled(motionInProgress)

                    Button("Restart game", systemImage: "arrow.counterclockwise") {

                        confirmingRestart = true

                    }

                    .disabled(motionInProgress)

                } label: { Image(systemName: "ellipsis.circle") }

                .accessibilityLabel("Game options")

            }

        }

        .sheet(item: $popup) { item in

            lessonPopup(item)

                .presentationDetents([.fraction(0.72), .large])

                .presentationDragIndicator(.visible)

                .presentationCornerRadius(30)

        }

        .confirmationDialog("Start this game over?", isPresented: $confirmingRestart, titleVisibility: .visible) {

            Button("Restart", role: .destructive) { restart() }

            Button("Keep playing", role: .cancel) { }

        }

        .onDisappear {

            motionTask?.cancel()

            motionInProgress = false

        }

    }

    private func phaseColor(_ stage: MitosisSession.Stage) -> Color {

        let dark = colorScheme == .dark

        switch stage {

        case .prophase: return dark ? Color(red: 0.77, green: 0.65, blue: 1) : Color(red: 0.45, green: 0.25, blue: 0.75)

        case .prometaphase: return dark ? Color(red: 0.48, green: 0.76, blue: 1) : Color(red: 0.12, green: 0.40, blue: 0.73)

        case .metaphase: return dark ? .mint : Color(red: 0.08, green: 0.45, blue: 0.38)

        case .anaphase: return dark ? Color(red: 1, green: 0.75, blue: 0.42) : Color(red: 0.65, green: 0.32, blue: 0.05)

        case .telophase: return dark ? Color(red: 1, green: 0.62, blue: 0.79) : Color(red: 0.69, green: 0.20, blue: 0.43)

        case .complete: return dark ? .mint : Color(red: 0.08, green: 0.45, blue: 0.38)

        }

    }

    private func heading(compact: Bool) -> some View {

        VStack(alignment: .leading, spacing: compact ? 4 : 7) {

            HStack(alignment: .firstTextBaseline) {

                Text(session.stage.title)

                    .font(.system(compact ? .title2 : .largeTitle, design: .serif, weight: .bold))

                    .foregroundStyle(accent)

                    .lineLimit(1)

                    .minimumScaleFactor(0.75)

                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 6)

                Text(session.stage == .complete ? "5 / 5" : "\(session.stage.rawValue + 1) / 5")

                    .font(.caption.weight(.bold).monospacedDigit())

                    .foregroundStyle(.secondary)

            }

            HStack(spacing: 6) {

                ForEach(0..<5, id: \.self) { index in

                    let stage = MitosisSession.Stage(rawValue: index) ?? .prophase

                    let done = index < session.stage.rawValue || (index == session.stage.rawValue && session.canAdvance)

                    let current = index == session.stage.rawValue

                    HStack(spacing: 4) {

                        if done { Image(systemName: "checkmark").font(.caption2.weight(.heavy)) }

                        else { Text("\(index + 1)").font(.caption2.weight(.bold)) }

                        Capsule().fill(phaseColor(stage).opacity(done || current ? 0.85 : 0.2)).frame(height: 4)

                    }

                    .foregroundStyle(phaseColor(stage))

                    .padding(.horizontal, 7)

                    .frame(maxWidth: .infinity, minHeight: compact ? 20 : 24)

                    .background(phaseColor(stage).opacity(done || current ? 0.13 : 0.04), in: Capsule())

                    .overlay(Capsule().stroke(current ? phaseColor(stage).opacity(0.6) : .clear, lineWidth: 1))

                    .accessibilityElement(children: .ignore)

                    .accessibilityLabel(stage.title)

                    .accessibilityValue(done ? "Complete" : current ? "Current phase" : "Upcoming")

                }

            }

        }

    }

    private var taskChecklist: some View {

        HStack(spacing: 6) {

            ForEach(phaseTasks) { task in

                HStack(spacing: 4) {

                    Image(systemName: task.done ? "checkmark.circle.fill" : "circle")

                        .font(.caption.weight(.bold))

                    Text(task.label)

                        .font(.system(.caption, design: .rounded, weight: .semibold))

                        .lineLimit(2)

                        .minimumScaleFactor(0.85)

                }

                .foregroundStyle(task.done ? accent : Color.secondary)

                .padding(.horizontal, 8)

                .padding(.vertical, 7)

                .frame(maxWidth: .infinity)

                .background(accent.opacity(task.done ? 0.14 : 0.05), in: RoundedRectangle(cornerRadius: 12))

                .accessibilityElement(children: .ignore)

                .accessibilityLabel(task.label)

                .accessibilityValue(task.done ? "Complete" : "Not complete")

            }

        }

    }

    private var phaseTasks: [MitosisTaskCheck] {

        switch session.stage {

        case .prophase:

            return [.init(label: "Pack DNA", done: session.condensed.count == 4),

                    .init(label: "Set Centrosome", done: session.movedPoles.count == 2)]

        case .prometaphase:

            return [.init(label: "Envelope Disassembly", done: session.envelopeOpen),

                    .init(label: "Left Microtubules", done: session.leftAttachments.count == 4),

                    .init(label: "Right Microtubules", done: session.rightAttachments.count == 4)]

        case .metaphase:

            return [.init(label: "Align", done: session.aligned.count == 4),

                    .init(label: "Checkpoint", done: session.checkpointPassed)]

        case .anaphase:

            return [.init(label: "Separate sisters", done: session.separated)]

        case .telophase:

            return [.init(label: "Left nucleus", done: session.rebuiltNuclei.contains(.left)),

                    .init(label: "Right nucleus", done: session.rebuiltNuclei.contains(.right))]

        case .complete:

            return [.init(label: "All five phases complete!", done: true)]

        }

    }

    private var playfield: some View {

        ZStack {

            RoundedRectangle(cornerRadius: 32)

                .fill(LinearGradient(

                    colors: colorScheme == .dark

                        ? [accent.opacity(0.15), Color(red: 0.19, green: 0.17, blue: 0.27)]

                        : [Color(red: 0.99, green: 0.89, blue: 0.65), Color(red: 0.98, green: 0.85, blue: 0.57)],

                    startPoint: .topLeading, endPoint: .bottomTrailing

                ))

            MitosisCellScene(session: session, onAction: perform, showsParts: showsParts)

                .padding(4)

                .frame(maxWidth: .infinity, maxHeight: .infinity)

        }

        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color(red: 0.19, green: 0.37, blue: 0.35).opacity(0.8), lineWidth: 1.5))

        .accessibilityIdentifier("mitosis-playfield")

    }

    private func dashboard(compact: Bool) -> some View {

        VStack(spacing: compact ? 8 : 12) {

            MitosisBiologyEmphasis.text(session.instruction)

                .font(.system(compact ? .subheadline : .headline, design: .rounded, weight: .bold))

                .multilineTextAlignment(.center)

                .lineLimit(3)

                .minimumScaleFactor(0.85)

                .accessibilityIdentifier("mitosis-instruction")

            taskChecklist

                .accessibilityIdentifier("mitosis-task-checklist")

            controls

            if session.needsCorrection {
                // Tap the compact bubble for the full explanation. Text can grow in the popup.
    
                Button { popup = MitosisPopup.explanation(session) } label: {
    
                    HStack(alignment: .center, spacing: 9) {
    
                        Image(systemName: session.needsCorrection ? "arrow.uturn.backward.circle.fill" : "bubble.left.fill")
    
                            .foregroundStyle(session.needsCorrection ? Color.orange : accent)
    
                        MitosisBiologyEmphasis.text(session.feedback)
    
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
    
                            .lineLimit(compact ? 2 : 3)
    
                            .multilineTextAlignment(.leading)
    
                        Spacer(minLength: 0)
    
                        Image(systemName: "info.circle")
    
                            .foregroundStyle(.secondary)
    
                    }
    
                    .foregroundStyle(.primary)
    
                    .padding(.horizontal, 12)
    
                    .padding(.vertical, compact ? 8 : 12)
    
                    .frame(maxWidth: .infinity, minHeight: 44)
    
                    .background(.background, in: RoundedRectangle(cornerRadius: 18))
    
                }
    
                .buttonStyle(.plain)
    
                .accessibilityLabel(session.feedback)
    
                .accessibilityHint("Opens the full explanation")
    
                .disabled(motionInProgress)
            }

            if session.canAdvance || session.stage == .complete {

                Button {

                    if session.stage == .complete { restart() }

                    else { popup = MitosisPopup.completed(session) }

                } label: {

                    Label(session.stage == .complete ? "Play again" : "What just happened?",

                          systemImage: session.stage == .complete ? "arrow.counterclockwise" : "checkmark.circle.fill")

                        .font(.system(.headline, design: .rounded))

                        .frame(maxWidth: .infinity, minHeight: 44)

                }

                .buttonStyle(.borderedProminent)

                .tint(accent)

                .disabled(motionInProgress)

            }

        }

        .fixedSize(horizontal: false, vertical: true)

        .accessibilityIdentifier("mitosis-controls")

    }

    @ViewBuilder private var controls: some View {

        switch session.stage {

        case .prometaphase:

            if session.envelopeOpen && !session.canAdvance {

                HStack(spacing: 10) {

                    poleButton(.left, count: session.leftAttachments.count)

                    poleButton(.right, count: session.rightAttachments.count)

                }

            }

        case .metaphase:

            if !session.checkpointPassed {

                Button { perform(.inspectCheckpoint) } label: {

                    Label("Run checkpoint", systemImage: "checkmark.shield")

                        .frame(maxWidth: .infinity, minHeight: 44)

                }

                .buttonStyle(.bordered)

                .tint(accent)

            }

        case .anaphase:

            if !session.separated {

                Button { perform(.separate) } label: {

                    Label("Separate sisters", systemImage: "arrow.left.and.right")

                        .frame(maxWidth: .infinity, minHeight: 44)

                }

                .buttonStyle(.borderedProminent)

                .tint(accent)

            }

        default: EmptyView()

        }

    }

    private func poleButton(_ pole: MitosisSession.Pole, count: Int) -> some View {

        Button { perform(.choosePole(pole)) } label: {

            HStack(spacing: 6) {

                Image(systemName: session.selectedPole == pole ? "checkmark.circle.fill" : "circle")

                Text("\(pole.rawValue) · \(count)/4")

            }

            .font(.system(.subheadline, design: .rounded, weight: .bold))

            .frame(maxWidth: .infinity, minHeight: 44)

            .foregroundStyle(session.selectedPole == pole ? accent : Color.secondary)

            .background(accent.opacity(session.selectedPole == pole ? 0.15 : 0.05), in: RoundedRectangle(cornerRadius: 15))

            .overlay(RoundedRectangle(cornerRadius: 15).stroke(session.selectedPole == pole ? accent : .clear, lineWidth: 2))

        }

        .buttonStyle(.plain)

        .accessibilityLabel("\(pole.rawValue) spindle pole, \(count) of 4 connected")

        .accessibilityAddTraits(session.selectedPole == pole ? .isSelected : [])

    }

    private func lessonPopup(_ item: MitosisPopup) -> some View {

        VStack(spacing: 0) {

            // Only the modal explanation scrolls if larger text needs more room.

            ScrollView {

                VStack(alignment: .leading, spacing: 18) {

                    HStack(spacing: 12) {

                        Image(systemName: item.advancesStage ? "checkmark.seal.fill" : "lightbulb.fill")

                            .font(.system(size: 32))

                            .foregroundStyle(accent)

                        Text(item.title)

                            .font(.system(.title2, design: .serif, weight: .bold))

                    }

                    MitosisBiologyEmphasis.text(item.explanation)

                        .font(.body)

                        .lineSpacing(4)

                    if item.takeaway == MitosisSession.Stage.prophase.lessonTakeaway {
                        MitosisBiologyEmphasis.text(item.takeaway)
    
                            .font(.system(.headline, design: .rounded))
    
                            .padding(16)
    
                            .frame(maxWidth: .infinity, alignment: .leading)
    
                            .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
                    }

                }

                .padding(24)

                .frame(maxWidth: 600)

                .frame(maxWidth: .infinity)

            }

            Button {

                popup = nil

                if item.advancesStage { perform(.advance) }

            } label: {

                Text(item.buttonTitle)

                    .font(.system(.headline, design: .rounded))

                    .frame(maxWidth: .infinity, minHeight: 44)

            }

            .buttonStyle(.borderedProminent)

            .tint(accent)

            .padding(.horizontal, 24)

            .padding(.bottom, 16)

        }

    }

    private func perform(_ action: MitosisSession.Action) {

        guard !motionInProgress else { return }

        let wasComplete = session.canAdvance

        let duration: Double

        if case .separate = action { duration = 1.2 } else { duration = 0.55 }

        withAnimation(reduceMotion ? nil : .easeInOut(duration: duration)) {

            session.send(action)

        }

        // Explain a phase only after its final visual transformation finishes.

        if !wasComplete && session.canAdvance {

            motionInProgress = true

            motionTask?.cancel()

            motionTask = Task { @MainActor in

                if !reduceMotion {

                    do { try await Task.sleep(for: .seconds(duration + 0.15)) }

                    catch { return }

                }

                guard !Task.isCancelled else { return }

                motionInProgress = false

                popup = MitosisPopup.completed(session)

            }

        }

    }

    private func restart() {

        motionTask?.cancel()

        motionInProgress = false

        popup = nil

        session.send(.restart)

    }

}

/// Capture the copy before presenting: changing stage while dismissing cannot change the popup.

private struct MitosisPopup: Identifiable {

    let id = UUID()

    let title: String

    let explanation: String

    let takeaway: String

    let buttonTitle: String

    let advancesStage: Bool

    static func completed(_ session: MitosisSession) -> Self {

        let next = MitosisSession.Stage(rawValue: session.stage.rawValue + 1)

        return Self(title: "\(session.stage.title) complete!",

                    explanation: session.stage.lessonExplanation, takeaway: session.stage.lessonTakeaway,

                    buttonTitle: session.stage == .telophase ? "Mitosis complete!" : "Next: \(next?.title ?? "Continue")",

                    advancesStage: true)

    }

    static func explanation(_ session: MitosisSession) -> Self {

        Self(

            title: session.stage.title,

            explanation: session.facts

                .map { "•  \($0)" }

                .joined(separator: "\n\n"),

            takeaway: session.stage.lessonTakeaway,

            buttonTitle: "Back to the cell",

            advancesStage: false

        )

    }

}

#Preview("Mitosis • Full screen") {

    NavigationStack { MitosisGameView() }

}

#Preview("Mitosis • Dark") {

    NavigationStack { MitosisGameView() }.preferredColorScheme(.dark)

}

private struct MitosisTaskCheck: Identifiable {

    let label: String

    let done: Bool

    var id: String { label }

}

/// Presentation only: the original words, punctuation, and line breaks are retained.
private enum MitosisBiologyEmphasis {
    private static let terms = [
        "spindle assembly checkpoint", "non-kinetochore microtubules",
        "kinetochore microtubules", "nuclear envelopes", "nuclear envelope",
        "sister chromatids", "sister chromatid", "replicated chromosomes",
        "individual chromosomes", "metaphase plate", "spindle microtubules",
        "spindle poles", "mitotic spindle", "spindle fibers", "kinetochores",
        "kinetochore", "centromeres", "centromere", "centrosomes", "centrosome",
        "centrioles", "chromosomes", "chromosome", "chromatin", "histone proteins",
        "histones", "nucleoli", "nucleolus", "cytokinesis", "cytoplasm",
        "nuclear division", "cytoplasmic division", "DNA", "S phase", "mitosis"
    ]
    private static let expression = try? NSRegularExpression(
        pattern: "(?<![A-Za-z])(?:" + terms.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|") + ")(?![A-Za-z])",
        options: .caseInsensitive)

    static func text(_ value: String) -> Text {
        guard let expression else { return Text(verbatim: value) }
        let matches = expression.matches(in: value, range: NSRange(value.startIndex..., in: value))
        var result = Text(verbatim: "")
        var cursor = value.startIndex
        for match in matches {
            guard let range = Range(match.range, in: value) else { continue }
            result = result + Text(verbatim: String(value[cursor..<range.lowerBound]))
            result = result + Text(verbatim: String(value[range])).bold()
            cursor = range.upperBound
        }
        return result + Text(verbatim: String(value[cursor...]))
    }
}
