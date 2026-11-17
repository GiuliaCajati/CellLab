import XCTest

final class CellStructuresNarrationUITests: XCTestCase {
    @MainActor
    private func openLesson() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let module = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Cell Structures,")).firstMatch
        XCTAssertTrue(module.waitForExistence(timeout: 8))
        module.tap()
        XCTAssertTrue(app.buttons["structures-listen"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication,
                        file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<30 {
            if element.isHittable, element.frame.midY > 110, element.frame.midY < app.frame.maxY - 70 { return }
            let below = !element.exists || element.frame.midY > app.frame.midY
            let distance = element.exists
                ? min(max(abs(element.frame.midY - app.frame.midY), 70), app.frame.height * 0.5)
                : app.frame.height * 0.5
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: below ? 0.76 : 0.24))
            start.press(forDuration: 0.01, thenDragTo: start.withOffset(CGVector(dx: 0, dy: below ? -distance : distance)),
                        withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        XCTAssertTrue(element.isHittable, file: file, line: line)
    }

    @MainActor
    private func waitFor(_ element: XCUIElement, _ predicate: String, _ value: String) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: predicate, value), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testAxolotlExplainsSelectedStructuresAndStopsWhenAsked() {
        let app = openLesson()
        let axolotl = app.buttons["structures-listen"]
        XCTAssertEqual(axolotl.value as? String, "Quiet")
        axolotl.tap()
        waitFor(axolotl, "value CONTAINS[cd] %@", "Opening")
        let nucleolus = app.buttons["structure-chip-nucleolus"]
        reveal(nucleolus, in: app)
        nucleolus.tap()
        waitFor(axolotl, "value CONTAINS[cd] %@", "Nucleolus")
        reveal(axolotl, in: app)
        capture(app, "Talking axolotl above the cell image")
        axolotl.tap()
        XCTAssertEqual(axolotl.value as? String, "Quiet")
        let nucleus = app.buttons["structure-chip-nucleus"]
        reveal(nucleus, in: app)
        nucleus.tap()
        XCTAssertEqual(axolotl.value as? String, "Quiet")
    }

    @MainActor
    func testCardAndLookCloserSpeakersBrowserSelectionAndBackgroundStop() {
        let app = openLesson()
        let summary = app.buttons["narration-structure.nucleus"]
        reveal(summary, in: app)
        summary.tap()
        waitFor(summary, "label == %@", "Stop Nucleus narration")
        summary.tap()
        let closer = app.buttons["Look closer"]
        reveal(closer, in: app)
        closer.tap()
        let detail = app.buttons["narration-detail.nucleus"]
        reveal(detail, in: app)
        detail.tap()
        waitFor(detail, "label == %@", "Stop more about Nucleus narration")
        capture(app, "Optional Look closer details have their own recording")
        detail.tap()
        let browse = app.buttons["structures-browse"]
        reveal(browse, in: app)
        browse.tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 3))
        search.tap()
        search.typeText("mitochondria")
        app.buttons["structure-browser-mitochondria"].tap()
        let mitochondria = app.buttons["narration-structure.mitochondria"]
        XCTAssertTrue(mitochondria.waitForExistence(timeout: 3))
        reveal(mitochondria, in: app)
        mitochondria.tap()
        waitFor(mitochondria, "label == %@", "Stop Mitochondria narration")
        XCUIDevice.shared.press(.home)
        app.activate()
        waitFor(mitochondria, "label == %@", "Hear Mitochondria")
    }
}
