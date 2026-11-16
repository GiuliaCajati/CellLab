import XCTest

final class MitosisNarrationUITests: XCTestCase {
    @MainActor
    func testListenStopAndLeavingTheOverview() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()

        let mitosis = app.staticTexts["Mitosis"].firstMatch
        XCTAssertTrue(mitosis.waitForExistence(timeout: 5))
        if !mitosis.isHittable { app.swipeUp() }
        mitosis.tap()

        let listen = app.buttons["mitosisListenButton"]
        XCTAssertTrue(listen.waitForExistence(timeout: 5))
        XCTAssertEqual(listen.label, "Listen")
        listen.tap()
        XCTAssertEqual(listen.label, "Stop")
        listen.tap()
        XCTAssertEqual(listen.label, "Listen")

        listen.tap()
        XCTAssertEqual(listen.label, "Stop")
        app.buttons["mitosisPlayButton"].tap()
        XCTAssertTrue(app.buttons["mitosis-parts-hint"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(listen.waitForExistence(timeout: 5))
        XCTAssertEqual(listen.label, "Listen")

        listen.tap()
        XCTAssertEqual(listen.label, "Stop")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(mitosis.waitForExistence(timeout: 5))
        mitosis.tap()
        XCTAssertTrue(listen.waitForExistence(timeout: 5))
        XCTAssertEqual(listen.label, "Listen")
    }
}
