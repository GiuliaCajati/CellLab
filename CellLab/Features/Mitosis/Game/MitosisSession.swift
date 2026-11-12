//
//  MitosisSession.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/12/26.
//
import Foundation

/// Animal-cell mitosis only. Four chromosomes make individual copies traceable.
/// Biology adapted from the user's supplied McGraw-Hill notes.
nonisolated struct MitosisSession {
    enum Pole: String, CaseIterable, Identifiable {
        case left = "Left", right = "Right"
        var id: Self { self }
    }
    enum Stage: Int, CaseIterable, Identifiable {
        case prophase, prometaphase, metaphase, anaphase, telophase, complete
        var id: Self { self }
        var title: String {
            switch self {
            case .prophase: "Prophase"
            case .prometaphase: "Prometaphase"
            case .metaphase: "Metaphase"
            case .anaphase: "Anaphase"
            case .telophase: "Telophase"
            case .complete: "Mitosis complete"
            }
        }
        var mission: String {
            switch self {
            case .prophase: "Pack the DNA."
            case .prometaphase: "Make connections."
            case .metaphase: "Center stage!"
            case .anaphase: "Sisters, separate!"
            case .telophase: "Build two nuclei."
            case .complete: "One cell. Two nuclei."
            }
        }
    }
    enum Action {
        case condense(Int), movePole(Pole), openEnvelope, choosePole(Pole)
        case attach(Int), align(Int, nearEquator: Bool), inspectCheckpoint
        case separate, rebuildNucleus(Pole), advance, restart
    }

    static let chromosomeIDs = Array(0..<4)
    private(set) var stage: Stage = .prophase
    private(set) var condensed: Set<Int> = []
    private(set) var movedPoles: Set<Pole> = []
    private(set) var envelopeOpen = false
    private(set) var selectedPole: Pole = .left
    private(set) var leftAttachments: Set<Int> = []
    private(set) var rightAttachments: Set<Int> = []
    private(set) var aligned: Set<Int> = []
    private(set) var checkpointPassed = false
    private(set) var separated = false
    private(set) var rebuiltNuclei: Set<Pole> = []
    private(set) var feedback = "DNA was copied in S phase. Now divide the nucleus."
    private(set) var needsCorrection = false

    var attachmentsComplete: Bool { leftAttachments.count == 4 && rightAttachments.count == 4 }
    var canAdvance: Bool {
        switch stage {
        case .prophase: condensed.count == 4 && movedPoles.count == 2
        case .prometaphase: envelopeOpen && attachmentsComplete
        case .metaphase: attachmentsComplete && aligned.count == 4 && checkpointPassed
        case .anaphase: separated
        case .telophase: rebuiltNuclei.count == 2
        case .complete: false
        }
    }
    var instruction: String {
        switch stage {
        case .prophase:
            condensed.count < 4 ? "Tap each DNA bundle to pack it." : "Tap both centrosomes to move them apart."
        case .prometaphase:
            !envelopeOpen ? "Open the nuclear envelope." : "Choose a pole. Tap chromosomes to connect."
        case .metaphase:
            aligned.count < 4 ? "Drag to the center line—or tap to align." : "Run the checkpoint."
        case .anaphase:
            !separated ? "Release the sisters. Watch them travel." : "Each sister is now a chromosome."
        case .telophase: "Tap each group to rebuild its nucleus."
        case .complete: "Matching DNA sets, inside two new nuclei."
        }
    }
    var progressLabel: String {
        switch stage {
        case .prophase: condensed.count < 4 ? "\(condensed.count)/4 packed" : "\(movedPoles.count)/2 centrosomes positioned"
        case .prometaphase: "\(leftAttachments.count + rightAttachments.count)/8 kinetochore connections"
        case .metaphase: checkpointPassed ? "Checkpoint passed" : "\(aligned.count)/4 aligned"
        case .anaphase: separated ? "4 chromosomes moving to each pole" : "4 replicated chromosomes"
        case .telophase: "\(rebuiltNuclei.count)/2 nuclei rebuilt"
        case .complete: "4 chromosomes per nucleus"
        }
    }
    var fact: String {
        switch stage {
        case .prophase:
            "DNA was already copied during S phase. Each replicated chromosome has two sister chromatids. Chromatin, already associated with histones, condenses; the nucleolus disappears and the spindle begins forming. Each animal centrosome contains a pair of centrioles."
        case .prometaphase:
            "The nuclear envelope fragments. Spindle microtubules attach to kinetochores, protein complexes at the centromeres. The two sisters attach toward opposite poles. Gold dots in the scene mark these attachment sites."
        case .metaphase:
            "Replicated chromosomes align at the cell's equator. The checkpoint prevents premature separation. This guided game verifies opposite-pole attachments and alignment before allowing anaphase."
        case .anaphase:
            "Sister chromatids separate and each becomes an individual chromosome. Kinetochore microtubules shorten to draw them toward opposite poles. Non-kinetochore microtubules help push the poles apart. Four replicated chromosomes become eight individual chromosomes, with four going toward each pole."
        case .telophase:
            "Nuclear envelopes and nucleoli re-form around each set. Chromosomes decondense into chromatin, and the spindle disassembles. The two nuclei contain matching chromosome sets."
        case .complete:
            "Mitosis is nuclear division. Cytokinesis divides the cytoplasm and is a separate process, not played here. It can overlap late mitosis; the cell outline stays whole in this simplified model so the two processes remain distinct."
        }
    }

    mutating func send(_ action: Action) {
        needsCorrection = false
        switch action {
        case .condense(let id):
            guard stage == .prophase, Self.chromosomeIDs.contains(id) else { return }
            condensed.insert(id)
            respond(condensed.count == 4 ? "Packed. Now position the centrosomes." : "Same DNA. Smaller suitcase.")
        case .movePole(let pole):
            guard stage == .prophase, condensed.count == 4 else { return }
            movedPoles.insert(pole)
            respond(movedPoles.count == 2 ? "Opposite poles. Spindle forming!" : "One pole ready. One to go.")
        case .openEnvelope:
            guard stage == .prometaphase else { return }
            envelopeOpen = true
            respond("Way cleared. Connect the gold kinetochores.")
        case .choosePole(let pole):
            guard stage == .prometaphase, envelopeOpen else { return }
            selectedPole = pole
            respond("\(pole.rawValue) pole selected.")
        case .attach(let id):
            guard stage == .prometaphase, envelopeOpen, Self.chromosomeIDs.contains(id) else { return }
            if selectedPole == .left { leftAttachments.insert(id) }
            else { rightAttachments.insert(id) }
            if attachmentsComplete { respond("Both sisters connected. Opposite destinations!") }
            else if (selectedPole == .left ? leftAttachments : rightAttachments).count == 4 {
                respond("This side is ready. Select the other pole.")
            } else { respond("Kinetochore connected!") }
        case .align(let id, let nearEquator):
            guard stage == .metaphase, Self.chromosomeIDs.contains(id) else { return }
            guard nearEquator else {
                respond("Aim for the dashed line—or tap to align.", correction: true)
                return
            }
            aligned.insert(id)
            respond(aligned.count == 4 ? "Great lineup. Ready for inspection." : "Center stage. Sisters stay together!")
        case .inspectCheckpoint:
            guard stage == .metaphase else { return }
            guard attachmentsComplete && aligned.count == 4 else {
                respond("Not yet. Every chromosome needs to be connected and aligned.", correction: true)
                return
            }
            checkpointPassed = true
            respond("All connected. All aligned. Cleared to separate!")
        case .separate:
            guard stage == .anaphase, checkpointPassed, attachmentsComplete else { return }
            separated = true
            respond("Sisters apart. Each is now a chromosome!")
        case .rebuildNucleus(let pole):
            guard stage == .telophase, separated else { return }
            rebuiltNuclei.insert(pole)
            respond(rebuiltNuclei.count == 2 ? "Two nuclei. DNA unpacked. Mitosis complete!" : "One nucleus rebuilt. One to go.")
        case .advance:
            guard canAdvance, let next = Stage(rawValue: stage.rawValue + 1) else { return }
            stage = next
            respond(instruction)
        case .restart: self = Self()
        }
    }
    private mutating func respond(_ text: String, correction: Bool = false) {
        feedback = text
        needsCorrection = correction
    }
}

// Short phase-completion lessons; longer definitions remain in `fact`.
extension MitosisSession.Stage {
    var lessonJoke: String {
        switch self {
        case .prophase: "Packing for a very short trip."
        case .prometaphase: "The nucleus has opened its doors."
        case .metaphase: "Everyone made the group photo."
        case .anaphase: "Identical DNA. Separate travel plans."
        case .telophase: "Two nuclei. Both unpacked."
        case .complete: "Same DNA. Two nuclear addresses."
        }
    }
    var lessonExplanation: String {
        switch self {
        case .prophase:
            "Loose chromatin condensed into compact, replicated chromosomes. Each still has two sister chromatids. The centrosomes moved apart, and the spindle began forming."
        case .prometaphase:
            "The nuclear envelope fragmented, giving spindle fibers access to the chromosomes. You connected each sister's kinetochore to a different pole. Those gold dots are the attachment sites."
        case .metaphase:
            "The replicated chromosomes lined up at the equator. Your checkpoint confirmed they were aligned and attached to opposite poles. The sisters are still together—for now."
        case .anaphase:
            "Sister chromatids separated. Each is now an individual chromosome. The spindle moved four toward each pole. No extra DNA was copied during this step."
        case .telophase:
            "New nuclear envelopes formed around matching chromosome sets. The chromosomes loosened into chromatin, nucleoli re-formed, and the spindle disassembled. You have completed nuclear division!"
        case .complete:
            "You made two nuclei with matching chromosome sets. Cytokinesis divides the cytoplasm; that separate process is outside this game. The cell stays whole here to keep the distinction clear."
        }
    }
    var lessonTakeaway: String {
        switch self {
        case .prophase: "Same DNA. More compact packaging."
        case .prometaphase: "Spindle fibers attach at kinetochores."
        case .metaphase: "Aligned + attached → ready to separate."
        case .anaphase: "Sister chromatids → individual chromosomes."
        case .telophase: "Two nuclei. Matching chromosome sets."
        case .complete: "Mitosis divides the nucleus."
        }
    }
}
