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

    private(set) var feedback = "Starting to pack up."

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

    var facts: [String] {

        switch stage {

        case .prophase:

            [

                "Chromatin (DNA wrapped around histone proteins) condenses into visible chromosomes.",

                "The nucleolus disappears, and the mitotic spindle begins to form.",

                "In animal cells, the centrosomes move toward opposite sides of the cell. Each centrosome contains a pair of centrioles."

            ]

        case .prometaphase:

            [

                "The nuclear envelope breaks down, allowing spindle microtubules to reach the chromosomes.",

                "Kinetochores, protein structures located at the centromere region, form attachment sites for spindle microtubules.",

                "Microtubules attach to the kinetochores of each sister chromatid, connecting the chromosome to opposite spindle poles.",

                "The chromosomes begin moving toward the middle of the cell."

            ]

        case .metaphase:

            [

                "Replicated chromosomes line up along the middle of the cell, called the metaphase plate.",

                "Sister chromatids are still joined at their centromeres.",

                "Each sister chromatid should be attached to spindle microtubules from an opposite pole.",

                "The spindle assembly checkpoint helps prevent separation until all chromosomes are properly attached."

            ]

        case .anaphase:

            [

                "The centromeres separate, allowing sister chromatids to split apart.",

                "Once separated, each former chromatid is considered an individual chromosome.",

                "Kinetochore microtubules shorten, pulling chromosomes toward opposite poles.",

                "Non-kinetochore microtubules help push the spindle poles farther apart.",

                "In this model, four replicated chromosomes become eight individual chromosomes, with four moving toward each pole."

            ]

        case .telophase:

            [

                "Chromosomes arrive at opposite poles of the cell.",

                "New nuclear envelopes form around each set of chromosomes.",

                "The nucleoli reappear inside the newly forming nuclei.",

                "Chromosomes loosen and return to their less-condensed chromatin form.",

                "The mitotic spindle disassembles.",

                "Two nuclei now contain matching sets of chromosomes."

            ]

        case .complete:

            [

                "Mitosis is complete: one nucleus has divided into two genetically matching nuclei.",

                "Cytokinesis is the separate process that divides the cytoplasm and separates the cell into two daughter cells.",

                "Cytokinesis often overlaps with late mitosis, but it is not animated in this model.",

                "The cell outline remains intact here to help distinguish nuclear division (mitosis) from cytoplasmic division (cytokinesis)."

            ]

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

// Short phase-completion lessons; longer definitions remain in \`fact\`.

extension MitosisSession.Stage {

    var lessonExplanation: String {

        switch self {

        case .prophase:

            [

                "✅ Chromatin condenses into compact, visible chromosomes.",

                "✅ The nucleolus disappears, and the mitotic spindle begins to form.",

                "✅In animal cells, the centrosomes move toward opposite sides of the cell. Each contains a pair of centrioles."

            ].joined(separator: "\n\n")

        case .prometaphase:

            [

                "✅ The nuclear envelope breaks down, allowing spindle microtubules to reach the chromosomes.",

                "✅ Kinetochores, protein structures at the centromere region, provide attachment sites for spindle microtubules.",

                "✅ Each sister chromatid's kinetochore attaches to microtubules oriented toward an opposite spindle pole. The gold dots in the scene represent these kinetochore attachment sites."

            ].joined(separator: "\n\n")

        case .metaphase:

            [

                "✅ Replicated chromosomes line up across the middle of the cell, called the metaphase plate.",

                "✅ Sister chromatids remain joined at their centromeres.",

                "✅ Each sister chromatid should be attached to microtubules from an opposite spindle pole.",

                "✅ The spindle assembly checkpoint helps prevent anaphase until all chromosomes are properly attached."

            ].joined(separator: "\n\n")

        case .anaphase:

            [

                "✅Sister chromatids separate and are now considered individual chromosomes.",

                "✅ Kinetochore microtubules shorten, pulling the chromosomes toward opposite poles.",

                "✅ Other spindle microtubules help push the two poles farther apart.",

                "✅ In this model, four replicated chromosomes become eight individual chromosomes, with four moving toward each pole.",

                "✅ No additional DNA is copied during anaphase."

            ].joined(separator: "\n\n")

        case .telophase:

            [

                "✅ Chromosomes reach opposite poles of the cell.",

                "✅ New nuclear envelopes form around each set of chromosomes.",

                "✅ The nucleoli reappear inside the new nuclei.",

                "✅ Chromosomes decondense, returning to their less compact chromatin form.",

                "✅ The mitotic spindle disassembles.",

                "✅ Two nuclei now contain matching sets of chromosomes."

            ].joined(separator: "\n\n")

        case .complete:

            [

                "✅ Mitosis is complete! One nucleus has divided into two genetically matching nuclei.",

                "✅ Cytokinesis is the separate process that divides the cytoplasm to produce two daughter cells.",

                "✅ Cytokinesis often overlaps with late mitosis, but it is not included in this game.",

                "✅ The cell outline stays whole in this model to make the distinction between nuclear division and cytoplasmic division clear."

            ].joined(separator: "\n\n")

        }

    }

    var lessonTakeaway: String {

        switch self {

        case .prophase: "DNA was copied during S phase. Each chromosome now consists of two identical sister chromatids joined at the centromere."

        case .prometaphase: "Spindle fibers attach at kinetochores."

        case .metaphase: "Aligned + attached → ready to separate."

        case .anaphase: "Sister chromatids → individual chromosomes."

        case .telophase: "Two nuclei. Matching chromosome sets."

        case .complete: "Mitosis divides the nucleus."

        }

    }

}
