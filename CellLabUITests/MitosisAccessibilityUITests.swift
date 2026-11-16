import XCTest

final class MitosisAccessibilityUITests: XCTestCase {
    @MainActor
    private func lesson() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let entry = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Mitosis,")).firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 8))
        if !entry.isHittable { app.swipeUp() }
        entry.tap()
        XCTAssertTrue(app.buttons["mitosisListenButton"].waitForExistence(timeout: 5))
        return app
    }
    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
    }
    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, upward: Bool = true) {
        for _ in 0..<8 where !element.isHittable {
            if upward { app.swipeUp() } else { app.swipeDown() }
        }
        XCTAssertTrue(element.isHittable)
    }

    @MainActor
    func testGuideKeepsItsHeightAtCurrentTextSize() {
        let app = lesson()
        attach(app, "Small iPhone header at largest text size")
        let game = app.buttons["mitosisPlayButton"]
        XCTAssertLessThanOrEqual(game.frame.maxX, app.frame.maxX)
        let guide = app.buttons["mitosisListenButton"]
        reveal(guide, in: app)
        let height = guide.frame.height
        XCTAssertGreaterThanOrEqual(height, 44)
        XCTAssertLessThanOrEqual(guide.frame.maxX, app.frame.maxX)
        guide.tap()
        XCTAssertEqual(guide.label, "Stop narration")
        XCTAssertEqual(guide.frame.height, height, accuracy: 1)
        attach(app, "Large text with Reduce Motion during narration")
        guide.tap()
        XCTAssertEqual(guide.value as? String, "Quiet")
    }

    @MainActor
    func testLargeTextGameKeepsTheSceneAndToolsUsable() {
        let app = lesson()
        let play = app.buttons["mitosisPlayButton"]
        reveal(play, in: app)
        play.tap()
        let scene = app.otherElements["mitosis-playfield"].firstMatch
        XCTAssertTrue(scene.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(scene.frame.height, 250)
        let guide = app.buttons["mitosisGameListenButton"]
        reveal(guide, in: app)
        guide.tap()
        XCTAssertEqual(guide.label, "Stop narration")
        attach(app, "Game instruction area at largest text size")
        XCUIDevice.shared.press(.home)
        app.activate()
        let quiet = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Quiet"), object: guide)
        XCTAssertEqual(XCTWaiter.wait(for: [quiet], timeout: 4), .completed)
        let chromosome = app.buttons["Condense chromosome 1"]
        reveal(chromosome, in: app, upward: false)
        chromosome.tap()
        XCTAssertFalse(chromosome.exists)
    }
}
