//
//  CellLifeCycleView.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/13/26.
//

import SwiftUI
import UIKit

struct CellLifeCycleView: View {
    @StateObject private var narration: LessonNarrator
    @State private var phase: CellCyclePhase
    @State private var mitosisStep: CellCycleMitosisStep = .prophase
    @State private var cellKind: CellCycleCellKind = .animal
    @State private var playerSheet: CellCyclePlayerRoute?
    @State private var hasStartedOverview = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @AccessibilityFocusState private var detailFocused: Bool

    init(initialPhase: CellCyclePhase = .g1) {
        _phase = State(initialValue: initialPhase)
        _narration = StateObject(wrappedValue: .cellLifeCycle(initialPhaseID:
            CellCycleNarration.cueID(phase: initialPhase, step: .prophase, kind: .animal)))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Cell Life Cycle")
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                        .foregroundStyle(CellCyclePalette.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Growth, genome replication & division.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(CellCyclePalette.muted)
                    LessonGuide(narrator: narration,
                                title: narration.isPlaying ? "Stop" : hasStartedOverview ? narration.lessonButtonTitle : "Hear overview",
                                cueID: narration.isPlaying ? (narration.currentCueID ?? narration.overviewCueID)
                                    : (hasStartedOverview ? selectedCueID : narration.overviewCueID),
                                action: {
                                    if narration.isPlaying { narration.stop() }
                                    else if !hasStartedOverview { playOverview() }
                                    else { narration.toggleLesson() }
                                },
                                showsStopBetweenClips: narration.mode == .lesson,
                                replayOverview: playOverview,
                                controlID: "cycle-listen", layoutTitle: "Hear overview")
                        .padding(.top, 3)
                }

                VStack(spacing: 0) {
                    CellCycleWheel(selection: $phase)
                    Text("Tap a section to explore.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(CellCyclePalette.muted)
                }

                phaseCard

                Button {
                    playerSheet = CellCyclePlayerRoute(id: "chromosomes")
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "books.vertical")
                            .font(.title3)
                        Text("Meet the key players")
                            .font(.system(.headline, design: .rounded))
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.right")
                            .font(.system(.body, weight: .bold))
                    }
                    .foregroundStyle(CellCyclePalette.ink)
                    .padding(20)
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .background(CellCycleTint.sage.color, in: RoundedRectangle(cornerRadius: 23))
                    .overlay(RoundedRectangle(cornerRadius: 23).strokeBorder(CellCyclePalette.edge, lineWidth: 1.5))
                    .contentShape(RoundedRectangle(cornerRadius: 23))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("cycle-meet-key-players")

                Text("Cycle sections are schematic, not a measure of time.")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(CellCyclePalette.muted)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: 580)
            .frame(maxWidth: .infinity)
        }
        .background(CellCyclePalette.cream.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .tint(CellCyclePalette.ink)
        .environmentObject(narration)
        .onDisappear { narration.stop() }
        .onChange(of: selectedCueID) { _, id in narration.selectPhase(id) }
        .onChange(of: playerSheet?.id) { _, _ in narration.stop() }
        .onChange(of: scenePhase) { _, state in if state != .active { narration.stop() } }
        .alert("Audio unavailable", isPresented: Binding(
            get: { narration.errorMessage != nil }, set: { if !$0 { narration.errorMessage = nil } }
        )) { Button("OK", role: .cancel) { narration.errorMessage = nil } }
        message: { Text(narration.errorMessage ?? "Please try again.") }
        .sheet(item: $playerSheet) { route in
            CellCycleKeyPlayersView(initialPlayerID: route.id)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
        }
        .onChange(of: phase) { _, _ in
            // A phase tap leaves the ring in place; details update directly beneath it.
            // VoiceOver can move from the selected segment to the new heading.
            if UIAccessibility.isVoiceOverRunning { detailFocused = true }
        }
    }

    private var phaseCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(phase.content.group.uppercased())
                .font(.system(.caption, design: .rounded, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(CellCyclePalette.ink.opacity(0.75))

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(phase.content.title)
                        .font(.system(.title, design: .serif, weight: .bold))
                        .foregroundStyle(CellCyclePalette.ink)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($detailFocused)
                        .accessibilityIdentifier("cycle-phase-title")
                    Text(phase.content.subtitle)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(CellCyclePalette.muted)
                }
                Spacer(minLength: 4)
                NarrationSpeakerButton(cueID: selectedCueID, title: selectedCueTitle)
            }

            if let summary = phase.content.summary {
                CellCycleRichText(summary)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(CellCyclePalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if phase == .mitosis {
                mitosisPicker
                Text(mitosisStep.content.title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(CellCyclePalette.ink)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("cycle-mitosis-title")
                CellCycleBullets(items: mitosisStep.content.bullets)
            } else if phase == .cytokinesis {
                Picker("Cell type", selection: $cellKind) {
                    ForEach(CellCycleCellKind.allCases) { kind in
                        Text(kind.content.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("cycle-cell-type")
                CellCycleBullets(items: cellKind.content.bullets)
            } else {
                CellCycleBullets(items: phase.content.bullets)
            }

            if let checkpoint = selectedCheckpoint {
                Button {
                    playerSheet = CellCyclePlayerRoute(id: checkpointPlayerID)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: "checkmark.shield")
                        Text(checkpoint)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.caption2.bold())
                    }
                    .font(.system(.footnote, design: .rounded, weight: .medium))
                    .foregroundStyle(CellCyclePalette.ink)
                    .padding(12)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .background(CellCyclePalette.paper.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens this checkpoint in Meet the key players.")
                .accessibilityIdentifier("cycle-checkpoint")
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(phase.content.tint.color.opacity(0.68), in: RoundedRectangle(cornerRadius: 27))
        .overlay(RoundedRectangle(cornerRadius: 27).strokeBorder(CellCyclePalette.edge, lineWidth: 1.5))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: phase)
        .accessibilityIdentifier("cycle-detail-card")
    }

    private var mitosisPicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(CellCycleMitosisStep.allCases) { step in
                        Button { mitosisStep = step } label: {
                            Text(step.content.title)
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(mitosisStep == step ? CellCyclePalette.paper : CellCyclePalette.ink)
                                .padding(.horizontal, 13)
                                .frame(minHeight: 44)
                                .background(
                                    mitosisStep == step ? CellCyclePalette.ink : CellCyclePalette.paper.opacity(0.65),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                        .id(step)
                        .accessibilityValue(mitosisStep == step ? "Selected" : "")
                        .accessibilityIdentifier("cycle-mitosis-\(step.rawValue)")
                    }
                }
                .padding(.vertical, 2)
            }
            .onChange(of: mitosisStep) { _, newValue in
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    private var selectedCheckpoint: String? {
        phase == .mitosis ? mitosisStep.content.checkpoint : phase.content.checkpoint
    }

    private var selectedCueID: String {
        CellCycleNarration.cueID(phase: phase, step: mitosisStep, kind: cellKind)
    }

    private func playOverview() {
        hasStartedOverview = true
        narration.playOverview()
    }

    private var selectedCueTitle: String {
        narration.library[selectedCueID]?.title ?? phase.content.title
    }

    private var checkpointPlayerID: String {
        switch phase {
        case .g1: return "p53"
        case .s, .g2: return "replicationChecks"
        case .mitosis: return "kinetochores"
        default: return "chromosomes"
        }
    }
}

private struct CellCyclePlayerRoute: Identifiable {
    let id: String
}

#Preview("Cell life cycle") {
    NavigationStack { CellLifeCycleView() }
}
