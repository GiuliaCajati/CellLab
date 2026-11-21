// CellularRespirationView.swift — matches the final DNA Replication lesson layout.
import SwiftUI

@MainActor struct CellularRespirationView: View {
    @State private var session = RespirationSession()
    @State private var sheet: RespirationSheet?
    @State private var expandedStep: RespirationStep?
    @StateObject private var narration = LessonNarrator.respiration()
    @State private var hasStartedOverview = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    private let onPlayGame: (() -> Void)?

    // Leave nil until the actual Cellular respiration game is available.
    init(onPlayGame: (() -> Void)? = nil) { self.onPlayGame = onPlayGame }

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = min(proxy.size.width, 580)
            let cardWidth = max(240, contentWidth - 40)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cellular respiration")
                                .font(.system(.largeTitle, design: .serif, weight: .bold))
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.isHeader)
                            Text("Follow food’s energy from glucose to ATP.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(RespirationTheme.muted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if let onPlayGame {
                            Button {
                                session.isPlaying = false
                                narration.stop()
                                onPlayGame()
                            } label: {
                                Label("Play", systemImage: "play.fill")
                                    .font(.system(.headline, design: .rounded))
                                    .padding(.horizontal, 17).frame(minHeight: 50)
                                    .background(RespirationTheme.teal, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Play the Cellular respiration game")
                        }
                    }

                    LessonGuide(narrator: narration,
                                title: narration.isPlaying ? "Stop" : hasStartedOverview ? narration.lessonButtonTitle : "Hear overview",
                                cueID: narration.isPlaying ? (narration.currentCueID ?? narration.overviewCueID)
                                    : (hasStartedOverview ? session.step.narrationID : narration.overviewCueID),
                                action: {
                                    if narration.isPlaying || narration.isScheduled { narration.stop() }
                                    else if !hasStartedOverview { playOverview() }
                                    else { narration.toggleLesson() }
                                },
                                showsStopBetweenClips: narration.mode == .lesson,
                                replayOverview: playOverview,
                                controlID: "respiration-listen", layoutTitle: "Hear overview")

                    phaseCard(session.step, width: cardWidth)
                    .id(session.step)
                    .transition(.opacity)
                    .simultaneousGesture(DragGesture(minimumDistance: 24).onEnded { value in
                        let x = value.translation.width
                        guard abs(x) > 50, abs(x) > abs(value.translation.height) * 1.5 else { return }
                        if x < 0, let next = session.step.next { selectCard(next) }
                        if x > 0, let previous = session.step.previous { selectCard(previous) }
                    })
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: expandedStep)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: session.step)

                    RespirationCarouselControls(
                        titles: RespirationStep.slides.map { $0.content.title },
                        index: session.step.slideIndex
                    ) { index in
                        selectCard(RespirationStep.slides[index])
                    }

                    Button(action: toggleLesson) {
                        Label(session.isPlaying ? "Pause animation" : "Animate steps",
                              systemImage: session.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .padding(.horizontal, 18).frame(minHeight: 44)
                            .background(RespirationTint.sage.color, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(reduceMotion)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("respiration-animate")

                    bigPicture(width: cardWidth)

                    Button {
                        session.isPlaying = false
                        sheet = .players
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "books.vertical").font(.system(size: 20)).frame(width: 24)
                            Text("Meet the key players")
                                .font(.system(.headline, design: .rounded))
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").font(.system(size: 15, weight: .bold))
                        }
                        .padding(20).frame(maxWidth: .infinity, minHeight: 64)
                        .background(RespirationTint.sage.color, in: RoundedRectangle(cornerRadius: 23))
                        .overlay(RoundedRectangle(cornerRadius: 23).strokeBorder(RespirationTheme.edge, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("respiration-key-players")

                    Text("Linked beads show carbon counts. Diagrams are simplified and not to scale; location notes include prokaryotes.")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(RespirationTheme.muted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .foregroundStyle(RespirationTheme.ink)
                .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 28)
                .frame(width: contentWidth).frame(maxWidth: .infinity)
            }
        }
        .background(RespirationTheme.cream.ignoresSafeArea())
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .tint(RespirationTheme.ink)
        .sheet(item: $sheet) { route in
            Group {
                switch route {
                case .diagram: RespirationExpandedView(session: session)
                case .players: CellularRespirationKeyPlayersView(initialPlayerID: session.step.content.playerID)
                }
            }
            .environmentObject(narration)
            .presentationDetents([.large]).presentationDragIndicator(.visible)
            .presentationCornerRadius(30)
        }
        .task(id: RespirationClockKey(playing: session.isPlaying, reduced: reduceMotion, active: scenePhase == .active)) {
            guard session.isPlaying, !reduceMotion, scenePhase == .active else { return }
            await session.run()
        }
        .environmentObject(narration)
        .onChange(of: session.step) { _, step in
            expandedStep = nil
            narration.selectPhase(step.narrationID)
        }
        .onChange(of: sheet) { _, _ in narration.stop(); session.isPlaying = false }
        .onChange(of: narration.mode) { _, mode in
            if mode == .lesson { session.autoAdvance = false }
        }
        .onChange(of: narration.currentCueID) { _, _ in syncAnimationToNarration() }
        .onChange(of: narration.isPlaying) { _, _ in syncAnimationToNarration() }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced { session.isPlaying = false; session.progress = 1 }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { session.isPlaying = false; narration.stop() }
        }
        .onDisappear { session.isPlaying = false; narration.stop() }
        .alert("Audio unavailable", isPresented: Binding(
            get: { narration.errorMessage != nil }, set: { if !$0 { narration.errorMessage = nil } }
        )) { Button("OK", role: .cancel) { narration.errorMessage = nil } }
        message: { Text(narration.errorMessage ?? "Please try again.") }
        .sensoryFeedback(.selection, trigger: session.step)
    }

    private func phaseCard(_ step: RespirationStep, width: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(step.content.stage)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(step.accent)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(RespirationTheme.paper.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
                    Text(step.content.title)
                        .font(.system(.title, design: .serif, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(step.location)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(RespirationTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button { sheet = .diagram } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(.body, weight: .semibold)).frame(width: 40, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain).accessibilityLabel("Enlarge diagram")
            }
            .frame(minHeight: 68, alignment: .top)
            .padding(.horizontal, 20).padding(.top, 20)

            RespirationScene(step: step, progress: step == session.step && !reduceMotion ? session.progress : 1,
                              background: .clear)
                .equatable()
                .frame(height: min(width * 330 / 360, 400))
                .frame(maxWidth: .infinity)

            Button {
                session.isPlaying = false
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                    expandedStep = expandedStep == step ? nil : step
                }
            } label: {
                HStack(spacing: 12) {
                    Text(step.content.mnemonic)
                        .font(.system(.headline, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: expandedStep == step ? "chevron.down" : "chevron.right")
                        .font(.system(.body, weight: .bold))
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 20).padding(.bottom, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(step.content.mnemonic + ". Show or hide explanation")
            .accessibilityValue(expandedStep == step ? "Expanded" : "Collapsed")
            .accessibilityIdentifier("respiration-explanation")

            if expandedStep == step && session.step == step {
                RespirationBullets(items: step.content.bullets)
                    .padding(.horizontal, 20).padding(.bottom, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(RespirationTheme.ink)
        .frame(width: width).fixedSize(horizontal: false, vertical: true)
        .background(LinearGradient(colors: [step.tint.opacity(0.9), step.tint.opacity(0.45)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 27))
        .overlay(RoundedRectangle(cornerRadius: 27).strokeBorder(step.accent.opacity(0.45), lineWidth: 1))
        .shadow(color: RespirationTheme.ink.opacity(0.035), radius: 12, x: 0, y: 5)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("respiration-card-" + step.id)
    }

    private func bigPicture(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Text("The big picture")
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                NarrationSpeakerButton(cueID: "reference.big-picture", title: "the big picture")
            }
            Text(RespirationStep.overview.content.mnemonic)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(RespirationTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
            RespirationScene(step: .overview, progress: 1, background: .clear)
                .frame(height: min(max(0, width - 36) * RespirationScene.overviewSize.height / RespirationScene.overviewSize.width,
                                   RespirationScene.overviewSize.height))
            RespirationEquationView(showsNarration: true)
            DisclosureGroup("How cells use the energy") {
                RespirationBullets(items: RespirationStep.overview.content.bullets)
                    .padding(.top, 12)
            }
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .environment(\.colorScheme, .light)
        }
        .padding(18)
        .frame(width: width, alignment: .leading)
        .background(LinearGradient(colors: [RespirationTint.blue.color.opacity(0.4), RespirationTheme.paper],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 27))
        .overlay(RoundedRectangle(cornerRadius: 27).strokeBorder(RespirationTheme.edge.opacity(0.3)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("respiration-big-picture")
    }

    private func selectCard(_ step: RespirationStep) {
        expandedStep = nil
        session.autoAdvance = false
        session.select(step, play: !reduceMotion)
    }

    private func toggleLesson() {
        narration.stop()
        if session.isPlaying { session.isPlaying = false; return }
        expandedStep = nil
        session.autoAdvance = true
        if session.step == .fermentation && session.progress >= 1 { session.select(.glycolysis, play: true) }
        else if session.progress >= 1 { session.replay(play: true) }
        else { session.isPlaying = true }
    }

    private func playOverview() {
        hasStartedOverview = true
        session.isPlaying = false
        session.autoAdvance = false
        narration.playOverview()
    }

    private func syncAnimationToNarration() {
        guard narration.isPlaying else { return }
        session.autoAdvance = false
        guard narration.mode == .lesson, narration.currentCueID == session.step.narrationID else {
            session.isPlaying = false
            return
        }
        session.replay(play: !reduceMotion)
    }
}

@MainActor private struct RespirationExpandedView: View {
    @EnvironmentObject private var narration: LessonNarrator
    @Bindable var session: RespirationSession
    @State private var zoom: Double = 1
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let fittedWidth = min(max(0, proxy.size.width - 32), max(160, proxy.size.height - 220) * 360 / 330)
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Menu {
                            Picker("Cellular respiration card", selection: Binding(
                                get: { session.step },
                                set: { narration.stop(); session.autoAdvance = false; session.select($0, play: !reduceMotion) }
                            )) {
                                ForEach(RespirationStep.slides) { step in Text(step.content.title).tag(step) }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "rectangle.stack").font(.system(size: 18))
                                Text(dynamicTypeSize.isAccessibilitySize
                                     ? "\(session.step.slideIndex + 1) / \(RespirationStep.slides.count)"
                                     : "Card \(session.step.slideIndex + 1) of \(RespirationStep.slides.count)")
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.down").font(.system(size: 14, weight: .semibold))
                            }
                            .frame(minHeight: 44).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(RespirationTheme.ink)
                        .accessibilityLabel("Choose respiration card")
                        .accessibilityValue(session.step.content.title)
                        .accessibilityIdentifier("respiration-diagram-card")
                        NarrationSpeakerButton(cueID: session.step.narrationID, title: session.step.content.title)
                    }
                    .padding(.horizontal, 20).padding(.top, 8)
                    ScrollView([.horizontal, .vertical]) {
                        RespirationScene(step: session.step, progress: reduceMotion ? 1 : session.progress)
                            .frame(width: fittedWidth * zoom,
                                   height: fittedWidth * zoom * 330 / 360)
                            .padding(16)
                    }
                    .background(RespirationTheme.paper)
                    VStack(spacing: 10) {
                        Text("H⁺: proton · e⁻: electron")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(RespirationTheme.muted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack {
                            Image(systemName: "minus.magnifyingglass").font(.system(size: 20))
                            Slider(value: $zoom, in: 1...2.6).accessibilityLabel("Diagram zoom")
                            Image(systemName: "plus.magnifyingglass").font(.system(size: 20))
                        }
                        HStack(spacing: 12) {
                            Button {
                                if let previous = session.step.previous { narration.stop(); session.autoAdvance = false; session.select(previous, play: !reduceMotion) }
                            } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                            .disabled(session.step.previous == nil).accessibilityLabel("Previous card")
                            Button { session.autoAdvance = false; session.togglePlayback() } label: {
                                Group {
                                    if dynamicTypeSize.isAccessibilitySize {
                                        Image(systemName: session.isPlaying ? "pause.fill" : "play.fill")
                                    } else {
                                        Label(session.isPlaying ? "Pause" : "Animate",
                                              systemImage: session.isPlaying ? "pause.fill" : "play.fill")
                                    }
                                }
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .accessibilityLabel(session.isPlaying ? "Pause animation" : "Animate this card")
                            .disabled(reduceMotion)
                            Button { session.autoAdvance = false; session.replay(play: !reduceMotion) } label: {
                                Image(systemName: "arrow.counterclockwise").frame(width: 44, height: 44)
                            }
                            .disabled(reduceMotion).accessibilityLabel("Replay this card")
                            Button {
                                if let next = session.step.next { narration.stop(); session.autoAdvance = false; session.select(next, play: !reduceMotion) }
                            } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                            .disabled(session.step.next == nil).accessibilityLabel("Next card")
                        }
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .buttonStyle(.plain)
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(RespirationTheme.ink)
                    .padding(.horizontal, 20).padding(.bottom, 12)
                }
            }
            .background(RespirationTheme.cream.ignoresSafeArea())
            .navigationTitle("Respiration").navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(RespirationTheme.cream, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .tint(RespirationTheme.ink)
        }
        .onDisappear { narration.stop() }
    }
}

private struct RespirationClockKey: Hashable {
    let playing, reduced, active: Bool
}
private enum RespirationSheet: String, Identifiable {
    case diagram, players
    var id: String { rawValue }
}

#Preview("Cellular respiration") { NavigationStack { CellularRespirationView() } }
