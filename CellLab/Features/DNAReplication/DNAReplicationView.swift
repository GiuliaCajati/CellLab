// DNAReplicationView.swift — CellLab's primer-first, swipeable lesson.
import SwiftUI
import UIKit

@MainActor struct DNAReplicationView: View {
    @State private var session = DNAReplicationSession()
    @State private var sheet: DNAReplicationSheet?
    @State private var measuredCardHeight: CGFloat = 0
    @State private var expandedStep: DNAReplicationStep? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = min(proxy.size.width, 580)
            let cardWidth = contentWidth - 40
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center, spacing: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DNA Replication")
                                .font(.system(.largeTitle, design: .serif, weight: .bold))
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.isHeader)
                            Text("One DNA molecule → two copies")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(DNAReplicationTheme.muted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        NavigationLink {
                            DNAReplicationGameView()
                        } label: {
                            Label("Play", systemImage: "play.fill")
                                .font(.system(.headline, design: .rounded))
                                .padding(.horizontal, 17)
                                .frame(minHeight: 50)
                                .background(DNAReplicationTheme.teal, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Play the DNA replication game")
                    }

                    TabView(selection: Binding(
                        get: { session.step },
                        set: { step in
                            guard step != session.step else { return }
                            selectCard(step)
                        }
                    )) {
                        ForEach(DNAReplicationStep.carouselCases) { step in
                            phaseCard(step, width: cardWidth)
                                .tag(step)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: measuredCardHeight > 0 ? measuredCardHeight : min(cardWidth * 1.07, 410) + 145)
                    .onPreferenceChange(DNAReplicationLessonHeights.self) { heights in
                        if let height = heights.values.max(), abs(height - measuredCardHeight) > 1 {
                            measuredCardHeight = height
                        }
                    }
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: session.step)
                    .accessibilityIdentifier("dna-carousel")

                    HStack(spacing: 4) {
                        ForEach(DNAReplicationStep.carouselCases) { step in
                            Button { selectCard(step) } label: {
                                Capsule()
                                    .fill(session.step == step ? DNAReplicationTheme.teal : DNAReplicationTheme.edge.opacity(0.2))
                                    .frame(width: session.step == step ? 22 : 6, height: 6)
                                    .frame(width: 34, height: 36)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(step.content.title)
                            .accessibilityValue(session.step == step ? "Selected" : "")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    Button(action: toggleLesson) {
                        Label(session.isPlaying ? "Pause" : "Play", systemImage: session.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(.headline, design: .rounded))
                            .padding(.horizontal, 17).frame(minHeight: 50)
                            .background(DNAReplicationTheme.teal, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(reduceMotion)
                    .accessibilityIdentifier("dna-play-pause")
                    .frame(maxWidth: .infinity, alignment: .center)


                    DNAReplicationLegend().frame(maxWidth: .infinity)


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
                        .background(DNAReplicationTint.sage.color, in: RoundedRectangle(cornerRadius: 23))
                        .overlay(RoundedRectangle(cornerRadius: 23).strokeBorder(DNAReplicationTheme.edge, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("dna-key-players")

                    Text("Simplified, not to scale. Enzyme actions overlap in cells.")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(DNAReplicationTheme.muted)
                        .frame(maxWidth: .infinity)
                }
                .foregroundStyle(DNAReplicationTheme.ink)
                .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 28)
                .frame(width: contentWidth).frame(maxWidth: .infinity)
            }
        }
        .background(DNAReplicationTheme.cream.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .tint(DNAReplicationTheme.ink)
        .sheet(item: $sheet) { route in
            Group {
                switch route {
                case .diagram: DNAReplicationExpandedView(session: session)
                case .players: DNAReplicationKeyPlayersView(initialPlayerID: "primase")
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(30)
        }
        .task(id: DNAReplicationClockKey(playing: session.isPlaying, reduced: reduceMotion, active: scenePhase == .active)) {
            guard session.isPlaying, !reduceMotion, scenePhase == .active else { return }
            await session.run()
        }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced { session.isPlaying = false; session.progress = 1 }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { session.isPlaying = false }
        }
        .sensoryFeedback(.selection, trigger: session.step)
    }

    private func phaseCard(_ step: DNAReplicationStep, width: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                Text(step.content.title)
                    .font(.system(.title, design: .serif, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                Button { sheet = .diagram } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(.body, weight: .semibold))
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Enlarge diagram")
            }
            .padding(.horizontal, 18).padding(.top, 18)

            DNAReplicationScene(step: step, progress: step == session.step && !reduceMotion ? session.progress : 1,
                                background: DNAReplicationTint.butter.color)
                .frame(height: min(width * 1.07, 410))
                .frame(maxWidth: .infinity)

            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                    expandedStep = expandedStep == step ? nil : step
                }
            } label: {
                HStack {
                    Text(step.content.mnemonic)
                        .font(.system(.headline, design: .rounded))

                    Spacer(minLength: 0)

                    Image(systemName: expandedStep == step ? "chevron.down" : "chevron.right")
                        .font(.system(.body, weight: .bold))
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(expandedStep == step ? "Expanded" : "Collapsed")

            if expandedStep == step && session.step == step {
                DNAReplicationBullets(items: step.content.bullets)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(DNAReplicationTheme.ink)
        .frame(width: width)
        .fixedSize(horizontal: false, vertical: true)
        .background(DNAReplicationTint.butter.color, in: RoundedRectangle(cornerRadius: 27))
        .overlay(RoundedRectangle(cornerRadius: 27).strokeBorder(DNAReplicationTheme.edge, lineWidth: 1.5))
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: DNAReplicationLessonHeights.self, value: [step.id: proxy.size.height])
            }
        }
        .accessibilityIdentifier("dna-card-\(step.content.slug)")
    }

    private func selectCard(_ step: DNAReplicationStep) {
        session.autoAdvance = false
        session.select(step, play: !reduceMotion)
    }

    private func toggleLesson() {
        if session.isPlaying { session.isPlaying = false; return }
        session.autoAdvance = true
        if session.step == .result && session.progress >= 1 { session.select(.prime, play: true) }
        else if session.progress >= 1 { session.replay(play: true) }
        else { session.isPlaying = true }
    }
}

@MainActor struct DNAReplicationPlaybackControls: View {
    @Bindable var session: DNAReplicationSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        HStack(spacing: 12) {
            Button {
                if let previous = session.step.previous { session.autoAdvance = false; session.select(previous, play: !reduceMotion) }
            } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
            .disabled(session.step.previous == nil).accessibilityLabel("Previous card")
            Button { session.togglePlayback() } label: {
                Label(session.isPlaying ? "Pause" : "Play", systemImage: session.isPlaying ? "pause.fill" : "play.fill")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .disabled(reduceMotion)
            Button { session.replay(play: !reduceMotion) } label: {
                Image(systemName: "arrow.counterclockwise").frame(width: 44, height: 44)
            }
            .disabled(reduceMotion).accessibilityLabel("Replay this card")
            Button {
                if let next = session.step.next { session.autoAdvance = false; session.select(next, play: !reduceMotion) }
            } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
            .disabled(session.step.next == nil).accessibilityLabel("Next card")
        }
        .font(.system(.body, design: .rounded, weight: .semibold))
        .foregroundStyle(DNAReplicationTheme.ink).buttonStyle(.plain)
    }
}

@MainActor private struct DNAReplicationExpandedView: View {
    @Bindable var session: DNAReplicationSession
    @State private var zoom: Double = 1.25
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                VStack(spacing: 12) {
                    Picker("Replication card", selection: Binding(get: { session.step }, set: { session.autoAdvance = false; session.select($0, play: !reduceMotion) })) {
                        ForEach(DNAReplicationStep.carouselCases) { step in Text(step.content.title).tag(step) }
                    }
                    .pickerStyle(.menu).padding(.top, 8)
                    ScrollView([.horizontal, .vertical]) {
                        DNAReplicationScene(step: session.step, progress: reduceMotion ? 1 : session.progress)
                            .frame(width: max(320, proxy.size.width - 24) * CGFloat(zoom),
                                   height: max(320, proxy.size.width - 24) * CGFloat(zoom) * 420 / 360)
                            .padding(12)
                    }
                    .background(DNAReplicationTheme.paper)
                    VStack(spacing: 10) {
                        DNAReplicationLegend()
                        HStack {
                            Image(systemName: "minus.magnifyingglass")
                            Slider(value: $zoom, in: 1...2.6).accessibilityLabel("Diagram zoom")
                            Image(systemName: "plus.magnifyingglass")
                        }
                        DNAReplicationPlaybackControls(session: session)
                    }
                    .padding(.horizontal, 20).padding(.bottom, 12)
                }
            }
            .background(DNAReplicationTheme.cream.ignoresSafeArea())
            .navigationTitle("Replication close-up").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .tint(DNAReplicationTheme.ink)
        }
    }
}

private struct DNAReplicationLessonHeights: PreferenceKey {
    static var defaultValue: [Int: CGFloat] { [:] }
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: max)
    }
}
private struct DNAReplicationClockKey: Hashable {
    let playing: Bool
    let reduced: Bool
    let active: Bool
}
private enum DNAReplicationSheet: String, Identifiable {
    case diagram, players
    var id: String { rawValue }
}

#Preview("DNA replication") { NavigationStack { DNAReplicationView() } }
