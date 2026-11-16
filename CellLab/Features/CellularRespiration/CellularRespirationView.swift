// CellularRespirationView.swift — matches the final DNA Replication lesson layout.
import SwiftUI

@MainActor struct CellularRespirationView: View {
    @State private var session = RespirationSession()
    @State private var sheet: RespirationSheet?
    @State private var expandedStep: RespirationStep?
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
                            Text("Small steps. Big energy.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(RespirationTheme.muted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if let onPlayGame {
                            Button {
                                session.isPlaying = false
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
                    .accessibilityIdentifier("respiration-carousel")

                    RespirationCarouselControls(
                        titles: RespirationStep.allCases.map { $0.content.title },
                        index: session.step.index
                    ) { index in
                        selectCard(RespirationStep.allCases[index])
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

                    RespirationEquationView().frame(maxWidth: .infinity)

                    Button {
                        session.isPlaying = false
                        sheet = .players
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "books.vertical").font(.title3)
                            Text("Meet the key players").font(.system(.headline, design: .rounded))
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").font(.system(.body, weight: .bold))
                        }
                        .padding(20).frame(maxWidth: .infinity, minHeight: 64)
                        .background(RespirationTint.sage.color, in: RoundedRectangle(cornerRadius: 23))
                        .overlay(RoundedRectangle(cornerRadius: 23).strokeBorder(RespirationTheme.edge, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("respiration-key-players")

                    Text("Eukaryotic diagrams shown; prokaryotic locations are included in the notes. Diagrams are not to scale.")
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
            .presentationDetents([.large]).presentationDragIndicator(.visible)
            .presentationCornerRadius(30)
        }
        .task(id: RespirationClockKey(playing: session.isPlaying, reduced: reduceMotion, active: scenePhase == .active)) {
            guard session.isPlaying, !reduceMotion, scenePhase == .active else { return }
            await session.run()
        }
        .onChange(of: session.step) { _, _ in expandedStep = nil }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced { session.isPlaying = false; session.progress = 1 }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { session.isPlaying = false }
        }
        .onDisappear { session.isPlaying = false }
        .sensoryFeedback(.selection, trigger: session.step)
    }

    private func phaseCard(_ step: RespirationStep, width: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(step.content.stage)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(RespirationTheme.teal)
                    Text(step.content.title)
                        .font(.system(.title, design: .serif, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button { sheet = .diagram } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(.body, weight: .semibold)).frame(width: 40, height: 44)
                }
                .buttonStyle(.plain).accessibilityLabel("Enlarge diagram")
            }
            .frame(minHeight: 68, alignment: .top)
            .padding(.horizontal, 20).padding(.top, 20)

            RespirationScene(step: step, progress: step == session.step && !reduceMotion ? session.progress : 1,
                              background: RespirationTint.butter.color)
                .equatable()
                .frame(height: min(width * 390 / 360, 410))
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

            if expandedStep == step && session.step == step {
                RespirationBullets(items: step.content.bullets)
                    .padding(.horizontal, 20).padding(.bottom, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(RespirationTheme.ink)
        .frame(width: width).fixedSize(horizontal: false, vertical: true)
        .background(RespirationTint.butter.color, in: RoundedRectangle(cornerRadius: 27))
        .overlay(RoundedRectangle(cornerRadius: 27).strokeBorder(RespirationTheme.edge.opacity(0.65), lineWidth: 1))
        .shadow(color: RespirationTheme.ink.opacity(0.035), radius: 12, x: 0, y: 5)
        .accessibilityIdentifier("respiration-card-" + step.id)
    }

    private func selectCard(_ step: RespirationStep) {
        expandedStep = nil
        session.autoAdvance = false
        session.select(step, play: !reduceMotion)
    }

    private func toggleLesson() {
        if session.isPlaying { session.isPlaying = false; return }
        expandedStep = nil
        session.autoAdvance = true
        if session.step == .fermentation && session.progress >= 1 { session.select(.overview, play: true) }
        else if session.progress >= 1 { session.replay(play: true) }
        else { session.isPlaying = true }
    }
}

@MainActor private struct RespirationExpandedView: View {
    @Bindable var session: RespirationSession
    @State private var zoom: Double = 1
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let fittedWidth = min(proxy.size.width - 32, max(160, proxy.size.height - 220) * 360 / 390)
                VStack(spacing: 12) {
                    Picker("Cellular respiration card", selection: Binding(
                        get: { session.step },
                        set: { session.autoAdvance = false; session.select($0, play: !reduceMotion) }
                    )) {
                        ForEach(RespirationStep.allCases) { step in Text(step.content.title).tag(step) }
                    }
                    .pickerStyle(.menu).padding(.top, 8)
                    ScrollView([.horizontal, .vertical]) {
                        RespirationScene(step: session.step, progress: reduceMotion ? 1 : session.progress)
                            .frame(width: fittedWidth * zoom,
                                   height: fittedWidth * zoom * 390 / 360)
                            .padding(16)
                    }
                    .background(RespirationTheme.paper)
                    VStack(spacing: 10) {
                        Text("H⁺ = proton · e⁻ = electron")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(RespirationTheme.muted)
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
                    .foregroundStyle(RespirationTheme.ink)
                    .padding(.horizontal, 20).padding(.bottom, 12)
                }
            }
            .background(RespirationTheme.cream.ignoresSafeArea())
            .navigationTitle("Cellular respiration close-up").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .tint(RespirationTheme.ink)
        }
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
