import SwiftData
import XCTest
@testable import CellLab

@MainActor
final class CellLabStartupTests: XCTestCase {
    func testBackgroundPreparationMakesLessonsAndProgressReadyTogether() async throws {
        let content = try await CellLabContent.load(inMemory: true)
        XCTAssertNotNil(content.catalog.entry(id: "process.human-nuclear-transcription"))
        XCTAssertFalse(content.catalog.entries.isEmpty)

        // The container created in the background must support the main-thread
        // progress context used by the lesson and game screens.
        let context = content.progressContainer.mainContext
        let progress = ActivityProgress(activityID: "startup-test")
        context.insert(progress)
        try context.save()
        let saved = try context.fetch(FetchDescriptor<ActivityProgress>())
        XCTAssertEqual(saved.map(\.activityID), ["startup-test"])
    }
}
