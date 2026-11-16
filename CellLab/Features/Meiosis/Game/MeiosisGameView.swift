import SwiftUI
import Foundation

/// Matches MitosisGameView: fixed portrait/landscape playfield, checklist, controls,
/// hints, phase-completion sheet and restart. Only explanations/lab sheets scroll.
struct MeiosisGameView: View {
    @EnvironmentObject private var narration: LessonNarrator
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var session = MeiosisSession()
    @State private var popup: MeiosisPopup?
    @State private var lab: MeiosisLabSheet?
    @State private var confirmingRestart = false
    @State private var showsParts = false
    @State private var motionInProgress = false
    @State private var motionTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    private var accent: Color { phaseColor(session.stage) }
    private var background: Color {
        colorScheme == .dark ? Color(red: 0.08, green: 0.16, blue: 0.15) : Color(red: 0.99, green: 0.96, blue: 0.92)
    }
    var body: some View {
        GeometryReader { geometry in
            let landscape = geometry.size.width > geometry.size.height * 1.2
            let compact = geometry.size.height < 620
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView {
                    VStack(spacing: 16) {
                        heading(compact: true)
                        playfield.frame(height: min(max(geometry.size.width * 0.8, 260), 360))
                        dashboard(compact: true)
                    }
                    .padding(16)
                    .frame(maxWidth: 1100).frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: compact ? 8 : 14) {
                    heading(compact: compact)
                    if landscape {
                        HStack(spacing: 18) {
                            playfield.frame(maxWidth: .infinity, maxHeight: .infinity)
                            dashboard(compact: true).frame(width: min(340, geometry.size.width * 0.42))
                        }
                    } else {
                        playfield.frame(maxWidth: .infinity, maxHeight: .infinity)
                        dashboard(compact: compact)
                    }
                }
                .padding(landscape ? 12 : 16)
                .frame(maxWidth: 1100).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(background.ignoresSafeArea())
        .navigationTitle("Meiosis").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showsParts.toggle() } label: {
                    Label("Hint", systemImage: showsParts ? "tag.fill" : "tag")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                }
                .tint(accent).accessibilityAddTraits(showsParts ? .isSelected : [])
                .accessibilityIdentifier("meiosis-parts-hint").disabled(motionInProgress)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("What is happening?", systemImage: "lightbulb") { popup = .explanation(session) }
                    Button("Diversity & packaging", systemImage: "shuffle") { lab = .diversity }
                    Button("Division error lab", systemImage: "exclamationmark.magnifyingglass") { lab = .errors }
                    Button("Restart game", systemImage: "arrow.counterclockwise") { confirmingRestart = true }
                } label: { Image(systemName: "ellipsis.circle") }
                .accessibilityLabel("Game options").disabled(motionInProgress)
            }
        }
        .sheet(item: $popup, onDismiss: { narration.gameEventChanged(activeNarrationEvent) }) { item in
            lessonPopup(item).presentationDetents([.fraction(0.72), .large])
                .presentationDragIndicator(.visible).presentationCornerRadius(30)
        }
        .sheet(item: $lab, onDismiss: { narration.stop() }) { item in
            NavigationStack {
                Group {
                    switch item {
                    case .diversity: MeiosisDiversityLab(session: session)
                    case .errors: MeiosisErrorLab()
                    }
                }
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { lab = nil } } }
            }
            .presentationDetents([.large]).presentationDragIndicator(.visible)
        }
        .confirmationDialog("Start this game over?", isPresented: $confirmingRestart, titleVisibility: .visible) {
            Button("Restart", role: .destructive) { restart() }
            Button("Keep playing", role: .cancel) { }
        }
        .onChange(of: activeNarrationEvent) { _, event in narration.gameEventChanged(event) }
        .onChange(of: lab) { _, _ in narration.stop() }
        .onDisappear { narration.stop(); motionTask?.cancel(); motionInProgress = false }
    }

    private func phaseColor(_ stage: MeiosisSession.Stage) -> Color {
        let dark = colorScheme == .dark
        switch stage {
        case .interphase, .interkinesis: return dark ? .mint : Color(red: 0.08, green: 0.45, blue: 0.38)
        case .prophaseI, .prophaseII: return dark ? Color(red: 0.77, green: 0.65, blue: 1) : Color(red: 0.45, green: 0.25, blue: 0.75)
        case .metaphaseI, .metaphaseII: return dark ? Color(red: 0.48, green: 0.76, blue: 1) : Color(red: 0.12, green: 0.40, blue: 0.73)
        case .anaphaseI, .anaphaseII: return dark ? Color(red: 1, green: 0.75, blue: 0.42) : Color(red: 0.65, green: 0.32, blue: 0.05)
        case .telophaseI, .telophaseII: return dark ? Color(red: 1, green: 0.62, blue: 0.79) : Color(red: 0.69, green: 0.20, blue: 0.43)
        case .complete: return dark ? .mint : Color(red: 0.08, green: 0.45, blue: 0.38)
        }
    }
    private func heading(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(session.stage.title)
                    .font(.system(compact ? .title2 : .largeTitle, design: .serif, weight: .bold))
                    .foregroundStyle(accent).lineLimit(1).minimumScaleFactor(0.65).accessibilityAddTraits(.isHeader)
                Spacer(minLength: 6)
                Text(session.stage == .complete ? "9 / 9" : "\(session.stage.rawValue) / 9")
                    .font(.caption.weight(.bold).monospacedDigit()).foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                ForEach(1..<10, id: \.self) { index in
                    let stage = MeiosisSession.Stage(rawValue: index) ?? .interphase
                    let done = index < session.stage.rawValue || (index == session.stage.rawValue && session.canAdvance)
                    let current = index == session.stage.rawValue
                    Capsule().fill(phaseColor(stage).opacity(done || current ? 0.85 : 0.20))
                        .frame(height: compact ? 6 : 8)
                        .padding(.vertical, 5).padding(.horizontal, 3)
                        .background(phaseColor(stage).opacity(done || current ? 0.13 : 0.04), in: Capsule())
                        .overlay(Capsule().stroke(current ? phaseColor(stage).opacity(0.6) : .clear, lineWidth: 1))
                        .accessibilityLabel(stage.title)
                        .accessibilityValue(done ? "Complete" : current ? "Current phase" : "Upcoming")
                }
            }
        }
    }

    private var playfield: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32).fill(LinearGradient(
                colors: colorScheme == .dark
                    ? [accent.opacity(0.15), Color(red: 0.19, green: 0.17, blue: 0.27)]
                    : [Color(red: 0.99, green: 0.89, blue: 0.65), Color(red: 0.98, green: 0.85, blue: 0.57)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            MeiosisCellScene(session: session, onAction: perform, showsParts: showsParts)
                .padding(4).frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(!motionInProgress)
        }
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color(red: 0.19, green: 0.37, blue: 0.35).opacity(0.8), lineWidth: 1.5))
        .accessibilityIdentifier("meiosis-playfield")
    }
    private func dashboard(compact: Bool) -> some View {
        VStack(spacing: compact ? 8 : 12) {
            gameGuide(cueID: session.canAdvance ? session.completionNarrationID : session.instructionNarrationID,
                      instruction: MeiosisBiologyEmphasis.text(session.instruction)
                        .font(.system(compact ? .subheadline : .headline, design: .rounded, weight: .bold)))
            HStack(spacing: 6) {
                ForEach(phaseTasks) { task in
                    HStack(spacing: 4) {
                        Image(systemName: task.done ? "checkmark.circle.fill" : "circle").font(.caption.weight(.bold))
                        Text(task.label).font(.system(.caption, design: .rounded, weight: .semibold))
                            .lineLimit(2).minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(task.done ? accent : Color.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 7).frame(maxWidth: .infinity)
                    .background(accent.opacity(task.done ? 0.14 : 0.05), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityElement(children: .ignore).accessibilityLabel(task.label)
                    .accessibilityValue(task.done ? "Complete" : "Not complete")
                }
            }
            .accessibilityIdentifier("meiosis-task-checklist")
            controls.disabled(motionInProgress)
            if session.needsCorrection {
                Button { popup = .explanation(session) } label: {
                    HStack(spacing: 9) {
                        Image(systemName: "arrow.uturn.backward.circle.fill").foregroundStyle(.orange)
                        Text(session.feedback).font(.system(.subheadline, design: .rounded))
                            .lineLimit(compact ? 2 : 3).multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        Image(systemName: "info.circle").foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.primary).padding(12).frame(maxWidth: .infinity, minHeight: 44)
                    .background(.background, in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain).disabled(motionInProgress)
                .accessibilityLabel(session.feedback)
            }
            if session.canAdvance || session.stage == .complete {
                Button {
                    if session.stage == .complete { restart() } else { popup = .completed(session) }
                } label: {
                    Label(session.stage == .complete ? "Play again" : "What just happened?",
                          systemImage: session.stage == .complete ? "arrow.counterclockwise" : "checkmark.circle.fill")
                        .font(.system(.headline, design: .rounded)).frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent).tint(accent).disabled(motionInProgress)
            }
            if session.stage == .complete {
                Text("Precision penalties: \(session.penalties)").font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button("Diversity & packaging") { lab = .diversity }
                    Button("Error lab") { lab = .errors }
                }
                .font(.system(.subheadline, design: .rounded, weight: .semibold)).buttonStyle(.bordered).tint(accent)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private var controls: some View {
        switch session.stage {
        case .interphase:
            if !session.replicated { actionButton("Replicate DNA · S phase", icon: "doc.on.doc", action: .replicateDNA) }
            else if !session.divisionPrepared { actionButton("Prepare division", icon: "sparkles", action: .prepareDivision) }
        case .metaphaseI:
            if !session.attachmentsIComplete {
                HStack {
                    Button("Flip pair 1", systemImage: "arrow.left.arrow.right") { perform(.flipPair(0)) }
                        .disabled(pairHasConnections(0))
                    Button("Flip pair 2", systemImage: "arrow.left.arrow.right") { perform(.flipPair(1)) }
                        .disabled(pairHasConnections(1))
                }
                .font(.system(.caption, design: .rounded, weight: .bold)).buttonStyle(.bordered).tint(accent)
                HStack(spacing: 10) {
                    poleButton(.left, count: session.leftAttachments.count, total: 2)
                    poleButton(.right, count: session.rightAttachments.count, total: 2)
                }
            } else if !session.checkpointI { actionButton("Run checkpoint", icon: "checkmark.shield", action: .inspectI) }
        case .anaphaseI:
            if !session.centromeresProtected { actionButton("Keep sisters joined", icon: "lock", action: .protectCentromeres) }
            else if !session.separatedI { actionButton("Separate homologs", icon: "arrow.left.and.right", action: .separateHomologs) }
        case .telophaseI:
            if session.nucleiI.count == 2 && !session.dividedI { actionButton("Divide cytoplasm", icon: "circle.lefthalf.filled", action: .divideI) }
        case .interkinesis:
            if !session.replicationBlocked { actionButton("Block DNA replication", icon: "lock.shield", action: .blockReplication) }
            else if !session.interkinesisProteins { actionButton("Make division proteins", icon: "sparkles", action: .makeInterkinesisProteins) }
            if !session.canAdvance {
                Button("Try copying DNA again?") { perform(.attemptExtraReplication) }
                    .font(.caption).buttonStyle(.bordered).tint(.secondary)
            }
        case .metaphaseII:
            if !session.attachmentsIIComplete {
                HStack(spacing: 10) {
                    poleButton(.top, count: session.topAttachments.count, total: 4)
                    poleButton(.bottom, count: session.bottomAttachments.count, total: 4)
                }
            } else if !session.checkpointII { actionButton("Run checkpoint", icon: "checkmark.shield", action: .inspectII) }
        case .anaphaseII:
            if !session.centromeresSplit { actionButton("Release centromere cohesion", icon: "lock.open", action: .splitCentromeres) }
            else if !session.separatedII { actionButton("Separate sisters", icon: "arrow.up.and.down", action: .separateSisters) }
        case .telophaseII:
            if session.nucleiII.count == 4 {
                if !session.relaxedII { actionButton("Unpack chromosomes", icon: "wind", action: .relaxChromosomes) }
                else if !session.dividedII { actionButton("Divide both cells", icon: "square.grid.2x2", action: .divideII) }
            }
        default: EmptyView()
        }
    }
    private func actionButton(_ title: String, icon: String, action: MeiosisSession.Action) -> some View {
        Button { perform(action) } label: {
            Label(title, systemImage: icon).frame(maxWidth: .infinity, minHeight: 44)
        }
        .font(.system(.subheadline, design: .rounded, weight: .semibold)).buttonStyle(.borderedProminent).tint(accent)
    }
    private func pairHasConnections(_ pair: Int) -> Bool {
        [pair * 2, pair * 2 + 1].contains { session.leftAttachments.contains($0) || session.rightAttachments.contains($0) }
    }
    private func poleButton(_ pole: MeiosisSession.Pole, count: Int, total: Int) -> some View {
        Button { perform(.choosePole(pole)) } label: {
            HStack(spacing: 6) {
                Image(systemName: session.selectedPole == pole ? "checkmark.circle.fill" : "circle")
                Text("\(pole.rawValue) · \(count)/\(total)")
            }
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(session.selectedPole == pole ? accent : Color.secondary)
            .background(accent.opacity(session.selectedPole == pole ? 0.15 : 0.05), in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(session.selectedPole == pole ? accent : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain).accessibilityLabel("\(pole.rawValue) pole, \(count) of \(total) homologs or sisters connected")
        .accessibilityAddTraits(session.selectedPole == pole ? .isSelected : [])
    }

    private var phaseTasks: [MeiosisTaskCheck] {
        switch session.stage {
        case .interphase: [.init("Copy DNA", session.replicated), .init("Prepare", session.divisionPrepared)]
        case .prophaseI: [.init("Pack & open", session.condensedI.count == 4 && session.envelopeOpenI),
                          .init("Pair homologs", session.synapsed.count == 2), .init("Cross over", session.crossed.count == 2)]
        case .metaphaseI: [.init("Connect", session.attachmentsIComplete), .init("Double-file", session.alignedI.count == 2), .init("Inspect", session.checkpointI)]
        case .anaphaseI: [.init("Keep sisters", session.centromeresProtected), .init("Split homologs", session.separatedI)]
        case .telophaseI: [.init("Two nuclei", session.nucleiI.count == 2), .init("Two cells", session.dividedI)]
        case .interkinesis: [.init("No DNA copy", session.replicationBlocked), .init("Make proteins", session.interkinesisProteins)]
        case .prophaseII: [.init("Re-pack DNA", session.condensedII.count == 4), .init("Open envelopes", session.envelopesOpenII.count == 2)]
        case .metaphaseII: [.init("Connect", session.attachmentsIIComplete), .init("Single-file", session.alignedII.count == 4), .init("Inspect", session.checkpointII)]
        case .anaphaseII: [.init("Release cohesion", session.centromeresSplit), .init("Split sisters", session.separatedII)]
        case .telophaseII: [.init("Four nuclei", session.nucleiII.count == 4), .init("Unpack", session.relaxedII), .init("Four cells", session.dividedII)]
        case .complete: [.init("Four distinct haploid products", true)]
        }
    }
    private func lessonPopup(_ item: MeiosisPopup) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    gameGuide(cueID: session.stage == .complete ? session.instructionNarrationID : session.completionNarrationID,
                              controlID: "meiosisPopupListenButton")
                    HStack(spacing: 12) {
                        Image(systemName: item.advancesStage ? "checkmark.seal.fill" : "lightbulb.fill")
                            .font(.system(size: 32)).foregroundStyle(accent)
                        Text(item.title).font(.system(.title2, design: .serif, weight: .bold))
                    }
                    MeiosisBiologyEmphasis.text(item.explanation).font(.body).lineSpacing(4)
                    if item.showsTakeaway {
                        MeiosisBiologyEmphasis.text(item.takeaway).font(.system(.headline, design: .rounded))
                            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                            .background(accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
                    }
                }
                .padding(24).frame(maxWidth: 600).frame(maxWidth: .infinity)
            }
            Button {
                narration.gameEventChanged(nil)
                popup = nil
                if item.advancesStage { perform(.advance) }
            } label: {
                Text(item.buttonTitle).font(.system(.headline, design: .rounded)).frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent).tint(accent).padding(.horizontal, 24).padding(.bottom, 16)
        }
    }
    private func perform(_ action: MeiosisSession.Action) {
        guard !motionInProgress else { return }
        let wasComplete = session.canAdvance
        let oldStage = session.stage
        let duration: Double
        switch action {
        case .separateHomologs, .separateSisters, .divideI, .divideII: duration = 1.3
        case .crossOver: duration = 0.9
        default: duration = 0.55
        }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: duration)) { session.send(action) }
        // Lock every transformation, not just the final task: no later action can
        // interrupt a separation, opening, crossover, or chromosome alignment.
        guard !session.needsCorrection else { return }
        let explains = !wasComplete && session.canAdvance && oldStage == session.stage
        motionInProgress = true
        motionTask?.cancel()
        motionTask = Task { @MainActor in
            if !reduceMotion {
                do { try await Task.sleep(for: .seconds(duration + 0.12)) } catch { return }
            }
            guard !Task.isCancelled else { return }
            motionInProgress = false
            if explains { popup = .completed(session) }
        }
    }
    private func restart() {
        narration.resetGameGuidance()
        motionTask?.cancel(); motionInProgress = false; popup = nil
        session.send(.restart)
        narration.gameEventChanged(session.instructionNarrationID)
    }

    private var activeNarrationEvent: String? {
        guard lab == nil else { return nil }
        if let popup { return popup.advancesStage ? session.completionNarrationID : nil }
        return session.canAdvance ? nil : session.instructionNarrationID
    }

    private func gameGuide(cueID: String, controlID: String = "meiosisGameListenButton", instruction: Text? = nil) -> some View {
        LessonGuide(narrator: narration,
                    title: narration.isPlaying ? "Stop" : narration.completedCues.contains(cueID) ? "Replay instruction" : "Hear instruction",
                    cueID: cueID,
                    action: {
                        if narration.isPlaying { narration.stop() }
                        else { narration.startGameGuidance(cueID) }
                    },
                    showsStopBetweenClips: narration.mode == .game,
                    controlID: controlID, instruction: instruction, instructionID: "meiosis-instruction")
    }
}

private enum MeiosisLabSheet: String, Identifiable {
    case diversity, errors
    var id: Self { self }
}
private struct MeiosisTaskCheck: Identifiable {
    let label: String
    let done: Bool
    var id: String { label }
    init(_ label: String, _ done: Bool) { self.label = label; self.done = done }
}

enum MeiosisBiologyEmphasis {
    private static let terms = ["independent assortment", "nuclear envelopes", "nuclear envelope", "sister chromatids",
        "sister chromatid", "non-sister chromatids", "homologous chromosomes", "replicated chromosomes", "chromosome count",
        "unreplicated chromosome", "kinetochores", "centromeres", "centromere", "centrosomes", "centrosome",
        "spindle microtubules", "crossing over", "chromatin", "synapsis", "chiasmata", "haploid", "diploid", "cytokinesis",
        "DNA replication", "DNA", "S phase", "interkinesis"]
    private static let expression = try? NSRegularExpression(
        pattern: "(?<![A-Za-z])(?:" + terms.sorted { $0.count > $1.count }.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|") + ")(?![A-Za-z])", options: .caseInsensitive)
    static func text(_ value: String) -> Text {
        guard let expression else { return Text(verbatim: value) }
        var result = Text(verbatim: ""), cursor = value.startIndex
        for match in expression.matches(in: value, range: NSRange(value.startIndex..., in: value)) {
            guard let range = Range(match.range, in: value) else { continue }
            result = result + Text(verbatim: String(value[cursor..<range.lowerBound]))
            result = result + Text(verbatim: String(value[range])).bold()
            cursor = range.upperBound
        }
        return result + Text(verbatim: String(value[cursor...]))
    }
}

#Preview("Meiosis • Full screen") { NavigationStack { MeiosisGameView().environmentObject(LessonNarrator.meiosis()) } }
#Preview("Meiosis • Dark") { NavigationStack { MeiosisGameView().environmentObject(LessonNarrator.meiosis()) }.preferredColorScheme(.dark) }
