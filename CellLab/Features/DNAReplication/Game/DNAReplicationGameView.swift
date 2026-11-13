import SwiftUI
import UIKit

/// Add to the same app target as the other five game source files. iOS 17+.
/// Open with NavigationLink { DNAReplicationGameView() } label: { ... }.
@MainActor struct DNAReplicationGameView: View {
    var onComplete: (() -> Void)? = nil
    @State private var session = DNACopySession()
    @State private var showsGuide = false
    @AccessibilityFocusState private var celebrationFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width - 32, 520)
            ZStack(alignment: .bottom) {
                ScrollViewReader { reader in
                  ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        progress
                        workbench(width: width).id("workbench")
                        DNACopyLegend().frame(maxWidth: .infinity)
                        if session.stage == .complete { summary }
                        else { helperRow }
                        Text("Shortened DNA, not to scale. Enzyme actions overlap in cells.")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(DNACopyStyle.muted)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(width: width)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                  }
                  .scrollIndicators(.hidden)
                  .onChange(of: session.stage) { _, _ in
                      withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { reader.scrollTo("workbench", anchor: .top) }
                  }
                }
                .accessibilityHidden(session.celebration != nil)
                .allowsHitTesting(session.celebration == nil)

                if let card = session.celebration {
                    DNACopyStyle.ink.opacity(0.16).ignoresSafeArea()
                    celebration(card)
                        .frame(maxWidth: 490)
                        .padding(16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(2)
                }
            }
        }
        .background(DNACopyStyle.cream.ignoresSafeArea())
        .foregroundStyle(DNACopyStyle.ink)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if session.stage != .complete {
                toolTray
                    .allowsHitTesting(session.celebration == nil)
                    .accessibilityHidden(session.celebration != nil)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showsGuide) { DNACopyFieldGuide() }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: session.celebration?.id)
        .sensoryFeedback(.success, trigger: session.successSerial)
        .sensoryFeedback(.warning, trigger: session.correctionSerial)
        .onChange(of: session.celebration?.id) { _, value in celebrationFocused = value != nil }
        .onChange(of: session.notice) { _, message in
            guard UIAccessibility.isVoiceOverRunning, session.celebration == nil else { return }
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(.body, weight: .bold))
                    .frame(width: 44, height: 44).background(DNACopyStyle.paper, in: Circle())
            }
            .accessibilityLabel("Back to DNA Replication")
            Spacer(minLength: 0)
            VStack(spacing: 3) {
                Text("DNA Replication").font(.system(.title3, design: .serif, weight: .bold))
                Text("Copy the code · S phase")
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
                Text(session.instruction)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 18).padding(.top, 18)
            DNACopyBoard(session: session, width: width, motionPaused: showsGuide || scenePhase != .active)
            if session.stage != .complete {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkle").foregroundStyle(DNACopyStyle.teal)
                    Text(session.notice).fixedSize(horizontal: false, vertical: true)
                }
                .font(.system(.caption, design: .rounded, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(13)
                .background(DNACopyStyle.paper.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 14).padding(.bottom, 14)
            }
        }
        .background(DNACopyStyle.butter, in: RoundedRectangle(cornerRadius: 27))
        .overlay(RoundedRectangle(cornerRadius: 27).strokeBorder(DNACopyStyle.edge, lineWidth: 1.5))
        .accessibilityIdentifier("dna-game-workbench")
    }
    private var helperRow: some View {
        HStack {
            Button { session.hint() } label: { Label("A little hint", systemImage: "lightbulb") }
            Spacer()
            Text("Drag, or select then tap")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(DNACopyStyle.muted)
        }
        .font(.system(.caption, design: .rounded, weight: .semibold))
        .buttonStyle(.plain)
        .frame(minHeight: 44)
    }
    private var toolTray: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("YOUR TOOLKIT").font(.system(.caption2, design: .rounded, weight: .bold))
                Spacer()
                Image(systemName: "arrow.left.and.right")
                Text("Swipe for tools").font(.system(.caption2, design: .rounded))
            }
            .foregroundStyle(DNACopyStyle.muted)
            .padding(.horizontal, 18).padding(.top, 10)
            ScrollViewReader { reader in
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 7) {
                        ForEach(DNACopyTool.allCases) { tool in
                            toolButton(tool).id(tool.id)
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 7)
                }
                .scrollIndicators(.hidden)
                .onChange(of: session.neededTool) { _, tool in
                    guard let tool else { return }
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { reader.scrollTo(tool.id, anchor: .center) }
                }
            }
        }
        .background(DNACopyStyle.cream.shadow(color: DNACopyStyle.ink.opacity(0.1), radius: 12, y: -4))
    }
    private func toolButton(_ tool: DNACopyTool) -> some View {
        Button { session.choose(tool: tool) } label: {
            VStack(spacing: 3) {
                DNACopyToolImage(tool: tool).frame(width: 47, height: 47)
                Text(tool.title).font(.system(.caption2, design: .rounded, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 28, alignment: .top)
            }
            .frame(width: 76).padding(.vertical, 7)
            .background(session.selectedTool == tool ? DNACopyStyle.sage : DNACopyStyle.paper, in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(session.selectedTool == tool ? DNACopyStyle.teal : DNACopyStyle.edge.opacity(0.25), lineWidth: session.selectedTool == tool ? 2 : 1))
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
    private func celebration(_ card: DNACopyCelebration) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 12) {
                Image(systemName: card.isCheck ? "magnifyingglass" : "checkmark.seal.fill")
                    .font(.system(size: 29, weight: .semibold))
                    .foregroundStyle(DNACopyStyle.teal)
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
            ScrollView {
                Text(card.body).font(.system(.body, design: .rounded))
                    .lineSpacing(3).frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 155)
            .scrollBounceBehavior(.basedOnSize)
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(card.tags, id: \.self) { tag in
                        Text(tag).font(.system(.caption2, design: .rounded, weight: .semibold))
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .background(DNACopyStyle.butter, in: Capsule())
                    }
                }
            }
            .scrollIndicators(.hidden)
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { session.continueAfterCelebration() }
            } label: {
                HStack {
                    Text(card.isCheck ? "Let’s check it" : card.next == .complete ? "See my DNA copies" : "Keep going")
                    Spacer(); Image(systemName: "arrow.right")
                }
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(DNACopyStyle.paper)
                .padding(16).background(DNACopyStyle.teal, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("dna-game-continue")
        }
        .padding(21)
        .background(DNACopyStyle.paper, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(DNACopyStyle.edge, lineWidth: 1.5))
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
                Button("Play again") { session = DNACopySession() }
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
        .overlay(RoundedRectangle(cornerRadius: 25).strokeBorder(DNACopyStyle.edge, lineWidth: 1.5))
    }
}

@MainActor private struct DNACopyFieldGuide: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Meet the copying crew")
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                    Text("A quick reference while you build.")
                        .font(.system(.subheadline, design: .rounded)).foregroundStyle(DNACopyStyle.muted)
                    ForEach(DNACopyTerm.all) { term in
                        VStack(alignment: .leading, spacing: 9) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(term.title).font(.system(.headline, design: .rounded))
                                    Text(term.memory).font(.system(.caption, design: .rounded)).foregroundStyle(DNACopyStyle.teal)
                                }
                                Spacer(minLength: 4)
                                if let tool = term.tool { DNACopyToolImage(tool: tool).frame(width: 49, height: 49) }
                            }
                            Text(term.body).font(.system(.subheadline, design: .rounded)).lineSpacing(3)
                        }
                        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                        .background(DNACopyStyle.paper, in: RoundedRectangle(cornerRadius: 21))
                        .overlay(RoundedRectangle(cornerRadius: 21).strokeBorder(DNACopyStyle.edge.opacity(0.3), lineWidth: 1))
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
    }
}

#Preview {
    NavigationStack { DNAReplicationGameView() }
}
