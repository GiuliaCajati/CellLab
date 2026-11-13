// DNAReplicationSession.swift — one deterministic clock, shared by the page and enlarged diagram.
import Foundation
import Observation

@MainActor @Observable final class DNAReplicationSession {
    var step: DNAReplicationStep = .prime
    var progress: Double = 1
    var isPlaying = false
    var autoAdvance = false

    func select(_ newStep: DNAReplicationStep, play: Bool) {
        step = newStep
        progress = play ? 0 : 1
        isPlaying = play
    }

    func replay(play: Bool) {
        progress = play ? 0 : 1
        isPlaying = play
    }

    func togglePlayback() {
        if progress >= 1 { progress = 0 }
        isPlaying.toggle()
    }

    func advance(by seconds: Double) {
        guard isPlaying else { return }
        progress = min(1, progress + max(0, seconds) / step.content.duration)
        guard progress >= 1 else { return }
        if autoAdvance, let next = step.next {
            step = next
            progress = 0
        } else {
            isPlaying = false
        }
    }

    func run() async {
        let clock = ContinuousClock()
        var previous = clock.now
        while isPlaying && !Task.isCancelled {
            do { try await Task.sleep(for: .milliseconds(40)) }
            catch { return }
            guard !Task.isCancelled else { return }
            let now = clock.now
            let parts = previous.duration(to: now).components
            previous = now
            let elapsed = Double(parts.seconds) + Double(parts.attoseconds) / 1e18
            advance(by: min(elapsed, 0.15))
        }
    }
}

// Biological state is independent of drawing, so every nucleotide can be checked.
enum DNAReplicationDiagram {
    static let sequence = Array("ACGTATGCCGTA").map(String.init)
    static func complement(_ base: String) -> String {
        switch base {
        case "A": return "T"
        case "T", "U": return "A"
        case "C": return "G"
        case "G": return "C"
        default: return "?"
        }
    }
    static func rnaComplement(_ base: String) -> String {
        let result = complement(base)
        return result == "T" ? "U" : result
    }
    static func isPrimer(leading: Bool, index: Int) -> Bool {
        leading ? index >= 10 : index % 4 < 2
    }
    static func visible(leading: Bool, index: Int, step: DNAReplicationStep, progress: Double) -> Bool {
        let p = min(max(progress, 0), 1)
        if step.rawValue < DNAReplicationStep.prime.rawValue { return false }
        if step == .prime {
            guard isPrimer(leading: leading, index: index) else { return false }
            return leading ? p >= 0.12 : p >= [0.82, 0.57, 0.32][index / 4]
        }
        if step == .build {
            if isPrimer(leading: leading, index: index) { return true }
            if leading { return index >= 10 - Int(floor(p * 10 + 1e-8)) }
            let rank = 2 - index / 4
            let local = min(max(p * 3 - Double(rank), 0), 1)
            return index % 4 - 2 < Int(floor(local * 2 + 1e-8))
        }
        return true
    }
}
