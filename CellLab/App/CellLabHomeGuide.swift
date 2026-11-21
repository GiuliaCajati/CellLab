import SwiftUI

private struct HomeGuideBubble: View {
    let speaking: Bool
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Image(systemName: speaking ? "stop.fill" : "play.fill")
                    .font(.system(size: 11, weight: .black))
                    .offset(x: speaking ? 0 : 1)
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Theme.teal, in: Circle())
                Text(speaking ? "Stop" : "Hear overview")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
            }
            if speaking {
                Text(detail)
                    .font(.system(.caption, design: .rounded))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [Color(hex: 0xFFE9B2), Theme.mitosis], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: Theme.gold.opacity(0.22), radius: 0, y: 3)
        }
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.gold.opacity(0.7), lineWidth: 1))
        .overlay(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 2).fill(Theme.mitosis)
                .frame(width: 12, height: 12).rotationEffect(.degrees(45)).offset(x: 5)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

/// A compact floating guide. The page leaves clearance only after its final card.
struct HomeAxolotlTab: View {
    @ObservedObject var narrator: LessonNarrator
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var recordingTitle: String {
        narrator.library[narrator.currentCueID ?? ""]?.title ?? "CellLab"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                HomeGuideBubble(speaking: narrator.isPlaying,
                                detail: narrator.isPlaying ? recordingTitle : "Lessons + games")
                TimelineView(.animation(minimumInterval: 0.24, paused: !narrator.isPlaying || reduceMotion)) { time in
                    MitosisAxolotl(isSpeaking: narrator.isPlaying && !reduceMotion
                                  && sin(time.date.timeIntervalSince1970 * .pi * 3) > 0.25,
                                  fittedToArtwork: true)
                }
                .frame(width: 70, height: 60)
                .rotationEffect(.degrees(-12))
                .modifier(HomeArtworkFloat(distance: 2, tilt: 1.5, phase: 0.7))
                .offset(x: appeared ? 8 : 60, y: 4)
                .accessibilityHidden(true)
            }
            .foregroundStyle(Theme.ink)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
            .clipped()
        }
        .buttonStyle(HomePressStyle())
        .accessibilityLabel(narrator.isPlaying ? "Stop narration" : "Hear CellLab overview")
        .accessibilityValue(narrator.isPlaying ? "Speaking \(recordingTitle)" : "Quiet")
        .accessibilityHint("Hear a tour of the lessons and their games")
        .accessibilityIdentifier("home-guide-listen")
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.45)) { appeared = true }
        }
    }
}

/// The selected card's description expands directly beneath its row on the home page.
struct HomeLessonPreview: View {
    let module: CellLabHomeModule
    let hide: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(module.title)
                    .font(.system(.headline, design: .rounded))
                Spacer(minLength: 8)
                Button(action: hide) {
                    Image(systemName: "xmark").font(.system(size: 14, weight: .bold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hide \(module.title) details")
                .accessibilityIdentifier("home-hide-\(module.id)")
            }
            Text(module.overview)
                .font(.system(.subheadline, design: .rounded))
            if let game = module.gameSummary {
                Label("Try the game", systemImage: "gamecontroller.fill")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                Text(game).font(.system(.subheadline, design: .rounded))
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(16)
        .foregroundStyle(Theme.ink)
        .background(module.fill.opacity(0.6), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.teal, lineWidth: 1.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-details-\(module.id)")
    }
}
