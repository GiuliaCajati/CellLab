//
//  CellCycleKeyPlayersView.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/13/26.
//

// CellCycleKeyPlayersView.swift
// A swipeable, eight-card sheet. No duplicated navigation title over the heading.

import SwiftUI

struct CellCycleKeyPlayersView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedPlayerID: String?
    @State private var carouselHeight: CGFloat = 620

    init(initialPlayerID: String? = nil) {
        let validID = CellCyclePlayer.all.first { $0.id == initialPlayerID }?.id
        _selectedPlayerID = State(initialValue: validID ?? CellCyclePlayer.all.first?.id)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let contentWidth = min(proxy.size.width, 580)
                let cardWidth = contentWidth - 40

                ScrollView {
                    VStack(alignment: .leading, spacing: 21) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meet the key players")
                                .font(.system(.largeTitle, design: .serif, weight: .bold))
                                .foregroundStyle(CellCyclePalette.ink)
                                .accessibilityAddTraits(.isHeader)
                            Text("Swipe to meet the cycle crew.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(CellCyclePalette.muted)
                        }
                        .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 14) {
                                ForEach(CellCyclePlayer.all) { player in
                                    playerCard(player, width: cardWidth)
                                        .id(player.id)
                                }
                            }
                            .scrollTargetLayout()
                            .padding(.horizontal, 20)
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .scrollPosition(id: $selectedPlayerID, anchor: .center)
                        .frame(height: carouselHeight, alignment: .top)
                        .onPreferenceChange(CellCycleCardHeights.self) { heights in
                            // Measure intrinsic text, including large Dynamic Type sizes.
                            // No fixed text height or truncation is imposed on any card.
                            if let height = heights.values.max(), abs(height - carouselHeight) > 1 {
                                carouselHeight = height
                            }
                        }

                        carouselControls
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 26)
                    .frame(width: contentWidth)
                    .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .background(CellCyclePalette.cream.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(CellCyclePalette.ink)
                        .accessibilityIdentifier("cycle-key-players-done")
                }
            }
            .tint(CellCyclePalette.ink)
        }
        .accessibilityIdentifier("cycle-key-players-sheet")
    }

    private func playerCard(_ player: CellCyclePlayer, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            CellCyclePlayerArt(player: player)
                .frame(height: min(width * 0.76, 270))

            Text(player.caption)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(CellCyclePalette.muted)
                .fixedSize(horizontal: false, vertical: true)

            Text(player.title)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(CellCyclePalette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            CellCycleBullets(items: player.bullets)
        }
        .padding(18)
        .frame(width: width, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .background(CellCyclePalette.paper, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(player.tint.color, lineWidth: 1.5))
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: CellCycleCardHeights.self, value: [player.id: proxy.size.height])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("cycle-player-\(player.id)")
    }

    private var selectedIndex: Int {
        CellCyclePlayer.all.firstIndex { $0.id == selectedPlayerID } ?? 0
    }

    private var carouselControls: some View {
        HStack(spacing: 12) {
            Button { move(-1) } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
                    .background(CellCycleTint.sage.color.opacity(0.6), in: Circle())
            }
            .disabled(selectedIndex == 0)
            .opacity(selectedIndex == 0 ? 0.35 : 1)
            .accessibilityLabel("Previous key player")

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                ForEach(Array(CellCyclePlayer.all.enumerated()), id: \.element.id) { index, _ in
                    Capsule()
                        .fill(index == selectedIndex ? CellCyclePalette.teal : CellCyclePalette.edge.opacity(0.2))
                        .frame(width: index == selectedIndex ? 20 : 6, height: 6)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Key player \(selectedIndex + 1) of \(CellCyclePlayer.all.count)")

            Spacer(minLength: 0)

            Button { move(1) } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
                    .background(CellCycleTint.sage.color.opacity(0.6), in: Circle())
            }
            .disabled(selectedIndex == CellCyclePlayer.all.count - 1)
            .opacity(selectedIndex == CellCyclePlayer.all.count - 1 ? 0.35 : 1)
            .accessibilityLabel("Next key player")
        }
        .font(.system(.body, weight: .bold))
        .foregroundStyle(CellCyclePalette.ink)
        .buttonStyle(.plain)
    }

    private func move(_ offset: Int) {
        let index = min(max(selectedIndex + offset, 0), CellCyclePlayer.all.count - 1)
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
            selectedPlayerID = CellCyclePlayer.all[index].id
        }
    }
}

private struct CellCycleCardHeights: PreferenceKey {
    static var defaultValue: [String: CGFloat] { [:] }

    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: max)
    }
}

#Preview("Key players") {
    CellCycleKeyPlayersView()
}
