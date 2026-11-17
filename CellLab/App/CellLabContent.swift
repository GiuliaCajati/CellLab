import Foundation
import SwiftData

/// Resources that must be ready before any lesson or game opens.
nonisolated struct CellLabContent: Sendable {
    let catalog: BiologyCatalog
    let progressContainer: ModelContainer

    // Both bundle decoding and opening saved progress can block. Run them away
    // from the main actor so the loading view can render and animate throughout.
    @concurrent
    static func load(inMemory: Bool = false) async throws -> CellLabContent {
        try Task.checkCancellation()
        let catalog = try BiologyCatalog.load()
        guard catalog.entry(id: "process.human-nuclear-transcription") != nil else {
            throw CatalogError.invalid("Missing transcription entry")
        }

        let schema = Schema(versionedSchema: PlayerDataV1.self)
        let configuration = ModelConfiguration(
            "CellLabProgress",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            groupContainer: .none,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        try Task.checkCancellation()
        return CellLabContent(catalog: catalog, progressContainer: container)
    }
}
