// DNAReplicationKeyPlayersView.swift — swipeable reference cards in the CellLab theme.
import SwiftUI

struct DNAReplicationKeyPlayersView: View {
    @EnvironmentObject private var narration: LessonNarrator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedID: String?
    @State private var cardHeights: [String: CGFloat] = [:]

    init(initialPlayerID: String? = nil) {
        let id = DNAReplicationPlayer.all.first { $0.id == initialPlayerID }?.id
        _selectedID = State(initialValue: id ?? DNAReplicationPlayer.all.first?.id)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let width = max(1, min(proxy.size.width, 680))
                ScrollView {
                    VStack(alignment: .leading, spacing: 21) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meet the key players")
                                .font(.system(.largeTitle, design: .serif, weight: .bold))
                                .foregroundStyle(DNAReplicationTheme.ink)
                                .accessibilityAddTraits(.isHeader)
                            Text("Swipe to meet the copying crew.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(DNAReplicationTheme.muted)
                        }
                        .padding(.horizontal, 20)

                        LessonGuide(narrator: narration,
                                    title: narration.isPlaying ? "Stop" : "Hear introduction",
                                    cueID: "reference.players",
                                    action: { narration.toggleStandalone("reference.players") },
                                    controlID: "sphaseVocabularyListenButton")
                            .padding(.horizontal, 20)

                        TabView(selection: Binding(
                            get: { selectedID ?? DNAReplicationPlayer.all[0].id },
                            set: { selectedID = $0 }
                        )) {
                            ForEach(DNAReplicationPlayer.all) { player in
                                card(player, width: max(1, width - 40)).tag(player.id)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: cardHeights[selectedID ?? ""] ?? 650, alignment: .top)
                        .onPreferenceChange(DNAReplicationCardHeights.self) { heights in
                            cardHeights.merge(heights, uniquingKeysWith: { _, new in new })
                        }

                        controls.padding(.horizontal, 20)

                        Link(destination: URL(string: "https://www.youtube.com/watch?v=Qqe4thU-os8")!) {
                            Label("Reference video · Amoeba Sisters", systemImage: "play.rectangle")
                                .font(.system(.caption, design: .rounded))
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 8).padding(.bottom, 28)
                    .frame(width: width).frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .background(DNAReplicationTheme.cream.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .accessibilityIdentifier("dna-players-done")
                }
            }
            .tint(DNAReplicationTheme.ink)
        }
        .onChange(of: selectedID) { _, _ in narration.stop() }
        .onDisappear { narration.stop() }
    }

    private func card(_ player: DNAReplicationPlayer, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(player.tint.color.opacity(0.5))
                if player.scene == .unzip {
                    DNAReplicationPlayerAnimation(step: .unzip, selected: selectedID == player.id)
                        .padding(8)
                } else if let asset = player.asset {
                    Image(asset).resizable().scaledToFit().padding(16)
                } else {
                    DNAReplicationScene(step: player.scene, progress: 1, showsLabels: false)
                        .padding(8)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
            }
            .frame(height: min(width * 0.72, 260))
            .accessibilityHidden(true)

            Text(player.caption)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(DNAReplicationTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top) {
                Text(player.title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(DNAReplicationTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 4)
                NarrationSpeakerButton(cueID: player.narrationID, title: player.narrationTitle)
            }
            DNAReplicationBullets(items: player.bullets)
        }
        .padding(18).frame(width: width, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .background(DNAReplicationTheme.paper, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(player.tint.color, lineWidth: 1.5))
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: DNAReplicationCardHeights.self, value: [player.id: proxy.size.height])
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var index: Int { DNAReplicationPlayer.all.firstIndex { $0.id == selectedID } ?? 0 }

    private var controls: some View {
        HStack(spacing: 12) {
            Button { move(-1) } label: {
                Image(systemName: "chevron.left").frame(width: 44, height: 44)
                    .background(DNAReplicationTint.sage.color.opacity(0.6), in: Circle())
            }
            .disabled(index == 0).opacity(index == 0 ? 0.35 : 1)
            .accessibilityLabel("Previous key player")
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                ForEach(Array(DNAReplicationPlayer.all.enumerated()), id: \.element.id) { item, _ in
                    Capsule()
                        .fill(item == index ? DNAReplicationTheme.teal : DNAReplicationTheme.edge.opacity(0.2))
                        .frame(width: item == index ? 20 : 5, height: 5)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Key player \(index + 1) of \(DNAReplicationPlayer.all.count)")
            Spacer(minLength: 0)
            Button { move(1) } label: {
                Image(systemName: "chevron.right").frame(width: 44, height: 44)
                    .background(DNAReplicationTint.sage.color.opacity(0.6), in: Circle())
            }
            .disabled(index == DNAReplicationPlayer.all.count - 1)
            .opacity(index == DNAReplicationPlayer.all.count - 1 ? 0.35 : 1)
            .accessibilityLabel("Next key player")
        }
        .font(.system(.body, weight: .bold))
        .foregroundStyle(DNAReplicationTheme.ink)
        .buttonStyle(.plain)
    }

    private func move(_ offset: Int) {
        let next = min(max(index + offset, 0), DNAReplicationPlayer.all.count - 1)
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
            selectedID = DNAReplicationPlayer.all[next].id
        }
    }
}

private struct DNAReplicationPlayerAnimation: View {
    let step: DNAReplicationStep
    let selected: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var appeared = false
    @State private var started = Date()
    private var animated: Bool { appeared && selected && !reduceMotion && scenePhase == .active }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animated)) { timeline in
            let elapsed = max(0, timeline.date.timeIntervalSince(started))
            let progress = animated ? min(1, elapsed.truncatingRemainder(dividingBy: step.content.duration + 1.3) / step.content.duration) : 1
            DNAReplicationScene(step: step, progress: progress, showsLabels: false,
                                background: .clear)
        }
        .onAppear { started = Date(); appeared = true }
        .onDisappear { appeared = false }
        .onChange(of: selected) { _, selected in if selected { started = Date() } }
        .onChange(of: reduceMotion) { _, reduced in if !reduced { started = Date() } }
    }
}

private struct DNAReplicationCardHeights: PreferenceKey {
    static var defaultValue: [String: CGFloat] { [:] }
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: max)
    }
}

#Preview("DNA copying crew") {
    DNAReplicationKeyPlayersView().environmentObject(LessonNarrator.sphase())
}
