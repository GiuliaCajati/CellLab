// CentralDogmaKeyPlayersView.swift — full artwork, natural card heights.
import SwiftUI

@MainActor struct CentralDogmaKeyPlayersView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedIndex: Int

    init(initialPlayerID: String? = nil) {
        _selectedIndex = State(initialValue: CentralDogmaPlayer.all.firstIndex { $0.id == initialPlayerID } ?? 0)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let width = min(proxy.size.width, 580)
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

                        card(CentralDogmaPlayer.all[selectedIndex], width: width - 40)
                            .id(selectedIndex)
                            .transition(.opacity)
                            .simultaneousGesture(DragGesture(minimumDistance: 24).onEnded { value in
                                let x = value.translation.width
                                guard abs(x) > 50, abs(x) > abs(value.translation.height) * 1.5 else { return }
                                move(to: selectedIndex + (x < 0 ? 1 : -1))
                            })
                            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: selectedIndex)

                        CentralDogmaCarouselControls(
                            titles: CentralDogmaPlayer.all.map { $0.title },
                            index: selectedIndex,
                            onSelect: { move(to: $0) }
                        )
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 28)
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
    }

    private func card(_ player: CentralDogmaPlayer, width: CGFloat) -> some View {
        let artWidth = width - 36
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
                Text(player.title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(CentralDogmaTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            CentralDogmaBullets(items: player.bullets)
        }
        .padding(18).frame(width: width, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .background(CentralDogmaTheme.paper, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(CentralDogmaTheme.edge.opacity(0.2), lineWidth: 1))
        .shadow(color: CentralDogmaTheme.ink.opacity(0.035), radius: 12, x: 0, y: 5)
        .accessibilityIdentifier("central-dogma-player-" + player.id)
    }

    private func move(to index: Int) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            selectedIndex = min(max(0, index), CentralDogmaPlayer.all.count - 1)
        }
    }
}

#Preview("Protein-making crew") { CentralDogmaKeyPlayersView() }
