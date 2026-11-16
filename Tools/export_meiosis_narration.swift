import Foundation

/// Run against the actual game model, not a second copy of its instruction strings.
/// Compiled by generate_meiosis_audio.py; this file is outside the iOS target.
@main
struct ExportMeiosisNarration {
    struct Cue: Codable, Equatable {
        let id: String
        let title: String
        let text: String
    }

    static func main() throws {
        var session = MeiosisSession(maternalLeft: [true, false])
        var cues: [Cue] = []
        func collect() {
            let cue: Cue
            if session.canAdvance {
                let popup = MeiosisPopup.completed(session)
                let text = popup.explanation.replacingOccurrences(of: "✅ ", with: "")
                    + (popup.showsTakeaway ? "\n\n" + popup.takeaway : "")
                cue = Cue(id: session.completionNarrationID, title: popup.title, text: text)
            } else {
                let text = session.instruction + (session.stage == .complete ? "\n\n" + session.facts.prefix(2).joined(separator: " ") : "")
                cue = Cue(id: session.instructionNarrationID, title: session.stage.title + " · Instruction", text: text)
            }
            if let existing = cues.first(where: { $0.id == cue.id }) {
                precondition(existing == cue, "A cue ID must always describe the same instruction")
            } else { cues.append(cue) }
        }
        func send(_ action: MeiosisSession.Action) {
            session.send(action)
            precondition(!session.needsCorrection, "The sample walk must follow valid actions")
            collect()
        }
        func advance() {
            precondition(session.canAdvance, "Incomplete \(session.stage.title): \(session.instruction)")
            send(.advance)
        }
        precondition(session.stage == .prophaseI && session.replicated && session.divisionPrepared)
        collect()
        for id in 0..<4 { send(.condenseI(id)) }
        send(.openEnvelopeI)
        for pair in 0..<2 { send(.synapse(pair, matched: true)) }
        for pair in 0..<2 { send(.crossOver(pair, matched: true)) }
        advance()
        for id in 0..<4 { send(.choosePole(session.poleForHomolog(id))); send(.attachI(id)) }
        for pair in 0..<2 { send(.alignI(pair, nearEquator: true)) }
        send(.inspectI); advance()
        send(.protectCentromeres); send(.separateHomologs); advance()
        for cell in 0..<2 { send(.rebuildI(cell)) }
        send(.divideI); advance()
        send(.blockReplication); send(.makeInterkinesisProteins); advance()
        for id in 0..<4 { send(.condenseII(id)) }
        for cell in 0..<2 { send(.openEnvelopeII(cell)) }
        advance()
        for pole in [MeiosisSession.Pole.top, .bottom] {
            send(.choosePole(pole))
            for id in 0..<4 { send(.attachII(id)) }
        }
        for id in 0..<4 { send(.alignII(id, nearEquator: true)) }
        send(.inspectII); advance()
        send(.splitCentromeres); send(.separateSisters); advance()
        for product in 0..<4 { send(.rebuildII(product)) }
        send(.relaxChromosomes); send(.divideII); advance()
        precondition(session.stage == .complete && cues.count == 33)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        FileHandle.standardOutput.write(try encoder.encode(cues))
    }
}
