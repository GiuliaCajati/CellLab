import XCTest

final class MitosisNarrationUITests: XCTestCase {
    @MainActor
    private func openLesson() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let module = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Mitosis,")).firstMatch
        XCTAssertTrue(module.waitForExistence(timeout: 8))
        if !module.isHittable { app.swipeUp() }
        module.tap()
        XCTAssertTrue(app.buttons["mitosisListenButton"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    private func waitFor(_ element: XCUIElement, _ predicate: String, _ value: String, timeout: TimeInterval = 6,
                         file: StaticString = #filePath, line: UInt = #line) {
        let expected = XCTNSPredicateExpectation(predicate: NSPredicate(format: predicate, value), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expected], timeout: timeout), .completed, file: file, line: line)
    }

    @MainActor
    private func speaking(_ guide: XCUIElement, _ title: String, timeout: TimeInterval = 6,
                          file: StaticString = #filePath, line: UInt = #line) {
        waitFor(guide, "value CONTAINS[cd] %@", title, timeout: timeout, file: file, line: line)
    }

    @MainActor
    private func screenshot(_ app: XCUIApplication, _ name: String) {
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
    }

    @MainActor
    func testAxolotlRowSpacingAndPositionStayFixedWhenSwiping() {
        let app = openLesson()
        let guide = app.buttons["mitosisListenButton"]
        let title = app.staticTexts["Mitosis"].firstMatch
        let subtitle = app.staticTexts["One nucleus → two nuclei"]
        let game = app.buttons["mitosisPlayButton"]
        let card = app.collectionViews["mitosis-phase-carousel"].firstMatch

        XCTAssertEqual(guide.frame.height, 48, accuracy: 1)
        XCTAssertEqual(guide.frame.minX, card.frame.minX + 2, accuracy: 1)
        XCTAssertEqual(guide.frame.minY - subtitle.frame.maxY, 8, accuracy: 1)
        XCTAssertEqual(card.frame.minY - guide.frame.maxY, 10, accuracy: 1)
        XCTAssertGreaterThan(game.frame.minX, title.frame.maxX)
        XCTAssertLessThan(game.frame.minY, subtitle.frame.minY)
        screenshot(app, "48 point axolotl row above the phase card")

        let position = guide.frame.origin
        // Tap the open space at the right of the primary row, beyond the label.
        guide.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        speaking(guide, "Opening")
        card.swipeLeft()
        speaking(guide, "2 · Prometaphase")
        XCTAssertEqual(guide.frame.minX, position.x, accuracy: 1)
        XCTAssertEqual(guide.frame.minY, position.y, accuracy: 1)
        XCTAssertEqual(guide.frame.height, 48, accuracy: 1)
        screenshot(app, "Axolotl stays still while the card changes")
        guide.tap()
    }

    @MainActor
    func testOverviewFlowsIntoProphaseAndWaitsForTheLearner() {
        let app = openLesson()
        let guide = app.buttons["mitosisListenButton"]
        XCTAssertEqual(guide.label, "Hear mitosis overview")
        XCTAssertEqual(app.buttons["mitosisPlayButton"].label, "Play game")
        screenshot(app, "Stationary guide above Prophase")
        guide.tap()
        speaking(guide, "Opening")
        // Exercise the real full overview and the 350 ms handoff, using bundled audio.
        speaking(guide, "1 · Prophase", timeout: 46)
        waitFor(guide, "label == %@", "Replay Prophase", timeout: 20)
        XCTAssertTrue(app.buttons["mitosisListenButton-stop"].exists)
        app.buttons["mitosisListenButton-stop"].tap()
        app.buttons["mitosis-phase-metaphase"].tap()
        waitFor(guide, "value == %@", "Quiet")
        XCTAssertEqual(guide.label, "Hear Metaphase")
        guide.tap()
        speaking(guide, "3 · Metaphase")
        guide.tap()
        XCTAssertEqual(guide.label, "Hear Metaphase")
    }

    @MainActor
    func testSwipeInterruptsOverviewDisclosureDoesNotRestartAndReturnIsQuiet() {
        let app = openLesson()
        let guide = app.buttons["mitosisListenButton"]
        guide.tap()
        speaking(guide, "Opening")
        let carousel = app.collectionViews["mitosis-phase-carousel"].firstMatch
        XCTAssertTrue(carousel.exists)
        carousel.swipeLeft()
        speaking(guide, "2 · Prometaphase")
        app.buttons["mitosis-phase-prophase"].tap()
        speaking(guide, "1 · Prophase")
        app.buttons["Pack it up"].tap()
        speaking(guide, "1 · Prophase")
        screenshot(app, "Measured expanded phase and adjacent dots")
        app.buttons["Pack it up"].tap()
        app.buttons["mitosis-phase-prophase"].tap()
        speaking(guide, "1 · Prophase")
        app.buttons["mitosisPlayButton"].tap()
        XCTAssertTrue(app.buttons["mitosis-parts-hint"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["mitosisGameListenButton"].label, "Hear instruction")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        XCTAssertEqual(guide.value as? String, "Quiet")
        guide.tap()
        app.activate() // Already active must not replay anything.
        XCUIDevice.shared.press(.home)
        app.activate()
        waitFor(guide, "value == %@", "Quiet")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let entry = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Mitosis,")).firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 5))
        entry.tap()
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        waitFor(guide, "value == %@", "Quiet")
        app.buttons["mitosis-phase-anaphase"].tap()
        waitFor(guide, "value == %@", "Quiet")
    }

    @MainActor
    func testOptionalReferencesAndTranscriptsAreOnDemand() {
        let app = openLesson()
        let counts = app.buttons["narration-reference.human-count"]
        while !counts.isHittable { app.swipeUp() }
        counts.tap()
        waitFor(counts, "label CONTAINS %@", "Stop")
        counts.tap()
        app.buttons["More about human chromosomes"].tap()
        let fact = app.buttons["narration-reference.chromosome-eleven"]
        if !fact.isHittable { app.swipeUp() }
        fact.tap()
        waitFor(fact, "label CONTAINS %@", "Stop")
        let players = app.buttons["Meet the key players"]
        while !players.isHittable { app.swipeUp() }
        players.tap()
        let referenceGuide = app.buttons["mitosisReferenceListenButton"]
        XCTAssertTrue(referenceGuide.waitForExistence(timeout: 5))
        XCTAssertEqual(referenceGuide.value as? String, "Quiet")
        let player = app.buttons["narration-player.chromosomes-sister-chromatids"]
        if !player.isHittable { app.swipeUp() }
        XCTAssertTrue(player.waitForExistence(timeout: 5))
        player.tap()
        waitFor(player, "label CONTAINS %@", "Stop")
        referenceGuide.tap()
        waitFor(player, "label BEGINSWITH %@", "Hear")
        app.buttons["mitosisReferenceListenButton-options"].tap()
        app.buttons["Read transcript"].tap()
        XCTAssertTrue(app.navigationBars["Transcript"].waitForExistence(timeout: 5))
        screenshot(app, "Shared script transcript")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Tap a name to meet the division crew.")).firstMatch.exists)
        app.navigationBars["Transcript"].buttons["Done"].tap()
        app.navigationBars["Mitosis"].buttons["Done"].tap()
    }

    @MainActor
    func testGameGuidanceFollowsActionsAndSkipsObsoletePopups() {
        let app = openLesson()
        app.buttons["mitosisPlayButton"].tap()
        let guide = app.buttons["mitosisGameListenButton"]
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        XCTAssertEqual(guide.label, "Hear instruction")
        guide.tap()
        speaking(guide, "Game begins")
        for id in 1...4 { app.buttons["Condense chromosome \(id)"].tap() }
        speaking(guide, "All four bundles packed")
        app.buttons["Move left centrosome"].tap()
        app.buttons["Move right centrosome"].tap()
        let next = app.buttons["Next: Prometaphase"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        speaking(app.buttons["mitosisPopupListenButton"], "Completion pop-up")
        screenshot(app, "Completion pop-up owns the current cue")
        next.tap() // Do not wait for the long result recording.
        speaking(guide, "Stage begins")
        app.buttons["Open envelope"].tap()
        speaking(guide, "Envelope open")
        for id in 1...4 { app.buttons["Connect chromosome \(id) to left pole"].tap() }
        app.buttons["Right spindle pole, 0 of 4 connected"].tap()
        for id in 1...4 { app.buttons["Connect chromosome \(id) to right pole"].tap() }
        XCTAssertTrue(app.buttons["Next: Metaphase"].waitForExistence(timeout: 5))
        app.buttons["Next: Metaphase"].tap()
        for id in 1...4 { app.buttons["Align chromosome \(id)"].tap() }
        speaking(guide, "All four aligned")
        app.buttons["Run checkpoint"].tap()
        XCTAssertTrue(app.buttons["Next: Anaphase"].waitForExistence(timeout: 5))
        app.buttons["Next: Anaphase"].tap()
        app.buttons["Separate sisters"].tap()
        XCTAssertTrue(app.buttons["Next: Telophase"].waitForExistence(timeout: 5))
        app.buttons["Next: Telophase"].tap()
        app.buttons["Rebuild left nucleus"].tap()
        app.buttons["Rebuild right nucleus"].tap()
        XCTAssertTrue(app.buttons["Mitosis complete!"].waitForExistence(timeout: 5))
        app.buttons["Mitosis complete!"].tap()
        speaking(guide, "Final screen")
        screenshot(app, "Final screen with opt-in growth story")
        app.buttons["Game options"].tap()
        app.buttons["Restart game"].tap()
        app.buttons["Restart"].tap()
        speaking(guide, "Game begins")
        guide.tap()
        for id in 1...4 { app.buttons["Condense chromosome \(id)"].tap() }
        waitFor(guide, "value == %@", "Quiet")
    }

    @MainActor
    func testDisclosureLayoutAtCurrentTextSize() {
        let app = openLesson()
        let disclosure = app.buttons["Pack it up"]
        if !disclosure.isHittable { app.swipeUp() }
        disclosure.tap()
        let dot = app.buttons["mitosis-phase-prophase"]
        for _ in 0..<6 where !dot.isHittable { app.swipeUp() }
        let card = app.collectionViews["mitosis-phase-carousel"].firstMatch
        XCTAssertTrue(dot.exists)
        XCTAssertLessThanOrEqual(dot.frame.minY - card.frame.maxY, 24)
        XCTAssertGreaterThanOrEqual(dot.frame.minY - card.frame.maxY, 0)
        screenshot(app, "Expanded disclosure at current text size")
    }
}
