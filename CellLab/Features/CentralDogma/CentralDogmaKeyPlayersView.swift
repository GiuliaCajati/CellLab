// CentralDogmaKeyPlayersView.swift — full artwork, natural card heights.
import SwiftUI

@MainActor struct CentralDogmaKeyPlayersView: View {
    @EnvironmentObject private var narration: LessonNarrator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedIndex: Int
    @State private var cardHeights: [String: CGFloat] = [:]

    init(initialPlayerID: String? = nil) {
        _selectedIndex = State(initialValue: CentralDogmaPlayer.all.firstIndex { $0.id == initialPlayerID } ?? 0)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let width = max(1, min(proxy.size.width, 680))
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meet the key players")
                                .font(.system(.largeTitle, design: .serif, weight: .bold))
                                .foregroundStyle(CentralDogmaTheme.ink)
                                .accessibilityAddTraits(.isHeader)
                            Text("Swipe to meet the protein-making crew.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(CentralDogmaTheme.muted)
                        }
                        .padding(.horizontal, 20)

                        LessonGuide(narrator: narration,
                                    title: narration.isPlaying ? "Stop" : "Hear introduction",
                                    cueID: "reference.players",
                                    action: {
                                        if narration.isPlaying { narration.stop() }
                                        else { narration.playStandalone("reference.players") }
                                    },
                                    controlID: "central-dogma-vocabulary-listen")
                            .padding(.horizontal, 20)

                        TabView(selection: $selectedIndex) {
                            ForEach(Array(CentralDogmaPlayer.all.enumerated()), id: \.element.id) { index, player in
                                card(player, width: max(1, width - 40)).tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: cardHeights[CentralDogmaPlayer.all[selectedIndex].id] ?? 650)
                        .onPreferenceChange(CentralDogmaPlayerHeights.self) { heights in
                            cardHeights.merge(heights, uniquingKeysWith: { _, new in new })
                        }
                        .accessibilityIdentifier("central-dogma-players-carousel")

                        CentralDogmaCarouselControls(
                            titles: CentralDogmaPlayer.all.map { $0.title },
                            index: selectedIndex,
                            onSelect: { move(to: $0) }
                        )
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 8).padding(.bottom, 28)
                    .frame(width: width).frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .background(CentralDogmaTheme.cream.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .accessibilityIdentifier("central-dogma-players-done")
                }
            }
            .tint(CentralDogmaTheme.ink)
        }
        .onChange(of: selectedIndex) { _, _ in narration.stop() }
        .onDisappear { narration.stop() }
    }

    private func card(_ player: CentralDogmaPlayer, width: CGFloat) -> some View {
        let artWidth = max(1, width - 36)
        let artHeight = min(artWidth * 0.78, 270)
        return VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(CentralDogmaTheme.tint(player.tint).opacity(0.35))
                if let asset = player.asset {
                    Image(asset)
                        .resizable().scaledToFit()
                        .frame(width: max(0, artWidth - 32), height: max(0, artHeight - 32))
                } else {
                    CentralDogmaScene(step: player.scene, progress: 1,
                                      background: .clear, illustrationID: player.id)
                        .frame(width: artWidth, height: artHeight)
                }
            }
            .frame(width: artWidth, height: artHeight)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 9) {
                Text(player.caption)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(CentralDogmaTheme.teal)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(alignment: .top) {
                    Text(player.title)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(CentralDogmaTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 4)
                    NarrationSpeakerButton(cueID: player.narrationID, title: player.title)
                }
            }
            CentralDogmaBullets(items: player.bullets)
        }
        .padding(18).frame(width: width, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .background(CentralDogmaTheme.paper, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(CentralDogmaTheme.tint(player.tint), lineWidth: 1.5))
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: CentralDogmaPlayerHeights.self, value: [player.id: proxy.size.height])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("central-dogma-player-" + player.id)
    }

    private func move(to index: Int) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            selectedIndex = min(max(0, index), CentralDogmaPlayer.all.count - 1)
        }
    }
}

private struct CentralDogmaPlayerHeights: PreferenceKey {
    static var defaultValue: [String: CGFloat] { [:] }
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: max)
    }
}

#Preview("Protein-making crew") { CentralDogmaKeyPlayersView().environmentObject(LessonNarrator.centralDogma()) }
