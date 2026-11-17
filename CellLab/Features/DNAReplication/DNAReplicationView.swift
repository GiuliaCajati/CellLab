// DNAReplicationView.swift — S phase in the shared CellLab lesson style.
import SwiftUI
import UIKit

@MainActor struct DNAReplicationView: View {
    @State private var session = DNAReplicationSession()
    @State private var sheet: DNAReplicationSheet?
    @State private var cardHeights: [Int: CGFloat] = [:]
    @State private var expandedStep: DNAReplicationStep?
    @State private var showingGame = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var clockActive: Bool { scenePhase == .active && sheet != .diagram && !showingGame }
    private var animationTitle: String {
        if reduceMotion { return "Still illustrations" }
        if session.isPlaying { return "Pause animation" }
        if session.progress >= 1 { return "Replay animation" }
        return session.progress > 0 ? "Resume animation" : "Watch animation"
    }

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = min(proxy.size.width, 680)
            let cardWidth = max(1, contentWidth - 36)
            ScrollView {
                VStack(spacing: 14) {
                    VStack(spacing: 0) {
                        header
                        animationControl
                            .padding(.top, 8).padding(.bottom, 10)
                        TabView(selection: Binding(get: { session.step }, set: selectCard)) {
                            ForEach(DNAReplicationStep.carouselCases) { step in
                                phaseCard(step, width: cardWidth).tag(step)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: cardHeights[session.step.id] ?? min(cardWidth, 360) + 155)
                        .onPreferenceChange(DNAReplicationLessonHeights.self) { heights in
                            cardHeights.merge(heights, uniquingKeysWith: { _, new in new })
                        }
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: session.step)
                        .accessibilityIdentifier("dna-carousel")
                        phaseDots.padding(.top, 8)
                    }
                    DNAReplicationLegend()
                        .padding(12).frame(maxWidth: .infinity)
                        .background(DNAReplicationTheme.paper, in: RoundedRectangle(cornerRadius: 18))
                    Button {
                        session.isPlaying = false
                        session.autoAdvance = false
                        sheet = .players
                    } label: {
                        HStack {
                            Label("Meet the key players", systemImage: "text.book.closed.fill")
                            Spacer(minLength: 4)
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(.headline, design: .rounded))
                        .padding(18).frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(MeiPalette.ink)
                        .background(MeiPalette.mint, in: RoundedRectangle(cornerRadius: 22))
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(MeiPalette.ink.opacity(0.7), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("dna-key-players")
                    Text("Simplified, not to scale. Enzyme actions overlap in cells.")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(MeiPalette.text)
                .padding(.horizontal, 18).padding(.top, 6).padding(.bottom, 18)
                .frame(width: contentWidth).frame(maxWidth: .infinity)
            }
        }
        .background(MeiPalette.paper.ignoresSafeArea())
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .tint(MeiPalette.teal)
        .navigationDestination(isPresented: $showingGame) { DNAReplicationGameView() }
        .sheet(item: $sheet) { route in
            Group {
                switch route {
                case .diagram: DNAReplicationExpandedView(session: session)
                case .players: DNAReplicationKeyPlayersView(initialPlayerID: session.step.content.playerID)
                }
            }
            .presentationDetents([.large]).presentationDragIndicator(.visible).presentationCornerRadius(30)
        }
        .task(id: DNAReplicationClockKey(playing: session.isPlaying, reduced: reduceMotion, active: clockActive)) {
            guard session.isPlaying, !reduceMotion, clockActive else { return }
            await session.run()
        }
        .onAppear {
            if reduceMotion { session.isPlaying = false; session.progress = 1 }
        }
        .onDisappear {
            if sheet == nil { session.isPlaying = false; session.autoAdvance = false }
        }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced { session.isPlaying = false; session.progress = 1 }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { session.isPlaying = false }
        }
        .sensoryFeedback(.selection, trigger: session.step)
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("S phase")
                .font(.system(.largeTitle, design: .serif, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Text("One DNA molecule → two copies")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top) {
                headerTitle.fixedSize(horizontal: true, vertical: true)
                Spacer(minLength: 12)
                gameButton
            }
            VStack(alignment: .leading, spacing: 8) {
                headerTitle
                HStack { Spacer(); gameButton }
            }
        }
    }

    private var gameButton: some View {
        Button {
            session.isPlaying = false
            session.autoAdvance = false
            showingGame = true
        } label: {
            Label("Play game", systemImage: "play.fill")
                .font(.system(.headline, design: .rounded)).frame(minHeight: 36)
                .foregroundStyle(.white)
        }
        .buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel("Play the DNA replication game")
        .accessibilityIdentifier("dna-play-game")
    }

    private var animationControl: some View {
        HStack(spacing: 4) {
            Button {
                session.autoAdvance = false
                session.togglePlayback()
            } label: {
                HStack(spacing: 8) {
                    MitosisAxolotl(isSpeaking: false, fittedToArtwork: true)
                        .frame(width: 48 * 160 / 136, height: 48)
                    Image(systemName: session.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .semibold)).frame(width: 18)
                    Text(animationTitle)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain).disabled(reduceMotion)
            .accessibilityLabel(animationTitle)
            .accessibilityValue("\(Int(session.progress * 100)) percent")
            .accessibilityIdentifier("dna-play-pause")
            Menu {
                Button("Replay this step", systemImage: "arrow.counterclockwise") {
                    session.autoAdvance = false
                    session.replay(play: true)
                }
                .disabled(reduceMotion)
                Button("Play all steps", systemImage: "play.rectangle.on.rectangle") {
                    session.autoAdvance = true
                    if session.step == .result && session.progress >= 1 { session.select(.origins, play: true) }
                    else if session.progress >= 1 { session.replay(play: true) }
                    else { session.isPlaying = true }
                }
                .disabled(reduceMotion)
            } label: {
                Image(systemName: "ellipsis.circle").frame(width: 44, height: 44)
            }
            .accessibilityLabel("Animation options")
            .accessibilityIdentifier("dna-animation-options")
        }
    }

    private var phaseDots: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) { dots(DNAReplicationStep.carouselCases) }.fixedSize()
            VStack(spacing: 0) {
                HStack(spacing: 0) { dots(Array(DNAReplicationStep.carouselCases.prefix(5))) }
                HStack(spacing: 0) { dots(Array(DNAReplicationStep.carouselCases.suffix(4))) }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func dots(_ steps: [DNAReplicationStep]) -> some View {
        ForEach(steps) { step in
            Button { selectCard(step) } label: {
                Capsule()
                    .fill(session.step == step ? MeiPalette.teal : MeiPalette.text.opacity(0.18))
                    .frame(width: session.step == step ? 22 : 7, height: 7)
                    .frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(step.content.title)
            .accessibilityValue(session.step == step ? "Selected" : "")
            .accessibilityIdentifier("dna-step-\(step.content.slug)")
        }
    }

    private func cardColor(_ step: DNAReplicationStep) -> Color {
        switch step {
        case .origins, .build, .result: MeiPalette.mint
        case .unzip, .prime: MeiPalette.butter
        case .stabilize, .replace: MeiPalette.lilac
        case .proofread: MeiPalette.blush
        case .seal: DNAReplicationTint.blue.color
        }
    }

    private func phaseCard(_ step: DNAReplicationStep, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DNA REPLICATION")
                Spacer(minLength: 4)
                Text("\(step.rawValue + 1) / \(DNAReplicationStep.carouselCases.count)")
            }
            .font(.system(.caption, design: .rounded, weight: .bold))
            .foregroundStyle(MeiPalette.ink.opacity(0.72))
            HStack(alignment: .top, spacing: 8) {
                Text(step.content.title)
                    .font(.system(.title, design: .serif, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                Button {
                    session.autoAdvance = false
                    sheet = .diagram
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right").frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Enlarge diagram")
                .accessibilityIdentifier("dna-enlarge-\(step.content.slug)")
            }
            DNAReplicationScene(step: step, progress: step == session.step && !reduceMotion ? session.progress : 1,
                                background: cardColor(step))
                .frame(height: step == .origins ? width * 220 / 360 : min(width, 360))
                .frame(maxWidth: .infinity)
            DisclosureGroup(isExpanded: Binding(
                get: { expandedStep == step },
                set: { expandedStep = $0 ? step : nil }
            )) {
                DNAReplicationBullets(items: step.content.bullets)
                    .padding(12)
                    .background(.white.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 4)
            } label: {
                Text(step.content.mnemonic)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .tint(MeiPalette.ink)
        }
        .padding(16).foregroundStyle(MeiPalette.ink)
        .frame(width: width).fixedSize(horizontal: false, vertical: true)
        .background(cardColor(step), in: RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(MeiPalette.ink.opacity(0.75), lineWidth: 1.5))
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: DNAReplicationLessonHeights.self, value: [step.id: proxy.size.height])
            }
        }
    }

    private func selectCard(_ step: DNAReplicationStep) {
        guard step != session.step else { return }
        expandedStep = nil
        session.autoAdvance = false
        session.select(step, play: !reduceMotion)
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
            Button { session.autoAdvance = false; session.togglePlayback() } label: {
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
    @Environment(\.scenePhase) private var scenePhase
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
                                   height: max(320, proxy.size.width - 24) * CGFloat(zoom) * (session.step == .origins ? 220 : 420) / 360)
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
        // The page yields its clock while this sheet owns the same session.
        .task(id: DNAReplicationClockKey(playing: session.isPlaying, reduced: reduceMotion,
                                        active: scenePhase == .active)) {
            guard session.isPlaying, !reduceMotion, scenePhase == .active else { return }
            await session.run()
        }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced { session.isPlaying = false; session.progress = 1 }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { session.isPlaying = false }
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
