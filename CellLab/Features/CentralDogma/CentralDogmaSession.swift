// CentralDogmaSession.swift — one deterministic clock, shared by the page and enlarged diagram.
import Foundation
import Observation

@MainActor @Observable final class CentralDogmaSession {
    // Match the shared lesson sessions on iOS 26.2.
    nonisolated deinit {}
    @ObservationIgnored private var clockID: UUID?
    var step: CentralDogmaStep
    var progress: Double = 0
    var isPlaying = false
    var autoAdvance = false
    private var completionHold: Double = 0

    init(step: CentralDogmaStep = .transcriptionStart) {
        self.step = step
    }

    func select(_ newStep: CentralDogmaStep, play: Bool) {
        completionHold = 0
        step = newStep
        progress = play ? 0 : 1
        isPlaying = play
    }

    func replay(play: Bool) {
        completionHold = 0
        progress = play ? 0 : 1
        isPlaying = play
    }

    func togglePlayback() {
        if progress >= 1 { progress = 0; completionHold = 0 }
        isPlaying.toggle()
    }

    func advance(by seconds: Double) {
        guard isPlaying else { return }
        let elapsed = max(0, seconds)
        if progress < 1 {
            progress = min(1, progress + elapsed / step.content.duration)
            if progress >= 1 {
                completionHold = 0
                if !autoAdvance { isPlaying = false }
            }
            return
        }
        guard autoAdvance else { isPlaying = false; return }
        completionHold += elapsed
        guard completionHold >= 1.25 else { return }
        if let next = step.next { select(next, play: true) }
        else { isPlaying = false }
    }

    func run() async {
        let request = UUID()
        clockID = request
        defer { if clockID == request { clockID = nil } }
        let clock = ContinuousClock()
        var previous = clock.now
        while isPlaying && !Task.isCancelled && clockID == request {
            do { try await Task.sleep(for: .milliseconds(40)) }
            catch { return }
            guard !Task.isCancelled, clockID == request else { return }
            let now = clock.now
            let parts = previous.duration(to: now).components
            previous = now
            let elapsed = Double(parts.seconds) + Double(parts.attoseconds) / 1e18
            advance(by: min(elapsed, 0.15))
        }
    }
}

