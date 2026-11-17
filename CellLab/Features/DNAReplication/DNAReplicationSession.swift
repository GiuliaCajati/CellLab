// DNAReplicationSession.swift — one deterministic clock, shared by the page and enlarged diagram.
import Foundation
import Observation

@MainActor @Observable final class DNAReplicationSession {
    // Match LessonNarrator's workaround for the iOS 26.2 isolated-deinit crash.
    nonisolated deinit {}
    @ObservationIgnored private var clockID: UUID?
    var step: DNAReplicationStep = .origins
    var progress: Double = 0
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
        // Sheet dismissal can briefly overlap view lifetimes. The newest owner
        // takes the clock, and an older task must never advance this session.
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

/// Shared fork geometry keeps helicase, base separation, and continuous
/// parental backbones together in the lesson and the interactive game.
nonisolated struct DNAUnzipGeometry {
    let progress: Double
    var closedLeft: CGFloat = 156
    var closedRight: CGFloat = 204
    var openLeft: CGFloat = 75
    var openRight: CGFloat = 285
    var startY: CGFloat = 350
    var endY: CGFloat = 110
    var spread: CGFloat = 72

    private func smooth(_ value: CGFloat) -> CGFloat {
        let p = min(max(value, 0), 1)
        return p * p * (3 - 2 * p)
    }

    var forkY: CGFloat { startY + (endY - startY) * smooth(CGFloat(progress)) }
    var helicase: CGPoint { CGPoint(x: (closedLeft + closedRight) / 2, y: forkY + 12) }

    func separation(at y: CGFloat) -> CGFloat { smooth((y - forkY) / spread) }

    func strandX(left: Bool, at y: CGFloat) -> CGFloat {
        let closed = left ? closedLeft : closedRight
        let open = left ? openLeft : openRight
        return closed + (open - closed) * separation(at: y)
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
