import SwiftUI

/// Only the artwork moves; text and touch targets keep their positions.
struct HomeArtworkFloat: ViewModifier {
    var distance: CGFloat = 3
    var tilt: Double = 1.2
    var phase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false

    private var moving: Bool { visible && !reduceMotion && scenePhase == .active }

    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1 / 15, paused: !moving)) { timeline in
            let wave = moving ? sin(timeline.date.timeIntervalSinceReferenceDate * 0.9 + phase) : 0
            content.offset(y: wave * distance).rotationEffect(.degrees(wave * tilt))
        }
        .onAppear { visible = true }
        .onDisappear { visible = false }
    }
}

struct HomePressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

/// The existing controller badge is also the shortcut, without a second large CTA.
struct HomeGameBadge: View {
    var body: some View {
        Label("Game", systemImage: "gamecontroller.fill")
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundStyle(Theme.teal)
            .padding(.horizontal, 9).padding(.vertical, 6)
            .background(Theme.background, in: Capsule())
            .overlay(Capsule().stroke(Theme.teal.opacity(0.35), lineWidth: 1))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }
}

/// Owns a lesson's audio when a game is opened directly from the home card.
struct HomeGameDestination: View {
    let module: CellLabHomeModule
    @StateObject private var narrator: LessonNarrator

    init(module: CellLabHomeModule) {
        self.module = module
        _narrator = StateObject(wrappedValue: Self.narrator(for: module))
    }

    private static func narrator(for module: CellLabHomeModule) -> LessonNarrator {
        switch module {
        case .mitosis: .mitosis()
        case .meiosis: .meiosis()
        case .sphase: .sphase()
        case .dogma: .centralDogma()
        default: preconditionFailure("This lesson has no game")
        }
    }

    var body: some View {
        game.environmentObject(narrator)
            .onDisappear { narrator.stop() }
    }

    @ViewBuilder private var game: some View {
        switch module {
        case .mitosis: MitosisGameView()
        case .meiosis: MeiosisGameView()
        case .sphase: DNAReplicationGameView(backLabel: "Back to CellLab")
        case .dogma: CentralDogmaGameView()
        default: EmptyView()
        }
    }
}
