// CentralDogmaView.swift — Central Dogma in the shared CellLab lesson style.
import SwiftUI

@MainActor struct CentralDogmaView: View {
    @State private var session = CentralDogmaSession()
    @StateObject private var narration = LessonNarrator.centralDogma()
    @State private var overviewSession = CentralDogmaSession(step: .overview)
    @State private var sheet: CentralDogmaSheet?
    @State private var expandedStep: CentralDogmaStep?
    @State private var cardHeights: [String: CGFloat] = [:]
    @State private var showingGame = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    private let onPlayGame: (() -> Void)?

    init(onPlayGame: (() -> Void)? = nil) { self.onPlayGame = onPlayGame }

    private var clockActive: Bool {
        scenePhase == .active && sheet != .diagram && sheet != .overviewDiagram && !showingGame
    }
    private var animationTitle: String {
        if reduceMotion { return "Still illustrations" }
        if session.isPlaying { return "Pause animation" }
        if session.progress >= 1 { return "Replay animation" }
        return session.progress > 0 ? "Resume animation" : "Watch animation"
    }

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = min(proxy.size.width, 680)
            let cardWidth = max(1, contentWidth - 36)
            ScrollView {
                VStack(spacing: 14) {
                    VStack(spacing: 0) {
                        header
                        overviewGuide.padding(.top, 8).padding(.bottom, 10)
                        TabView(selection: Binding(get: { session.step }, set: selectCard)) {
                            ForEach(CentralDogmaStep.carouselCases) { step in
                                phaseCard(step, width: cardWidth).tag(step)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: cardHeights[session.step.id] ?? min(cardWidth * 420 / 360, 400) + 230)
                        .onPreferenceChange(CentralDogmaLessonHeights.self) { heights in
                            cardHeights.merge(heights, uniquingKeysWith: { _, new in new })
                        }
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: session.step)
                        .accessibilityIdentifier("central-dogma-carousel")
                        phaseDots.padding(.top, 8)
                    }

                    phaseCard(.overview, width: cardWidth)

                    CentralDogmaLegend()
                        .padding(12).frame(maxWidth: .infinity)
                        .background(CentralDogmaTheme.paper, in: RoundedRectangle(cornerRadius: 18))

                    Button {
                        narration.stop()
                        session.isPlaying = false
                        session.autoAdvance = false
                        sheet = .players
                    } label: {
                        HStack {
                            Label("Meet the key players", systemImage: "text.book.closed.fill")
                            Spacer(minLength: 4)
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(.headline, design: .rounded))
                        .padding(18).frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(MeiPalette.ink)
                        .background(MeiPalette.mint, in: RoundedRectangle(cornerRadius: 22))
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(MeiPalette.ink.opacity(0.7), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("central-dogma-key-players")

                    Text("Eukaryotic sequence shown. Sequence examples are shortened; diagrams are not to scale.")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .foregroundStyle(MeiPalette.text)
                .padding(.horizontal, 18).padding(.top, 6).padding(.bottom, 18)
                .frame(width: contentWidth).frame(maxWidth: .infinity)
            }
        }
        .background(MeiPalette.paper.ignoresSafeArea())
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .tint(MeiPalette.teal)
        .environmentObject(narration)
        .navigationDestination(isPresented: $showingGame) { CentralDogmaGameView().environmentObject(narration) }
        .sheet(item: $sheet, onDismiss: narration.stop) { route in
            Group {
                switch route {
                case .diagram: CentralDogmaExpandedView(session: session)
                case .overviewDiagram: CentralDogmaExpandedView(session: overviewSession, steps: [.overview])
                case .players: CentralDogmaKeyPlayersView(initialPlayerID: session.step.content.playerID)
                }
            }
            .environmentObject(narration)
            .presentationDetents([.large]).presentationDragIndicator(.visible)
            .presentationCornerRadius(30)
        }
        .task(id: CentralDogmaClockKey(playing: session.isPlaying, reduced: reduceMotion, active: clockActive)) {
            guard session.isPlaying, !reduceMotion, clockActive else { return }
            await session.run()
        }
        .onAppear {
            narration.stop()
            narration.selectPhase(session.step.narrationID)
            if reduceMotion { session.isPlaying = false; session.progress = 1 }
        }
        .onChange(of: session.step) { _, step in
            expandedStep = nil
            narration.selectPhase(step.narrationID)
        }
        .onChange(of: sheet) { _, _ in narration.stop() }
        .onChange(of: narration.mode) { _, mode in
            if mode == .lesson { session.autoAdvance = false }
        }
        .onChange(of: narration.isPlaying) { _, playing in
            if playing && narration.mode == .lesson && narration.currentCueID == session.step.narrationID {
                session.replay(play: !reduceMotion)
            }
        }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced { session.isPlaying = false; session.progress = 1 }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { session.isPlaying = false; narration.stop() }
        }
        .onDisappear {
            narration.stop()
            if sheet == nil { session.isPlaying = false; session.autoAdvance = false }
        }
        .sensoryFeedback(.selection, trigger: session.step)
        .alert("Audio unavailable", isPresented: Binding(
            get: { narration.errorMessage != nil }, set: { if !$0 { narration.errorMessage = nil } }
        )) { Button("OK", role: .cancel) { narration.errorMessage = nil } }
        message: { Text(narration.errorMessage ?? "Please try again.") }
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Central Dogma")
                .font(.system(.title, design: .serif, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Text("DNA → RNA → Protein")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top) {
                headerTitle.fixedSize(horizontal: true, vertical: true)
                Spacer(minLength: 12)
                gameButton
            }
            VStack(alignment: .leading, spacing: 8) {
                headerTitle
                HStack { Spacer(); gameButton }
            }
        }
    }

    private var gameButton: some View {
        Button {
            narration.stop()
            session.isPlaying = false
            session.autoAdvance = false
            if let onPlayGame { onPlayGame() }
            else { showingGame = true }
        } label: {
            Label("Play game", systemImage: "play.fill")
                .font(.system(.headline, design: .rounded)).frame(minHeight: 36)
                .foregroundStyle(.white)
        }
        .buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel("Play the Central Dogma game")
        .accessibilityIdentifier("central-dogma-play-game")
    }

    private var overviewGuide: some View {
        LessonGuide(narrator: narration, title: narration.lessonButtonTitle,
                    cueID: narration.isPlaying ? (narration.currentCueID ?? narration.overviewCueID)
                        : (narration.hasBegunLesson ? session.step.narrationID : narration.overviewCueID),
                    action: narration.toggleLesson,
                    showsStopBetweenClips: narration.mode == .lesson,
                    replayOverview: narration.playOverview,
                    controlID: "central-dogma-overview", layoutTitle: "Hear overview")
    }

    private var animationControl: some View {
        HStack(spacing: 4) {
            Button {
                session.autoAdvance = false
                session.togglePlayback()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: session.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .semibold)).frame(width: 18)
                    Text(animationTitle)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain).disabled(reduceMotion)
            .accessibilityLabel(animationTitle)
            .accessibilityValue("\(Int(session.progress * 100)) percent")
            .accessibilityIdentifier("central-dogma-animate")
            Menu {
                Button("Replay this step", systemImage: "arrow.counterclockwise") {
                    session.autoAdvance = false
                    session.replay(play: true)
                }
                .disabled(reduceMotion)
                Button("Play all steps", systemImage: "play.rectangle.on.rectangle") {
                    narration.stop()
                    session.autoAdvance = true
                    if session.step == .finishing && session.progress >= 1 { session.select(.transcriptionStart, play: true) }
                    else if session.progress >= 1 { session.replay(play: true) }
                    else { session.isPlaying = true }
                }
                .disabled(reduceMotion)
            } label: {
                Image(systemName: "ellipsis.circle").frame(width: 44, height: 44)
            }
            .accessibilityLabel("Animation options")
            .accessibilityIdentifier("central-dogma-animation-options")
        }
    }

    private var phaseDots: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) { dots(CentralDogmaStep.carouselCases) }.fixedSize()
            VStack(spacing: 0) {
                HStack(spacing: 0) { dots(Array(CentralDogmaStep.carouselCases.prefix(5))) }
                HStack(spacing: 0) { dots(Array(CentralDogmaStep.carouselCases.suffix(4))) }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func dots(_ steps: [CentralDogmaStep]) -> some View {
        ForEach(steps) { step in
            Button { selectCard(step) } label: {
                Capsule()
                    .fill(session.step == step ? MeiPalette.teal : MeiPalette.text.opacity(0.18))
                    .frame(width: session.step == step ? 22 : 7, height: 7)
                    .frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(step.content.title)
            .accessibilityValue(session.step == step ? "Selected" : "")
            .accessibilityIdentifier("central-dogma-step-\(step.id)")
        }
    }

    private func cardColor(_ step: CentralDogmaStep) -> Color {
        switch step {
        case .overview, .folding: MeiPalette.mint
        case .transcriptionStart, .transcriptionEnd: MeiPalette.butter
        case .transcriptionBuild, .processing: DNAReplicationTint.blue.color
        case .translationStart, .translationEnd: MeiPalette.lilac
        case .translationBuild, .finishing: MeiPalette.blush
        }
    }

    private func phaseCard(_ step: CentralDogmaStep, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(step.content.stage.uppercased())
                Spacer(minLength: 4)
                if let index = step.carouselIndex {
                    Text("\(index + 1) / \(CentralDogmaStep.carouselCases.count)")
                        .fixedSize()
                }
            }
            .font(.system(.caption, design: .rounded, weight: .bold))
            .foregroundStyle(MeiPalette.ink.opacity(0.72))
            HStack(alignment: .top, spacing: 8) {
                Text(step.content.title)
                    .font(.system(.title, design: .serif, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                if step == .overview {
                    NarrationSpeakerButton(cueID: step.narrationID, title: "the big picture")
                }
                Button {
                    session.autoAdvance = false
                    if step == .overview {
                        overviewSession.select(.overview, play: false)
                        sheet = .overviewDiagram
                    } else {
                        sheet = .diagram
                    }
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Enlarge diagram")
                .accessibilityIdentifier("central-dogma-enlarge-\(step.id)")
            }
            CentralDogmaScene(step: step, progress: step == session.step && !reduceMotion ? session.progress : 1,
                              background: cardColor(step))
                .equatable()
                .frame(height: min(max(1, width - 32) * 420 / 360, 400))
                .frame(maxWidth: .infinity)
            if step == session.step { animationControl }
            DisclosureGroup(isExpanded: Binding(
                get: { expandedStep == step },
                set: { expandedStep = $0 ? step : nil }
            )) {
                CentralDogmaBullets(items: step.content.bullets)
                    .padding(12)
                    .background(.white.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 4)
            } label: {
                Text(step.content.mnemonic)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 44, alignment: .leading)
            }
            .tint(MeiPalette.ink)
            .accessibilityIdentifier("central-dogma-description-\(step.id)")
        }
        .padding(16).foregroundStyle(MeiPalette.ink)
        .frame(width: width).fixedSize(horizontal: false, vertical: true)
        .background(cardColor(step), in: RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(MeiPalette.ink.opacity(0.75), lineWidth: 1.5))
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: CentralDogmaLessonHeights.self, value: [step.id: proxy.size.height])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("central-dogma-card-" + step.id)
    }

    private func selectCard(_ step: CentralDogmaStep) {
        guard step != session.step else { return }
        expandedStep = nil
        session.autoAdvance = false
        session.select(step, play: !reduceMotion)
    }
}

@MainActor private struct CentralDogmaExpandedView: View {
    @Bindable var session: CentralDogmaSession
    var steps: [CentralDogmaStep] = CentralDogmaStep.carouselCases
    @State private var zoom: Double = 1
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let fittedWidth = max(1, min(proxy.size.width - 32, max(160, proxy.size.height - 220) * 360 / 420))
                VStack(spacing: 12) {
                    if steps.count > 1 {
                        Picker("Central Dogma card", selection: Binding(
                            get: { session.step },
                            set: { session.autoAdvance = false; session.select($0, play: !reduceMotion) }
                        )) {
                            ForEach(steps) { step in Text(step.content.title).tag(step) }
                        }
                        .pickerStyle(.menu).padding(.top, 8)
                    }
                    ScrollView([.horizontal, .vertical]) {
                        CentralDogmaScene(step: session.step, progress: reduceMotion ? 1 : session.progress)
                            .frame(width: fittedWidth * zoom,
                                   height: fittedWidth * zoom * 420 / 360)
                            .padding(16)
                    }
                    .background(CentralDogmaTheme.paper)
                    VStack(spacing: 10) {
                        CentralDogmaLegend()
                        HStack {
                            Image(systemName: "minus.magnifyingglass")
                            Slider(value: $zoom, in: 1...2.6).accessibilityLabel("Diagram zoom")
                            Image(systemName: "plus.magnifyingglass")
                        }
                        HStack(spacing: 12) {
                            Button {
                                if let previous = session.step.previous { session.autoAdvance = false; session.select(previous, play: !reduceMotion) }
                            } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                            .disabled(session.step.previous == nil).accessibilityLabel("Previous card")
                            Button { session.autoAdvance = false; session.togglePlayback() } label: {
                                Label(session.isPlaying ? "Pause animation" : "Animate",
                                      systemImage: session.isPlaying ? "pause.fill" : "play.fill")
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .disabled(reduceMotion)
                            Button { session.autoAdvance = false; session.replay(play: !reduceMotion) } label: {
                                Image(systemName: "arrow.counterclockwise").frame(width: 44, height: 44)
                            }
                            .disabled(reduceMotion).accessibilityLabel("Replay this card")
                            Button {
                                if let next = session.step.next { session.autoAdvance = false; session.select(next, play: !reduceMotion) }
                            } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                            .disabled(session.step.next == nil).accessibilityLabel("Next card")
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(CentralDogmaTheme.ink)
                    .padding(.horizontal, 20).padding(.bottom, 12)
                }
            }
            .background(CentralDogmaTheme.cream.ignoresSafeArea())
            .navigationTitle("Central Dogma close-up").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("central-dogma-diagram-done")
                }
            }
            .tint(CentralDogmaTheme.ink)
        }
        .task(id: CentralDogmaClockKey(playing: session.isPlaying, reduced: reduceMotion,
                                      active: scenePhase == .active)) {
            guard session.isPlaying, !reduceMotion, scenePhase == .active else { return }
            await session.run()
        }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced { session.isPlaying = false; session.progress = 1 }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { session.isPlaying = false }
        }
    }
}

private struct CentralDogmaLessonHeights: PreferenceKey {
    static var defaultValue: [String: CGFloat] { [:] }
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: max)
    }
}

private struct CentralDogmaClockKey: Hashable {
    let playing, reduced, active: Bool
}
private enum CentralDogmaSheet: String, Identifiable {
    case diagram, overviewDiagram, players
    var id: String { rawValue }
}

#Preview("Central Dogma") { NavigationStack { CentralDogmaView() } }
