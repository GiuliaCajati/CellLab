// DNAReplicationKeyPlayersView.swift — swipeable reference cards in the CellLab theme.
import SwiftUI

struct DNAReplicationKeyPlayersView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedID: String?
    @State private var carouselHeight: CGFloat = 650

    init(initialPlayerID: String? = nil) {
        let id = DNAReplicationPlayer.all.first { $0.id == initialPlayerID }?.id
        _selectedID = State(initialValue: id ?? DNAReplicationPlayer.all.first?.id)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let width = min(proxy.size.width, 580)
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

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 14) {
                                ForEach(DNAReplicationPlayer.all) { player in
                                    card(player, width: width - 40).id(player.id)
                                }
                            }
                            .scrollTargetLayout()
                            .padding(.horizontal, 20)
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .scrollPosition(id: $selectedID, anchor: .center)
                        .frame(height: carouselHeight, alignment: .top)
                        .onPreferenceChange(DNAReplicationCardHeights.self) { heights in
                            if let height = heights.values.max(), abs(height - carouselHeight) > 1 {
                                carouselHeight = height
                            }
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
    }

    private func card(_ player: DNAReplicationPlayer, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(player.tint.color.opacity(0.5))
                if let asset = player.asset {
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
            Text(player.title)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(DNAReplicationTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
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
        .accessibilityIdentifier("dna-player-\(player.id)")
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

private struct DNAReplicationCardHeights: PreferenceKey {
    static var defaultValue: [String: CGFloat] { [:] }
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: max)
    }
}

#Preview("DNA copying crew") {
    DNAReplicationKeyPlayersView()
}
