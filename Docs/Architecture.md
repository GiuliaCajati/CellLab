# Architecture

The biology catalog is bundled JSON for learner-facing explanations, stable entry IDs, related-entry links, source metadata, and claim-level evidence. `BiologyCatalog` decodes and validates it; SwiftUI displays entries and the reusable Sources & accuracy sheet. Educational prose lives in the catalog, not in views.

The bundled transcription activity JSON defines a synthetic DNA template and playable excerpt. Plain Foundation types in `CellLab/Transcription` validate definitions and implement deterministic precursor matching, RNA extension, and typed events. The current scope supports only template data stored 3′ → 5′ and rejects other orientations instead of reversing sequence data implicitly.

The session is separate from presentation: no SwiftUI, SpriteKit, or SwiftData is imported by the transcription rules. UI animation and collision handling can later observe session events but cannot decide whether a base matches. SwiftData remains the existing progress store; this milestone does not save activity completion.
