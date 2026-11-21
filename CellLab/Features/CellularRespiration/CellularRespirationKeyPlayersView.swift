// CellularRespirationKeyPlayersView.swift — full artwork, natural card heights.
import SwiftUI

@MainActor struct CellularRespirationKeyPlayersView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedIndex: Int
    @StateObject private var narration: LessonNarrator
    @State private var hasStartedIntroduction = false
    @Environment(\.scenePhase) private var scenePhase

    init(initialPlayerID: String? = nil) {
        let index = RespirationPlayer.all.firstIndex { $0.id == initialPlayerID } ?? 0
        _selectedIndex = State(initialValue: index)
        _narration = StateObject(wrappedValue: .respiration(initialPhaseID: RespirationPlayer.all[index].narrationID,
                                                         overviewCueID: "players.introduction"))
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let width = min(max(proxy.size.width, 240), 580)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meet the key players")
                                .font(.system(.largeTitle, design: .serif, weight: .bold))
                                .foregroundStyle(RespirationTheme.ink)
                                .accessibilityAddTraits(.isHeader)
                            if !dynamicTypeSize.isAccessibilitySize {
                                Text("Swipe to meet the energy-making crew.")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(RespirationTheme.muted)
                            }
                        }

                        LessonGuide(narrator: narration,
                                    title: narration.isPlaying ? "Stop" : hasStartedIntroduction ? narration.lessonButtonTitle : "Hear key players",
                                    cueID: narration.isPlaying ? (narration.currentCueID ?? "players.introduction")
                                        : (hasStartedIntroduction ? RespirationPlayer.all[selectedIndex].narrationID : "players.introduction"),
                                    action: {
                                        if narration.isPlaying || narration.isScheduled { narration.stop() }
                                        else if !hasStartedIntroduction {
                                            hasStartedIntroduction = true
                                            narration.playOverview()
                                        } else { narration.playPhase() }
                                    },
                                    showsStopBetweenClips: narration.mode == .lesson,
                                    controlID: "respiration-players-listen", layoutTitle: "Hear key players")
                            .foregroundStyle(RespirationTheme.ink)

                        card(RespirationPlayer.all[selectedIndex], width: width - 40)
                            .id(selectedIndex)
                            .transition(.opacity)
                            .simultaneousGesture(DragGesture(minimumDistance: 24).onEnded { value in
                                let x = value.translation.width
                                guard abs(x) > 50, abs(x) > abs(value.translation.height) * 1.5 else { return }
                                move(to: selectedIndex + (x < 0 ? 1 : -1))
                            })
                            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: selectedIndex)

                        RespirationCarouselControls(
                            titles: RespirationPlayer.all.map { $0.title },
                            index: selectedIndex,
                            identifierPrefix: "respiration-players",
                            onSelect: { move(to: $0) }
                        )
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 28)
                    .frame(width: width).frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .background(RespirationTheme.cream.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .accessibilityIdentifier("respiration-players-done")
                }
            }
            .tint(RespirationTheme.ink)
        }
        .environmentObject(narration)
        .onChange(of: selectedIndex) { _, index in narration.selectPhase(RespirationPlayer.all[index].narrationID) }
        .onChange(of: scenePhase) { _, state in if state != .active { narration.stop() } }
        .onDisappear { narration.stop() }
        .alert("Audio unavailable", isPresented: Binding(
            get: { narration.errorMessage != nil }, set: { if !$0 { narration.errorMessage = nil } }
        )) { Button("OK", role: .cancel) { narration.errorMessage = nil } }
        message: { Text(narration.errorMessage ?? "Please try again.") }
    }

    private func card(_ player: RespirationPlayer, width: CGFloat) -> some View {
        let artWidth = width - 36
        let artHeight = min(artWidth * 0.78, 270)
        return VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(RespirationTheme.tint(player.tint).opacity(0.75))
                if let asset = player.asset {
                    Image(asset)
                        .resizable().scaledToFit()
                        .frame(width: max(0, artWidth - 32), height: max(0, artHeight - 32))
                } else {
                    RespirationScene(step: player.scene, progress: 1,
                                      background: .clear, illustrationID: player.id)
                        .frame(width: artWidth, height: artHeight)
                }
            }
            .frame(width: artWidth, height: artHeight)
            .accessibilityHidden(true)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 9) {
                    Text(player.caption)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(RespirationTheme.teal)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(player.title)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(RespirationTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                NarrationSpeakerButton(cueID: player.narrationID, title: player.title)
            }
            RespirationBullets(items: player.bullets)
        }
        .padding(18).frame(width: width, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .background(LinearGradient(colors: [RespirationTheme.paper, RespirationTheme.tint(player.tint).opacity(0.2)],
                                   startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(RespirationTheme.tint(player.tint), lineWidth: 2))
        .shadow(color: RespirationTheme.ink.opacity(0.035), radius: 12, x: 0, y: 5)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("respiration-player-" + player.id)
    }

    private func move(to index: Int) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            selectedIndex = min(max(0, index), RespirationPlayer.all.count - 1)
        }
    }
}

#Preview("Energy-making crew") { CellularRespirationKeyPlayersView() }
