import XCTest

final class CellCycleNarrationUITests: XCTestCase {
    @MainActor
    private func openLesson() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let module = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Cell Life Cycle,")).firstMatch
        XCTAssertTrue(module.waitForExistence(timeout: 8))
        module.tap()
        XCTAssertTrue(app.buttons["cycle-listen"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication,
                        file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<18 {
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
    private func waitForValue(_ element: XCUIElement, containing value: String) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value CONTAINS[cd] %@", value), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
    }

    @MainActor
    private func tapPhase(_ id: String, in app: XCUIApplication) {
        // Ring buttons share the wheel's rectangular frame. Tap inside the
        // selected sector rather than at the empty center of that frame.
        let angle: Double
        switch id {
        case "mitosis": angle = 140
        case "cytokinesis": angle = 195
        case "s": angle = -10
        default: XCTFail("Add a coordinate for \(id)"); return
        }
        let button = app.buttons["cycle-phase-\(id)"]
        reveal(button, in: app)
        let width = button.frame.width
        let radians = angle * .pi / 180
        let x = 0.5 + 0.35 * cos(radians)
        let y = (width * 0.5 + 12 + width * 0.35 * sin(radians)) / button.frame.height
        button.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).tap()
    }

    @MainActor
    func testOverviewStillStartsAfterExploringAndPhaseChangesInterruptSpeech() {
        let app = openLesson()
        let guide = app.buttons["cycle-listen"]
        XCTAssertEqual(guide.value as? String, "Quiet")
        app.buttons["cycle-phase-g0"].tap()
        XCTAssertEqual(guide.label, "Hear cell life cycle overview")
        guide.tap()
        waitForValue(guide, containing: "Opening")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Cell Life Cycle talking axolotl"
        attachment.lifetime = .keepAlways
        add(attachment)
        tapPhase("mitosis", in: app)
        waitForValue(guide, containing: "Prophase")
        let metaphase = app.buttons["cycle-mitosis-metaphase"]
        reveal(metaphase, in: app)
        metaphase.tap()
        waitForValue(guide, containing: "Metaphase")
        reveal(guide, in: app)
        guide.tap()
        XCTAssertEqual(guide.value as? String, "Quiet")
        tapPhase("s", in: app)
        XCTAssertEqual(guide.value as? String, "Quiet")
    }

    @MainActor
    func testCytokinesisComparisonKeyPlayersAndBackgroundStop() {
        let app = openLesson()
        let guide = app.buttons["cycle-listen"]
        guide.tap()
        tapPhase("cytokinesis", in: app)
        waitForValue(guide, containing: "Animal cells")
        let plant = app.buttons["Plant cells"]
        XCTAssertTrue(plant.waitForExistence(timeout: 3), app.debugDescription)
        reveal(plant, in: app)
        plant.tap()
        waitForValue(guide, containing: "Plant cells")
        let players = app.buttons["cycle-meet-key-players"]
        reveal(players, in: app)
        players.tap()
        let sheetGuide = app.buttons["cycle-players-listen"]
        XCTAssertTrue(sheetGuide.waitForExistence(timeout: 3))
        XCTAssertEqual(sheetGuide.value as? String, "Quiet")
        sheetGuide.tap()
        waitForValue(sheetGuide, containing: "p53")
        let next = app.buttons["Next key player"]
        reveal(next, in: app)
        next.tap()
        waitForValue(sheetGuide, containing: "checkpoints")
        XCUIDevice.shared.press(.home)
        app.activate()
        waitForValue(sheetGuide, containing: "Quiet")
        app.buttons["cycle-key-players-done"].tap()
        reveal(guide, in: app)
        XCTAssertEqual(guide.value as? String, "Quiet")
        guide.tap()
        waitForValue(guide, containing: "Plant cells")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Cell Life Cycle,")).firstMatch.waitForExistence(timeout: 3))
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Cell Life Cycle,")).firstMatch.tap()
        XCTAssertEqual(app.buttons["cycle-listen"].value as? String, "Quiet")
    }
}
