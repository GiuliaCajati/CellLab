import AVFAudio
import Combine
import Foundation

@MainActor
final class MitosisNarrationPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var isPlaying = false
    @Published var errorMessage: String?

    private let recordingURL: URL?
    private var player: AVAudioPlayer?
    private var audioSessionIsActive = false

    init(recordingURL: URL? = Bundle.main.url(forResource: "mitosis-opening", withExtension: "wav")) {
        self.recordingURL = recordingURL
        super.init()
    }

    func toggle() {
        if isPlaying {
            stop()
        } else {
            play()
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        if audioSessionIsActive {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            audioSessionIsActive = false
        }
    }

    private func play() {
        errorMessage = nil
        guard let recordingURL else {
            errorMessage = "The mitosis recording could not be found."
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try audioSession.setActive(true)
            audioSessionIsActive = true

            let recording = try AVAudioPlayer(contentsOf: recordingURL)
            recording.delegate = self
            player = recording
            guard recording.play() else {
                stop()
                errorMessage = "The recording could not start. Please try again."
                return
            }
            isPlaying = true
        } catch {
            stop()
            errorMessage = "The recording could not play. Please try again."
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let finishedPlayer = ObjectIdentifier(player)
        Task { @MainActor [weak self] in
            guard let self, self.player.map(ObjectIdentifier.init) == finishedPlayer else { return }
            self.stop()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        let failedPlayer = ObjectIdentifier(player)
        Task { @MainActor [weak self] in
            guard let self, self.player.map(ObjectIdentifier.init) == failedPlayer else { return }
            self.stop()
            self.errorMessage = "The recording could not play. Please try again."
        }
    }
}
