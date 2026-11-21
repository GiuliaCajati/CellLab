import XCTest

final class DailyBiologyFactsUITests: XCTestCase {
    @MainActor private func app() -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        return XCUIApplication()
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
    }

    @MainActor func testFactStaysInsideSettingsWithoutOpeningAnotherPage() {
        let app = app()
        app.launch()
        XCTAssertTrue(app.buttons["celllab-settings"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["today-fact-entry"].exists)
        capture(app, "Uncluttered CellLab home with a small Settings gear")
        app.buttons["celllab-settings"].tap()
        let today = app.buttons["today-fact-entry"]
        XCTAssertTrue(today.waitForExistence(timeout: 5))
        capture(app, "Today’s Fact tucked inside Settings")
        today.tap()
        let title = app.staticTexts["daily-fact-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["daily-fact-detail"].exists)
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "daily-fact-source-0").firstMatch.exists)
        capture(app, "Fact and sources expand inside Settings")
        today.tap()
        let toggle = app.switches["daily-fact-reminder-toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual(toggle.value as? String, "0")
        capture(app, "Daily fact reminder defaults off")
    }

    @MainActor func testWidgetAndCachedFactLinksOpenCellLabHome() {
        let app = app()
        for url in ["celllab://home", "celllab://fact/fact-001", "celllab://fact/fact-069"] {
            app.terminate()
            app.open(URL(string: url)!)
            XCTAssertTrue(app.buttons["celllab-settings"].waitForExistence(timeout: 12))
            XCTAssertTrue(app.buttons["home-lesson-structures"].exists)
            XCTAssertFalse(app.staticTexts["daily-fact-title"].exists)
            XCTAssertFalse(app.buttons["today-fact-entry"].exists)
        }
        capture(app, "Widget opens the main CellLab screen")
        app.buttons["celllab-settings"].tap()
        XCTAssertTrue(app.switches["daily-fact-reminder-toggle"].waitForExistence(timeout: 5))
        app.open(URL(string: "celllab://home")!)
        XCTAssertTrue(app.buttons["celllab-settings"].waitForExistence(timeout: 12))
        XCTAssertFalse(app.switches["daily-fact-reminder-toggle"].exists)
    }

    @MainActor func testReminderDenialOffersSettingsAndKeepsSwitchOff() {
        let app = app()
        app.launch()
        XCTAssertTrue(app.buttons["celllab-settings"].waitForExistence(timeout: 10))
        app.buttons["celllab-settings"].tap()
        let toggle = app.switches["daily-fact-reminder-toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual(toggle.value as? String, "0")
        let monitor = addUIInterruptionMonitor(withDescription: "Notification permission") { alert in
            let deny = alert.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Don")).firstMatch
            guard deny.exists else { return false }
            deny.tap()
            return true
        }
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        app.tap() // Allow XCTest to handle the system permission alert.
        let settings = app.buttons["daily-fact-open-settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 8))
        XCTAssertEqual(toggle.value as? String, "0")
        capture(app, "Denied permission leaves reminder off with Open Settings")
        removeUIInterruptionMonitor(monitor)
    }
}
