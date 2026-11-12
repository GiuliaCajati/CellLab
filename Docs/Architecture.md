# Architecture

The biology catalog is bundled JSON for learner-facing explanations, stable entry IDs, related-entry links, source metadata, and claim-level evidence. `BiologyCatalog` decodes and validates it; SwiftUI displays entries and the reusable Sources & accuracy sheet. Educational prose lives in the catalog, not in views.

The bundled transcription activity JSON defines one synthetic DNA template, promoter, transcription start, manual-match ranges, cap boundary, intron, polyadenylation signal, and cleavage position. Plain Swift types in `CellLab/Transcription` validate the annotations and own initiation, RNA synthesis, processing, termination, and export state. The template is stored 3′ → 5′; other orientations are rejected instead of reversed implicitly.

The session is separate from presentation: no SwiftUI, SpriteKit, or SwiftData is imported by the transcription rules. A retained observable game model owns the session and the single SpriteKit scene; the scene reports input to the model, and session events drive rendering and animation. SpriteKit hit testing never decides whether a base matches. SwiftUI provides the compact journey header, instruction, information sheet, and accessible controls. SwiftData remains the existing progress store; this journey does not save full lesson completion.
