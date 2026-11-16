import SwiftUI

/// One familiar guide control, configured by its lesson's title and recordings.
struct LessonGuide: View {
    @ObservedObject var narrator: LessonNarrator
    let title: String
    let cueID: String
    let action: () -> Void
    var showsStopBetweenClips = false
    var replayOverview: (() -> Void)?
    var controlID: String? = nil
    var showsTranscriptOption = true
    var layoutTitle = "Replay instruction"
    var instruction: Text? = nil
    @State private var transcript: NarrationRecording?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if let instruction {
                HStack(alignment: .top, spacing: 8) {
                    primaryButton(artOnly: true)
                    VStack(alignment: .leading, spacing: 4) {
                        instruction
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("mitosis-instruction")
                        HStack(spacing: 4) {
                            Button(action: action) { playbackLabel }
                                .buttonStyle(.plain)
                                .frame(minHeight: 44, alignment: .leading)
                                .accessibilityHidden(true) // The mascot exposes the same action.
                            Spacer(minLength: 0)
                            trailingControls
                        }
                    }
                }
            } else {
                HStack(spacing: 4) {
                    primaryButton(artOnly: false)
                    trailingControls
                }
            }
        }
        .tint(.teal)
        .sheet(item: $transcript) { recording in
            NarrationTranscript(narrator: narrator, recording: recording)
        }
    }

    private var mascot: some View {
        TimelineView(.animation(minimumInterval: 0.24, paused: !narrator.isPlaying || reduceMotion)) { time in
            MitosisAxolotl(
                isSpeaking: narrator.isPlaying && !reduceMotion
                    && sin(time.date.timeIntervalSince1970 * .pi * 3) > 0.25,
                fittedToArtwork: true
            )
        }
        .frame(width: 48 * 160 / 136, height: 48)
    }

    private func primaryButton(artOnly: Bool) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                mascot
                if !artOnly {
                    playbackLabel
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: artOnly ? nil : .infinity, minHeight: 48, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(controlID ?? "narration-guide-\(cueID)")
        .accessibilityLabel(narrator.isPlaying ? "Stop narration" : title == "Hear overview" ? "Hear \(narrator.library.lessonTitle.lowercased()) overview" : title)
        .accessibilityValue(narrator.isPlaying ? "Speaking \(narrator.library[narrator.currentCueID ?? ""]?.title ?? "")" : "Quiet")
    }

    private var playbackLabel: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 6) {
                Image(systemName: "speaker.wave.2.fill").font(.system(size: 14, weight: .semibold)).frame(width: 18)
                Text(layoutTitle)
            }
            .hidden()
            .accessibilityHidden(true)
            HStack(spacing: 6) {
                Image(systemName: narrator.isPlaying ? "stop.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 18)
                    .contentTransition(.opacity)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: narrator.isPlaying)
                Text(title)
            }
        }
        .font(.system(.subheadline, design: .rounded, weight: .semibold))
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var trailingControls: some View {
        if showsStopBetweenClips && !narrator.isPlaying {
            Button { narrator.stop() } label: {
                Image(systemName: "stop.fill").frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Stop narration")
            .accessibilityIdentifier("\(controlID ?? "narration-guide-\(cueID)")-stop")
        }
        if replayOverview != nil || showsTranscriptOption {
            Menu {
                if let replayOverview {
                    Button("Replay overview", systemImage: "arrow.counterclockwise", action: replayOverview)
                }
                if showsTranscriptOption, let recording = narrator.library[cueID] {
                    Button("Read transcript", systemImage: "text.alignleft") {
                        narrator.stop()
                        transcript = recording
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle").frame(width: 44, height: 44)
            }
            .accessibilityLabel("Narration options")
            .accessibilityIdentifier("\(controlID ?? "narration-guide-\(cueID)")-options")
        }
    }
}

struct NarrationSpeakerButton: View {
    @EnvironmentObject private var narrator: LessonNarrator
    let cueID: String
    let title: String
    @State private var transcript: NarrationRecording?

    private var speaking: Bool { narrator.isPlaying && narrator.currentCueID == cueID }

    var body: some View {
        Menu {
            Button(speaking ? "Stop narration" : "Hear \(title)", systemImage: speaking ? "stop.fill" : "speaker.wave.2.fill") {
                narrator.toggleStandalone(cueID)
            }
            if let recording = narrator.library[cueID] {
                Button("Read transcript", systemImage: "text.alignleft") {
                    narrator.stop()
                    transcript = recording
                }
            }
        } label: {
            Image(systemName: speaking ? "stop.fill" : "speaker.wave.2.fill")
                .frame(width: 44, height: 44)
        } primaryAction: {
            narrator.toggleStandalone(cueID)
        }
        .accessibilityLabel(speaking ? "Stop \(title) narration" : "Hear \(title)")
        .accessibilityIdentifier("narration-\(cueID)")
        .sheet(item: $transcript) { recording in
            NarrationTranscript(narrator: narrator, recording: recording)
        }
    }
}

struct NarrationTranscript: View {
    @ObservedObject var narrator: LessonNarrator
    let recording: NarrationRecording
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    LessonGuide(narrator: narrator,
                                title: narrator.isPlaying ? "Stop" : "Hear recording",
                                cueID: recording.id,
                                action: { narrator.toggleStandalone(recording.id) },
                                controlID: "narrationTranscriptListenButton", showsTranscriptOption: false)
                    Text(recording.title).font(.title2.bold()).accessibilityAddTraits(.isHeader)
                    Text(recording.text).font(.body).fixedSize(horizontal: false, vertical: true)
                }
                .padding(22)
            }
            .navigationTitle("Transcript")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .onDisappear { narrator.stop() }
    }
}
