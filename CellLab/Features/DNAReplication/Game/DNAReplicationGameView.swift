import SwiftUI
import UIKit

/// Add to the same app target as the other five game source files. iOS 17+.
/// Supply the active S phase LessonNarrator when opening this game.
@MainActor struct DNAReplicationGameView: View {
    @EnvironmentObject private var narration: LessonNarrator
    var onComplete: (() -> Void)? = nil
    var backLabel = "Back to S phase"
    @State private var session = DNACopySession()
    @State private var showsGuide = false
    @State private var isDraggingNucleotide = false
    @State private var unzipAnimationFinished = false
    @AccessibilityFocusState private var celebrationFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption2) private var toolWidth: CGFloat = 76

    private var isUnzipping: Bool {
        session.stage == .unwind && session.unwound && !reduceMotion && !unzipAnimationFinished
    }
    private var celebrationVisible: Bool { session.celebration != nil && !isUnzipping }
    private var activeNarrationEvent: String? {
        guard !showsGuide else { return nil }
        if celebrationVisible { return session.celebration?.narrationID }
        guard session.celebration == nil else { return nil }
        return session.instructionNarrationID
    }

    var body: some View {
        GeometryReader { geometry in
            let width = max(1, min(geometry.size.width - 32, 520))
            ZStack(alignment: .bottom) {
                Group {
                    if dynamicTypeSize.isAccessibilitySize || session.stage == .complete {
                        scrollableGame(width: width)
                    } else {
                        fittedGame(size: geometry.size)
                    }
                }
                .accessibilityHidden(celebrationVisible)
                .allowsHitTesting(!celebrationVisible)
                if let card = session.celebration, celebrationVisible {
                    DNACopyStyle.ink.opacity(0.16).ignoresSafeArea()
                    celebration(card, availableHeight: geometry.size.height)
                        .frame(maxWidth: 490)
                        .padding(12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(2)
                }
            }
        }
        .background(DNACopyStyle.cream.ignoresSafeArea())
        .foregroundStyle(DNACopyStyle.ink)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showsGuide, onDismiss: narration.stop) {
            DNACopyFieldGuide().environmentObject(narration)
        }
        .onChange(of: activeNarrationEvent) { _, event in narration.gameEventChanged(event) }
        .onChange(of: showsGuide) { _, _ in narration.stop() }
        .onAppear { narration.stop(); narration.resetGameGuidance() }
        .onDisappear { narration.stop() }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: celebrationVisible)
        .sensoryFeedback(.success, trigger: session.successSerial)
        .sensoryFeedback(.warning, trigger: session.correctionSerial)
        .onChange(of: celebrationVisible) { _, visible in celebrationFocused = visible }
        .task(id: session.unwound) {
            guard session.unwound else { unzipAnimationFinished = false; return }
            guard !reduceMotion, scenePhase == .active else { unzipAnimationFinished = true; return }
            do { try await Task.sleep(for: .milliseconds(1600)) } catch { return }
            guard !Task.isCancelled else { return }
            unzipAnimationFinished = true
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                narration.stop()
                if session.unwound { unzipAnimationFinished = true }
            }
        }
        .onChange(of: session.notice) { _, message in
            guard UIAccessibility.isVoiceOverRunning, session.celebration == nil else { return }
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }

    private func fittedGame(size: CGSize) -> some View {
        let landscape = size.width > size.height * 1.2
        let compact = size.height < 700
        return VStack(spacing: 6) {
            header.padding(.horizontal, 16)
            if landscape {
                HStack(spacing: 12) {
                    fittedBoard
                    VStack(spacing: 6) {
                        instruction(compact: true)
                        selectionBar
                        toolTray
                    }
                    .frame(width: min(350, size.width * 0.46))
                }
                .padding(.horizontal, 12)
            } else {
                if !compact { progress.padding(.horizontal, 16) }
                VStack(spacing: 0) {
                    instruction(compact: compact).padding(.horizontal, 12).padding(.top, 8)
                    fittedBoard
                }
                .background(DNACopyStyle.butter, in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(DNACopyStyle.edge, lineWidth: 1.5).allowsHitTesting(false))
                .padding(.horizontal, 16)
                VStack(spacing: 0) {
                    selectionBar
                    toolTray
                }
                .fixedSize(horizontal: false, vertical: true)
                .background(DNACopyStyle.cream)
            }
        }
        .padding(.top, 4).padding(.bottom, 4)
        .frame(maxWidth: 1100).frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fittedBoard: some View {
        VStack(spacing: 0) {
            GeometryReader { area in
                // Fit the complete drawing. DNACopyBoard keeps its buttons at 56 pt;
                // only the molecular illustration and positions scale with width.
                let width = max(1, min(520, min(area.size.width - 12, area.size.height * 360 / 460)))
                DNACopyBoard(session: session, width: width, motionPaused: showsGuide || scenePhase != .active)
                    .frame(width: area.size.width, height: area.size.height)
            }
            DNACopyLegend().fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8).padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DNACopyStyle.butter, in: RoundedRectangle(cornerRadius: 24))
    }

    private func instruction(compact: Bool) -> some View {
        gameGuide(cueID: session.instructionNarrationID,
                  instruction: Text(isUnzipping ? "Helicase unzips the base pairs. Watch the strands separate." : session.instruction)
                    .font(.system(compact ? .caption : .subheadline, design: .rounded, weight: .medium)),
                  compact: true)
            .disabled(isUnzipping && narration.mode != .game)
    }

    private func scrollableGame(width: CGFloat) -> some View {
        // Large text and the final summary can scroll under the learner's control.
        // Selecting a tool or base never changes that scroll position.
        ScrollView {
            VStack(spacing: 16) {
                header
                progress
                workbench(width: width)
                if session.stage != .complete {
                    selectionBar
                    toolTray
                }
                DNACopyLegend().frame(maxWidth: .infinity)
                if session.stage == .complete { summary }
                Text("Shortened DNA, not to scale. Enzyme actions overlap in cells.")
                    .font(.system(.caption2, design: .rounded)).foregroundStyle(DNACopyStyle.muted)
            }
            .frame(width: width).padding(.top, 4).padding(.bottom, 20)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .scrollDisabled(isDraggingNucleotide)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(.body, weight: .bold))
                    .frame(width: 44, height: 44).background(DNACopyStyle.paper, in: Circle())
            }
            .accessibilityLabel(backLabel)
            Spacer(minLength: 0)
            VStack(spacing: 3) {
                Text(dynamicTypeSize.isAccessibilitySize ? "DNA Replication" : session.stage.title)
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1).minimumScaleFactor(0.75)
                Text("DNA replication · \(["Prepare", "Copy", "Finish"][session.stage.group])")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(DNACopyStyle.muted)
            }
            .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            Button { showsGuide = true } label: {
                Image(systemName: "book.closed").font(.system(.body, weight: .semibold))
                    .frame(width: 44, height: 44).background(DNACopyStyle.sage, in: Circle())
            }
            .accessibilityLabel("Open the DNA field guide")
        }
        .buttonStyle(.plain)
    }
    private var progress: some View {
        HStack(spacing: 8) {
            ForEach(Array(["Prepare", "Copy", "Finish"].enumerated()), id: \.offset) { index, name in
                HStack(spacing: 5) {
                    if index < session.stage.group || session.stage == .complete {
                        Image(systemName: "checkmark").font(.caption2.bold())
                    }
                    Text(name).font(.system(.caption, design: .rounded, weight: .bold))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 8)
                .background(session.stage.group == index ? DNACopyStyle.teal : DNACopyStyle.sage.opacity(0.5), in: Capsule())
                .foregroundStyle(session.stage.group == index ? DNACopyStyle.paper : DNACopyStyle.ink)
                .accessibilityLabel("\(name)\(session.stage.group == index ? ", current section" : "")")
            }
        }
    }
    private func workbench(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(session.stage.title)
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .accessibilityAddTraits(.isHeader)
                gameGuide(cueID: session.instructionNarrationID,
                          instruction: Text(isUnzipping ? "Helicase unzips the base pairs. Watch the strands separate." : session.instruction)
                            .font(.system(.subheadline, design: .rounded, weight: .medium)))
                    .disabled(isUnzipping && narration.mode != .game)
            }
            .padding(.horizontal, 18).padding(.top, 18)
            DNACopyBoard(session: session, width: width, motionPaused: showsGuide || scenePhase != .active,
                         onDraggingChanged: { isDraggingNucleotide = $0 })

        }
        .background(DNACopyStyle.butter, in: RoundedRectangle(cornerRadius: 27))
        .overlay(RoundedRectangle(cornerRadius: 27).strokeBorder(DNACopyStyle.edge, lineWidth: 1.5).allowsHitTesting(false))
    }
    private var selectionBar: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
            : AnyLayout(HStackLayout(spacing: 14))
        return VStack(alignment: .leading, spacing: 7) {
            Text(session.notice)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                .frame(height: dynamicTypeSize.isAccessibilitySize ? nil : 30, alignment: .leading)
                .foregroundStyle(DNACopyStyle.muted)
            layout {
                VStack(alignment: .leading, spacing: 3) {
                    Text("DNA built").font(.system(.caption2, design: .rounded))
                    Text("\(session.placedBases) / 16").font(.system(.subheadline, design: .rounded, weight: .bold))
                    ProgressView(value: Double(session.placedBases), total: 16).tint(DNACopyStyle.teal)
                        .frame(width: dynamicTypeSize.isAccessibilitySize ? nil : 75)
                        .accessibilityLabel("DNA nucleotides placed")
                        .accessibilityValue("\(session.placedBases) of 16")
                }
                Button { session.applySelection() } label: {
                    HStack(spacing: 8) {
                        Text(session.primaryActionTitle).fixedSize(horizontal: false, vertical: true)
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(session.canApplySelection ? DNACopyStyle.paper : DNACopyStyle.muted)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .padding(.horizontal, 12)
                    .background(session.canApplySelection ? DNACopyStyle.teal : DNACopyStyle.sage.opacity(0.5), in: RoundedRectangle(cornerRadius: 15))
                    .contentShape(RoundedRectangle(cornerRadius: 15))
                }
                .buttonStyle(.plain)
                .disabled(!session.canApplySelection)
                .accessibilityHint("Applies your selection to the highlighted target using the same DNA rules")
                .accessibilityIdentifier("dna-game-apply-selection")
            }
        }
        .padding(.horizontal, 18).padding(.top, dynamicTypeSize.isAccessibilitySize ? 10 : 0).padding(.bottom, 2)
        .frame(maxWidth: 556)
        .frame(maxWidth: .infinity)
    }
    private var toolTray: some View {
        VStack(alignment: .leading, spacing: 3) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 3) {
                    Text("YOUR TOOLKIT").font(.system(.caption2, design: .rounded, weight: .bold))
                    Text("Swipe for tools").font(.system(.caption2, design: .rounded))
                    Button { session.hint() } label: {
                        Image(systemName: "lightbulb").frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain).accessibilityLabel("A little hint")
                }
                .foregroundStyle(DNACopyStyle.muted)
                .padding(.horizontal, 18).padding(.top, 10)
            }
            HStack(spacing: 0) {
                ScrollViewReader { reader in
                    ScrollView(.horizontal) {
                        HStack(alignment: .top, spacing: 7) {
                            ForEach(DNACopyTool.allCases) { tool in
                                toolButton(tool).id(tool.id)
                            }
                        }
                        .padding(.horizontal, 14).padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 7 : 4)
                    }
                    .scrollIndicators(.hidden)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("dna-game-tools")
                    .onChange(of: session.neededTool) { _, tool in
                        guard let tool else { return }
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { reader.scrollTo(tool.id, anchor: .center) }
                    }
                }
                if !dynamicTypeSize.isAccessibilitySize {
                    Button { session.hint() } label: {
                        Image(systemName: "lightbulb").frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain).accessibilityLabel("A little hint")
                    .padding(.trailing, 6)
                }
            }
        }
    }
    private func toolButton(_ tool: DNACopyTool) -> some View {
        Button { session.choose(tool: tool) } label: {
            VStack(spacing: 3) {
                DNACopyToolImage(tool: tool)
                    .frame(width: dynamicTypeSize.isAccessibilitySize ? 47 : 34,
                           height: dynamicTypeSize.isAccessibilitySize ? 47 : 34)
                Text(tool.title).font(.system(.caption2, design: .rounded, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 28 : 24, alignment: .top)
            }
            .frame(width: dynamicTypeSize.isAccessibilitySize ? toolWidth : 68)
            .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 7 : 4)
            .background(session.selectedTool == tool ? DNACopyStyle.sage : DNACopyStyle.paper, in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(session.selectedTool == tool ? DNACopyStyle.teal : DNACopyStyle.edge.opacity(0.25), lineWidth: session.selectedTool == tool ? 2 : 1).allowsHitTesting(false))
            .contentShape(RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(.plain)
        .draggable(tool.payload) {
            DNACopyToolImage(tool: tool).frame(width: 70, height: 70).padding(8)
        }
        .accessibilityLabel("\(tool.title). \(tool.memory)")
        .accessibilityValue(session.selectedTool == tool ? "Selected" : "")
        .accessibilityHint("Drag onto the DNA target, or select then tap the target")
        .accessibilityIdentifier("dna-game-tool-\(tool.id)")
    }
    private func celebration(_ card: DNACopyCelebration, availableHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // The whole explanation scrolls when necessary. The Continue
            // control stays outside that scroll area and remains reachable.
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Group {
                            if let tool = session.selectedTool {
                                DNACopyToolImage(tool: tool).padding(3)
                            } else {
                                Image(systemName: card.isCheck ? "magnifyingglass" : "checkmark.seal.fill")
                                    .font(.system(size: 29, weight: .semibold))
                                    .foregroundStyle(DNACopyStyle.teal)
                            }
                        }
                        .frame(width: 52, height: 52)
                        .background(DNACopyStyle.sage, in: RoundedRectangle(cornerRadius: 17))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(card.isCheck ? "QUICK CHECK" : "WELL DONE!")
                                .font(.system(.caption2, design: .rounded, weight: .heavy))
                                .foregroundStyle(DNACopyStyle.teal)
                            Text(card.title).font(.system(.title2, design: .serif, weight: .bold))
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityFocused($celebrationFocused)
                        }
                    }
                    gameGuide(cueID: card.narrationID, controlID: "sphasePopupListenButton", explanation: true)
                    Text(card.body).font(.system(.body, design: .rounded))
                        .lineSpacing(3).frame(maxWidth: .infinity, alignment: .leading)
                    ScrollView(.horizontal) {
                        HStack(spacing: 6) {
                            ForEach(card.tags, id: \.self) { tag in
                                Text(tag).font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .padding(.horizontal, 10).padding(.vertical, 7)
                                    .background(DNACopyStyle.butter, in: Capsule())
                            }
                        }
                    }
                    .frame(height: 36)
                    .scrollIndicators(.hidden)
                }
            }
            .frame(height: min(290, max(60, availableHeight - 130)))
            .scrollBounceBehavior(.basedOnSize)
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { session.continueAfterCelebration() }
            } label: {
                HStack {
                    Text(card.isCheck ? "Let’s check it" : card.next == .complete ? "See my DNA copies" : "Keep going")
                    Spacer(); Image(systemName: "arrow.right")
                }
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(DNACopyStyle.paper)
                .padding(16).frame(minHeight: 50)
                .background(DNACopyStyle.teal, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("dna-game-continue")
        }
        .padding(18)
        .background(DNACopyStyle.paper, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(DNACopyStyle.edge, lineWidth: 1.5).allowsHitTesting(false))
        .shadow(color: DNACopyStyle.ink.opacity(0.14), radius: 20, y: 8)
    }
    private var summary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your copy is complete")
                .font(.system(.title2, design: .serif, weight: .bold))
            Label("\(session.placedBases) DNA nucleotides placed", systemImage: "checkmark.circle.fill")
            Label("Mismatch proofread and corrected", systemImage: "checkmark.circle.fill")
            Label("RNA replaced · backbone sealed", systemImage: "checkmark.circle.fill")
            HStack(spacing: 12) {
                Button("Play again") {
                    narration.resetGameGuidance()
                    session = DNACopySession()
                    unzipAnimationFinished = false
                    narration.gameEventChanged(session.instructionNarrationID)
                }
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(DNACopyStyle.paper, in: Capsule())
                Button("Done") { onComplete?(); dismiss() }
                    .foregroundStyle(DNACopyStyle.paper)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(DNACopyStyle.teal, in: Capsule())
            }
            .font(.system(.headline, design: .rounded)).buttonStyle(.plain)
        }
        .font(.system(.subheadline, design: .rounded))
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(DNACopyStyle.sage, in: RoundedRectangle(cornerRadius: 25))
        .overlay(RoundedRectangle(cornerRadius: 25).strokeBorder(DNACopyStyle.edge, lineWidth: 1.5).allowsHitTesting(false))
    }

    private func gameGuide(cueID: String, controlID: String = "sphaseGameListenButton",
                           instruction: Text? = nil, explanation: Bool = false, compact: Bool = false) -> some View {
        let subject = explanation ? "explanation" : "instruction"
        return LessonGuide(narrator: narration,
                           title: narration.isPlaying || (isUnzipping && narration.mode == .game) ? "Stop" : "\(narration.completedCues.contains(cueID) ? "Replay" : "Hear") \(subject)",
                           cueID: cueID,
                           action: {
                               if narration.isPlaying || isUnzipping { narration.stop() }
                               else { narration.startGameGuidance(cueID) }
                           },
                           showsStopBetweenClips: narration.mode == .game,
                           controlID: controlID, layoutTitle: "Replay \(subject)",
                           instruction: instruction, instructionID: "sphase-instruction", compactInstruction: compact)
    }
}

@MainActor private struct DNACopyFieldGuide: View {
    @EnvironmentObject private var narration: LessonNarrator
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Meet the copying crew")
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                    Text("A quick reference while you build.")
                        .font(.system(.subheadline, design: .rounded)).foregroundStyle(DNACopyStyle.muted)
                    LessonGuide(narrator: narration,
                                title: narration.isPlaying ? "Stop" : "Hear introduction",
                                cueID: "reference.players",
                                action: { narration.toggleStandalone("reference.players") },
                                controlID: "sphaseFieldGuideListenButton")
                    ForEach(DNACopyTerm.all) { term in
                        VStack(alignment: .leading, spacing: 9) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(term.title).font(.system(.headline, design: .rounded))
                                    Text(term.memory).font(.system(.caption, design: .rounded)).foregroundStyle(DNACopyStyle.teal)
                                }
                                Spacer(minLength: 4)
                                if let tool = term.tool { DNACopyToolImage(tool: tool).frame(width: 49, height: 49) }
                                NarrationSpeakerButton(cueID: term.narrationID, title: term.title)
                            }
                            Text(term.body).font(.system(.subheadline, design: .rounded)).lineSpacing(3)
                        }
                        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                        .background(DNACopyStyle.paper, in: RoundedRectangle(cornerRadius: 21))
                        .overlay(RoundedRectangle(cornerRadius: 21).strokeBorder(DNACopyStyle.edge.opacity(0.3), lineWidth: 1).allowsHitTesting(false))
                    }
                }
                .padding(20).frame(maxWidth: 580).frame(maxWidth: .infinity)
            }
            .background(DNACopyStyle.cream)
            .foregroundStyle(DNACopyStyle.ink)
            .navigationTitle("DNA field guide").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .tint(DNACopyStyle.ink)
        .onDisappear { narration.stop() }
    }
}

#Preview {
    NavigationStack { DNAReplicationGameView().environmentObject(LessonNarrator.sphase()) }
}
