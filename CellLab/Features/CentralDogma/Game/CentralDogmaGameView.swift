import SwiftUI

@MainActor struct CentralDogmaGameView: View {
    @EnvironmentObject private var narration: LessonNarrator
    @State private var session = CentralDogmaGameSession()
    @State private var started = false
    @State private var guide = false
    @State private var restart = false
    @AppStorage("CellLab.RNARelay.bestScore.v1") private var bestScore = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var activeNarrationEvent: String? {
        guard !guide else { return nil }
        if !started { return "game.introduction" }
        if let checkpoint = session.pending { return checkpoint.narrationID }
        return session.isComplete ? "game.complete" : session.step?.narrationID
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if !started { header; introduction }
                    else if session.isComplete && session.pending == nil { header; victory }
                    else if let step = session.step {
                        hud
                        VStack(alignment: .leading, spacing: 4) {
                            gameGuide(cueID: step.narrationID, instruction: Text(step.instruction)
                                .font(.system(.body, design: .rounded)), controlID: "central-dogma-game-listen")
                        }
                        feedback
                        CentralDogmaGameBoard(session: session, step: step)
                    }
                    if !started || session.isComplete { Text("Eukaryotic cell · shortened sequences · not to scale")
                        .font(.system(.caption2, design: .rounded)).foregroundStyle(CentralDogmaGameTheme.muted)
                        .multilineTextAlignment(.center).frame(maxWidth: .infinity) }
                }
                .padding(.horizontal, 16).padding(.vertical, 8).frame(width: min(geometry.size.width, 620)).frame(maxWidth: .infinity)
                .foregroundStyle(CentralDogmaGameTheme.ink)
                .allowsHitTesting(session.pending == nil)
                .accessibilityHidden(session.pending != nil)
            }
        }
        .background(CentralDogmaGameTheme.cream.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if started, !session.isComplete, session.pending == nil, let step = session.step, !step.options.isEmpty {
                VStack(spacing: 0) {
                    CentralDogmaGameToolbox(session: session, step: step)
                }
                .foregroundStyle(CentralDogmaGameTheme.ink)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
                .background(CentralDogmaGameTheme.cream.shadow(color: .black.opacity(0.07), radius: 8, y: -3))
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("rna-relay-tool-dock")
            }
        }
        .navigationTitle(started ? "RNA Relay" : "").navigationBarTitleDisplayMode(.inline)
        .tint(CentralDogmaGameTheme.ink)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if started {
                    Button { session.showHint() } label: { Image(systemName: "lightbulb") }.accessibilityLabel("Hint")
                    Button { guide = true } label: { Image(systemName: "info.circle") }.accessibilityLabel("Details")
                    Button { restart = true } label: { Image(systemName: "arrow.counterclockwise") }.accessibilityLabel("Start a new round")
                }
            }
        }
        .confirmationDialog("Start a new round?", isPresented: $restart, titleVisibility: .visible) {
            Button("New round") { restartRound() }
            Button("Keep playing", role: .cancel) {}
        } message: { Text("This round’s progress will reset. Your best completed score is kept.") }
        .sheet(isPresented: $guide, onDismiss: narration.stop) { fieldGuide }
        .overlay {
            if let checkpoint = session.pending { checkpointView(checkpoint) }
        }
        .sensoryFeedback(.success, trigger: session.successSerial)
        .sensoryFeedback(.warning, trigger: session.mistakeSerial)
        .onChange(of: session.isComplete) { _, completed in
            if completed { bestScore = max(bestScore, session.score) }
        }
        .onChange(of: activeNarrationEvent) { _, event in narration.gameEventChanged(event) }
        .onChange(of: guide) { _, _ in narration.stop() }
        .onChange(of: restart) { _, showing in if showing { narration.stop() } }
        .onChange(of: scenePhase) { _, phase in if phase != .active { narration.stop() } }
        .onAppear { narration.stop(); narration.resetGameGuidance() }
        .onDisappear { narration.stop() }
        .alert("Audio unavailable", isPresented: Binding(
            get: { narration.errorMessage != nil }, set: { if !$0 { narration.errorMessage = nil } }
        )) { Button("OK", role: .cancel) { narration.errorMessage = nil } }
        message: { Text(narration.errorMessage ?? "Please try again.") }
    }

    private func gameGuide(cueID: String, instruction: Text? = nil,
                           controlID: String = "central-dogma-game-introduction-listen") -> some View {
        LessonGuide(narrator: narration, title: narration.isPlaying ? "Stop" : "Hear instruction",
                    cueID: cueID, action: {
                        if narration.isPlaying { narration.stop() }
                        else { narration.startGameGuidance(cueID) }
                    }, showsStopBetweenClips: narration.mode == .game,
                    controlID: controlID, instruction: instruction,
                    instructionID: "central-dogma-game-instruction", compactInstruction: instruction != nil)
    }

    private func restartRound() {
        let guided = narration.mode == .game
        narration.stop()
        narration.resetGameGuidance()
        session.restart()
        if guided, let event = activeNarrationEvent { narration.startGameGuidance(event) }
    }
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RNA Relay").font(.system(.largeTitle, design: .serif, weight: .bold)).accessibilityAddTraits(.isHeader)
            Text("DNA → RNA → Protein").font(.system(.subheadline, design: .rounded)).foregroundStyle(CentralDogmaGameTheme.muted)
        }
    }
    private var introduction: some View {
        VStack(spacing: 17) {
            CentralDogmaGameJourney(preview: true)
            gameGuide(cueID: "game.introduction")
            Text("One gene. A new protein.").font(.system(.title2, design: .serif, weight: .bold))
            Text("Copy DNA. Send mRNA. Build a chain.")
                .font(.system(.body, design: .rounded)).multilineTextAlignment(.center)
            Button("Let’s make a message") { started = true }.buttonStyle(CentralDogmaGamePrimaryStyle())
        }.centralDogmaGamePanel(CentralDogmaGameTheme.butter)
    }
    private var hud: some View {
        VStack(spacing: 6) {
            HStack {
                Text(session.step?.title ?? "RNA Relay").font(.system(.title3, design: .serif, weight: .bold)).accessibilityAddTraits(.isHeader)
                Spacer()
                Label("\(session.score)", systemImage: "star.fill").font(.system(.subheadline, design: .rounded, weight: .bold))
            }
        }
    }
    private var feedback: some View {
        Group { if session.feedback.correct != nil || session.hints > 0 {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: session.feedback.correct == true ? "checkmark.circle.fill" : (session.feedback.correct == false ? "arrow.clockwise" : "sparkles"))
            Text(session.feedback.text).font(.system(.caption, design: .rounded)).fixedSize(horizontal: false, vertical: true)
            if session.feedback.points > 0 { Spacer(minLength: 2); Text("+\(session.feedback.points)").font(.system(.headline, design: .rounded)) }
        }
        .foregroundStyle(CentralDogmaGameTheme.ink)
        .padding(.horizontal, 8).padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(session.feedback.correct == false ? CentralDogmaGameTheme.peach.opacity(0.6) : CentralDogmaGameTheme.sage.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        } }
    }
    private func checkpointView(_ checkpoint: CentralDogmaGameMilestone) -> some View {
        ZStack {
            CentralDogmaGameTheme.ink.opacity(0.28).ignoresSafeArea()
            ScrollView {
            VStack(spacing: 15) {
                CentralDogmaGameCheckpointArt(badge: checkpoint.badge)
                Text(checkpoint.title).font(.system(.title2, design: .serif, weight: .bold))
                gameGuide(cueID: checkpoint.narrationID,
                          instruction: Text(checkpoint.body).font(.system(.body, design: .rounded)),
                          controlID: "central-dogma-checkpoint-listen")
                Text(checkpoint.badge).font(.system(.caption, design: .rounded, weight: .bold)).padding(9).background(CentralDogmaGameTheme.butter, in: Capsule())
                Button(session.isComplete ? "See my results" : "Keep going") { session.continueAfterCheckpoint() }
                    .buttonStyle(CentralDogmaGamePrimaryStyle())
            }
            .multilineTextAlignment(.center).padding(22).frame(maxWidth: 420)
            .background(CentralDogmaGameTheme.paper, in: RoundedRectangle(cornerRadius: 29)).padding(20)
            .foregroundStyle(CentralDogmaGameTheme.ink)
            .accessibilityElement(children: .contain)
            }.frame(maxWidth: 460, maxHeight: 620)
        }
    }
    private var victory: some View {
        VStack(spacing: 17) {
            Image(systemName: "trophy.fill").font(.system(size: 56)).foregroundStyle(CentralDogmaGameTheme.teal)
            Text("Message delivered!").font(.system(.title, design: .serif, weight: .bold))
            gameGuide(cueID: "game.complete", controlID: "central-dogma-results-listen")
            Text("\(session.score) points").font(.system(size: 34, weight: .bold, design: .rounded))
            Text("\(session.accuracy)% accuracy · best streak \(session.bestStreak)")
                .font(.system(.subheadline, design: .rounded))
            HStack { ForEach(0..<(session.accuracy >= 90 ? 3 : session.accuracy >= 75 ? 2 : 1), id: \.self) { _ in Image(systemName: "star.fill").font(.title).foregroundStyle(CentralDogmaGameTheme.color(0xD39D2F)) } }
            Text("You practiced transcription, processing, translation, folding, and protein finishing.")
                .font(.system(.body, design: .rounded)).multilineTextAlignment(.center)
            Text("Best completed score: \(bestScore)").font(.system(.caption, design: .rounded)).foregroundStyle(CentralDogmaGameTheme.muted)
            Button("New round · new stop codon") { restartRound() }.buttonStyle(CentralDogmaGamePrimaryStyle())
            Button("Done") { dismiss() }.frame(minHeight: 44)
        }.centralDogmaGamePanel(CentralDogmaGameTheme.butter)
    }
    private var fieldGuide: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("This mission follows a eukaryotic cell: transcription in the nucleus, translation at cytoplasmic ribosomes. Prokaryotic transcription occurs in the cytoplasm. The cap-based processing and initiation shown here are eukaryotic.")
                        .font(.system(.subheadline, design: .rounded)).centralDogmaGamePanel(CentralDogmaGameTheme.blue.opacity(0.4))
                    if let step = session.step {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(step.title).font(.system(.title2, design: .serif, weight: .bold))
                            ForEach(step.learn, id: \.self) { Text($0).font(.system(.body, design: .rounded)) }
                        }.centralDogmaGamePanel(CentralDogmaGameTheme.butter)
                    }
                    ForEach(CentralDogmaGameData.shared.players) { player in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(player.title).font(.system(.headline, design: .rounded))
                            ForEach(player.bullets, id: \.self) { text in
                                CentralDogmaGameRichText(value: "• " + text).font(.system(.subheadline, design: .rounded))
                            }
                        }.centralDogmaGamePanel()
                    }
                }.padding(20).foregroundStyle(CentralDogmaGameTheme.ink)
            }.background(CentralDogmaGameTheme.cream)
            .navigationTitle("Field guide").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { guide = false } } }
        }
    }
}

#Preview("RNA Relay") { NavigationStack { CentralDogmaGameView().environmentObject(LessonNarrator.centralDogma()) } }
