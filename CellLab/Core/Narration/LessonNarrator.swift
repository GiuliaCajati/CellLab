import AVFAudio
import Combine
import Foundation
import UIKit

nonisolated struct NarrationRecording: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let text: String
    let resource: String
    let event: String
}

nonisolated struct NarrationLibrary: Codable {
    let lessonTitle: String
    let recordings: [NarrationRecording]

    subscript(_ id: String) -> NarrationRecording? { recordings.first { $0.id == id } }

    static func load(resource: String, bundle: Bundle = .main) throws -> Self {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
    }
}

@MainActor
protocol NarrationPlayback: AnyObject {
    var onCompletion: ((UUID, Bool) -> Void)? { get set }
    func play(url: URL, token: UUID) throws
    func stop()
}

/// The only object that touches AVAudioPlayer/AVAudioSession in an active lesson.
@MainActor
final class LocalNarrationPlayback: NSObject, NarrationPlayback, AVAudioPlayerDelegate {
    var onCompletion: ((UUID, Bool) -> Void)?
    private var player: AVAudioPlayer?
    private var token: UUID?
    private var sessionIsActive = false

    func play(url: URL, token: UUID) throws {
        guard url.isFileURL else { throw CocoaError(.fileReadUnsupportedScheme) }
        stop()
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
        try session.setActive(true)
        sessionIsActive = true
        do {
            let recording = try AVAudioPlayer(contentsOf: url)
            recording.delegate = self
            self.player = recording
            self.token = token
            guard recording.play() else { throw CocoaError(.fileReadUnknown) }
        } catch {
            stop()
            throw error
        }
    }

    func stop() {
        token = nil
        player?.stop()
        player = nil
        if sessionIsActive {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            sessionIsActive = false
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        finish(ObjectIdentifier(player), success: flag)
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        finish(ObjectIdentifier(player), success: false)
    }

    private nonisolated func finish(_ identity: ObjectIdentifier, success: Bool) {
        Task { @MainActor [weak self] in
            guard let self, self.player.map(ObjectIdentifier.init) == identity, let token = self.token else { return }
            self.stop()
            self.onCompletion?(token, success)
        }
    }
}

/// Reusable lesson/game sequencing. Clips, transcripts, and titles come from a library.
@MainActor
final class LessonNarrator: ObservableObject {
    enum Mode { case quiet, lesson, game }
    let library: NarrationLibrary
    @Published private(set) var isPlaying = false
    @Published private(set) var isScheduled = false
    @Published private(set) var currentCueID: String?
    @Published private(set) var mode: Mode = .quiet
    @Published private(set) var visiblePhase: String
    @Published private(set) var hasBegunLesson = false
    @Published private(set) var completedCues: Set<String> = []
    @Published var errorMessage: String?

    private let playback: any NarrationPlayback
    private let resolveURL: (NarrationRecording) -> URL?
    let overviewCueID: String
    private let phaseDelay: TimeInterval
    private let overviewDelay: TimeInterval
    private let phaseNames: [String: String]
    private var playbackToken: UUID?
    private var workID = UUID()
    private var delayedStart: Task<Void, Never>?
    private var playedGameEvents: Set<String> = []
    private var lifecycleObservers: Set<AnyCancellable> = []

    // Avoid the isolated-deinit TaskLocal runtime crash on iOS 26.2.
    // All playback/task cleanup is explicit in stop(), on the main actor.
    nonisolated deinit {}

    init(library: NarrationLibrary, playback: (any NarrationPlayback)? = nil,
         overviewCueID: String = "lesson.overview", initialPhaseID: String = "lesson.prophase",
         phaseNames: [String: String] = [:],
         phaseDelay: TimeInterval = 0.25, overviewDelay: TimeInterval = 0.35,
         resolveURL: @escaping (NarrationRecording) -> URL? = { recording in
             let path = recording.resource as NSString
             return Bundle.main.url(forResource: path.deletingPathExtension, withExtension: path.pathExtension)
         }) {
        self.library = library
        self.overviewCueID = overviewCueID
        self.visiblePhase = initialPhaseID
        self.phaseNames = phaseNames
        self.playback = playback ?? LocalNarrationPlayback()
        self.phaseDelay = phaseDelay
        self.overviewDelay = overviewDelay
        self.resolveURL = resolveURL
        self.playback.onCompletion = { [weak self] token, success in
            self?.finished(token: token, success: success)
        }
        // Observe in the shared owner, including when the lesson view is behind the game.
        let interruptions = NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .filter { notification in
                (notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt)
                    == AVAudioSession.InterruptionType.began.rawValue
            }
        interruptions
            .merge(with: NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated { self?.stop() }
            }
            .store(in: &lifecycleObservers)
    }

    static func mitosis() -> LessonNarrator {
        let library = (try? NarrationLibrary.load(resource: "mitosis-narration"))
            ?? NarrationLibrary(lessonTitle: "Mitosis", recordings: [])
        return LessonNarrator(library: library)
    }

    static func meiosis() -> LessonNarrator {
        let library = (try? NarrationLibrary.load(resource: "meiosis-narration"))
            ?? NarrationLibrary(lessonTitle: "Meiosis", recordings: [])
        return LessonNarrator(library: library, initialPhaseID: MeiPhase.prophaseI.narrationID,
                              phaseNames: Dictionary(uniqueKeysWithValues: MeiPhase.allCases.map { ($0.narrationID, $0.title) }))
    }

    static func sphase() -> LessonNarrator {
        let library = (try? NarrationLibrary.load(resource: "sphase-narration"))
            ?? NarrationLibrary(lessonTitle: "S phase", recordings: [])
        return LessonNarrator(library: library, initialPhaseID: DNAReplicationStep.origins.narrationID,
                              phaseNames: Dictionary(uniqueKeysWithValues: DNAReplicationStep.carouselCases.map {
                                  ($0.narrationID, $0.content.title)
                              }))
    }

    static func centralDogma() -> LessonNarrator {
        let library = (try? NarrationLibrary.load(resource: "central-dogma-narration"))
            ?? NarrationLibrary(lessonTitle: "Central Dogma", recordings: [])
        return LessonNarrator(library: library,
                              initialPhaseID: CentralDogmaStep.transcriptionStart.narrationID,
                              phaseNames: Dictionary(uniqueKeysWithValues: CentralDogmaStep.carouselCases.map {
                                  ($0.narrationID, $0.content.title)
                              }))
    }

    static func cellStructures() -> LessonNarrator {
        let library = (try? NarrationLibrary.load(resource: "cell-structures-narration"))
            ?? NarrationLibrary(lessonTitle: "Cell Structures", recordings: [])
        return LessonNarrator(library: library, initialPhaseID: CSPart.nucleus.narrationID,
                              phaseNames: Dictionary(uniqueKeysWithValues: CSPart.allCases.map {
                                  ($0.narrationID, $0.content.title)
                              }))
    }

    var phaseName: String {
        phaseNames[visiblePhase]
            ?? visiblePhase.split(separator: ".").last.map { String($0).capitalized }
            ?? library.lessonTitle
    }
    var lessonButtonTitle: String {
        if isPlaying { return "Stop" }
        if !hasBegunLesson { return "Hear overview" }
        return "\(completedCues.contains(visiblePhase) ? "Replay" : "Hear") \(phaseName)"
    }

    func toggleLesson() {
        if isPlaying { stop() }
        else if !hasBegunLesson { playOverview() }
        else { playPhase() }
    }

    func playOverview() {
        mode = .lesson
        hasBegunLesson = true
        play(overviewCueID)
    }

    func playPhase() {
        mode = .lesson
        hasBegunLesson = true
        play(visiblePhase)
    }

    /// The selected, settled page is the only automatic phase trigger.
    func selectPhase(_ id: String) {
        guard id != visiblePhase else { return }
        visiblePhase = id
        hasBegunLesson = true
        guard mode == .lesson else { return }
        interrupt()
        schedule(id, delay: phaseDelay)
    }

    func playStandalone(_ id: String) {
        mode = .quiet
        play(id)
    }

    func toggleStandalone(_ id: String) {
        if isPlaying && currentCueID == id { stop() }
        else { playStandalone(id) }
    }

    func startGameGuidance(_ event: String) {
        mode = .game
        playedGameEvents.insert(event)
        play(event)
    }

    func gameEventChanged(_ event: String?) {
        guard mode == .game else { return }
        if let event, currentCueID == event, isPlaying { return }
        interrupt()
        guard let event, playedGameEvents.insert(event).inserted else { return }
        play(event)
    }

    func resetGameGuidance() {
        interrupt()
        playedGameEvents.removeAll()
    }

    func stop() {
        interrupt()
        mode = .quiet
    }

    private func interrupt() {
        workID = UUID()
        delayedStart?.cancel()
        delayedStart = nil
        isScheduled = false
        playbackToken = nil
        playback.stop()
        isPlaying = false
    }

    private func schedule(_ id: String, delay: TimeInterval) {
        let request = workID
        isScheduled = true
        delayedStart = Task { @MainActor [weak self] in
            do { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
            catch { return }
            guard let self, !Task.isCancelled, self.workID == request, self.mode == .lesson else { return }
            self.play(id)
        }
    }

    private func play(_ id: String) {
        interrupt()
        errorMessage = nil
        guard let recording = library[id], let url = resolveURL(recording) else {
            errorMessage = "This recording could not be found."
            mode = .quiet
            return
        }
        currentCueID = id
        let token = UUID()
        playbackToken = token
        do {
            try playback.play(url: url, token: token)
            isPlaying = true
        } catch {
            stop()
            errorMessage = "The recording could not play. Please try again."
        }
    }

    private func finished(token: UUID, success: Bool) {
        guard playbackToken == token, let id = currentCueID else { return }
        playbackToken = nil
        isPlaying = false
        guard success else {
            stop()
            errorMessage = "The recording could not play. Please try again."
            return
        }
        completedCues.insert(id)
        if mode == .lesson && id == overviewCueID {
            schedule(visiblePhase, delay: overviewDelay)
        }
    }
}
