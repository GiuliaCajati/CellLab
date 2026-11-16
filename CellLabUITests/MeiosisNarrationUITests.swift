import XCTest

final class MeiosisNarrationUITests: XCTestCase {
    @MainActor
    private func openLesson() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let entry = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meiosis,")).firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 8))
        for _ in 0..<5 where !entry.isHittable { app.swipeUp() }
        XCTAssertTrue(entry.isHittable)
        entry.tap()
        XCTAssertTrue(app.buttons["meiosisListenButton"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    private func waitFor(_ element: XCUIElement, _ predicate: String, _ value: String, timeout: TimeInterval = 6,
                         file: StaticString = #filePath, line: UInt = #line) {
        let expected = XCTNSPredicateExpectation(predicate: NSPredicate(format: predicate, value), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expected], timeout: timeout), .completed, file: file, line: line)
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, up: Bool = true) {
        for _ in 0..<7 where !element.isHittable {
            if up { app.swipeUp() } else { app.swipeDown() }
        }
        XCTAssertTrue(element.isHittable)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testStationaryGuideSwipesStopAndGameReturn() {
        let app = openLesson()
        let guide = app.buttons["meiosisListenButton"]
        let subtitle = app.staticTexts["Half the chromosomes. A new mix."]
        XCTAssertEqual(guide.label, "Hear meiosis overview")
        XCTAssertEqual(guide.value as? String, "Quiet")
        XCTAssertEqual(app.buttons["meiosisPlayButton"].label, "Play game")
        XCTAssertEqual(guide.frame.height, 48, accuracy: 1)
        XCTAssertEqual(guide.frame.minY - subtitle.frame.maxY, 8, accuracy: 1)
        let position = guide.frame.origin
        capture(app, "Meiosis guide above the first card")
        guide.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        waitFor(guide, "value CONTAINS %@", "Opening")
        let carousel = app.scrollViews["meiosis-phase-carousel"]
        XCTAssertTrue(carousel.exists)
        carousel.swipeLeft()
        waitFor(guide, "value CONTAINS %@", "Metaphase I")
        XCTAssertEqual(guide.frame.minX, position.x, accuracy: 1)
        XCTAssertEqual(guide.frame.minY, position.y, accuracy: 1)
        app.buttons["meiosis-phase-prophase-ii"].tap()
        waitFor(guide, "value CONTAINS %@", "Prophase II")
        guide.tap()
        app.buttons["meiosis-phase-telophase-ii"].tap()
        waitFor(guide, "value == %@", "Quiet")
        XCTAssertEqual(guide.label, "Hear Telophase II")
        guide.tap()
        waitFor(guide, "value CONTAINS %@", "Telophase II")
        app.buttons["meiosisPlayButton"].tap()
        let gameGuide = app.buttons["meiosisGameListenButton"]
        XCTAssertTrue(gameGuide.waitForExistence(timeout: 5))
        XCTAssertEqual(gameGuide.value as? String, "Quiet")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        XCTAssertEqual(guide.value as? String, "Quiet")
    }

    @MainActor
    func testActualOverviewHandsOffAndStopsBetweenPhases() {
        let app = openLesson()
        let guide = app.buttons["meiosisListenButton"]
        guide.tap()
        waitFor(guide, "value CONTAINS %@", "Opening")
        waitFor(guide, "value CONTAINS %@", "Prophase I", timeout: 65)
        waitFor(guide, "label == %@", "Replay Prophase I", timeout: 65)
        XCTAssertTrue(app.buttons["meiosisListenButton-stop"].exists)
        app.buttons["meiosisListenButton-stop"].tap()
        app.buttons["meiosis-phase-metaphase-i"].tap()
        waitFor(guide, "value == %@", "Quiet")
        XCTAssertEqual(guide.label, "Hear Metaphase I")
    }

    @MainActor
    func testOptionalCountsPlayersTranscriptAndBackgroundAreQuietOnReturn() {
        let app = openLesson()
        let counts = app.buttons["narration-reference.counts"]
        reveal(counts, in: app)
        counts.tap()
        waitFor(counts, "label CONTAINS %@", "Stop")
        let players = app.buttons["Meet the key players"]
        reveal(players, in: app)
        players.tap()
        let referenceGuide = app.buttons["meiosisReferenceListenButton"]
        XCTAssertTrue(referenceGuide.waitForExistence(timeout: 5))
        XCTAssertEqual(referenceGuide.value as? String, "Quiet")
        let crossing = app.buttons["narration-player.crossing"]
        reveal(crossing, in: app)
        crossing.tap()
        waitFor(crossing, "label CONTAINS %@", "Stop")
        XCUIDevice.shared.press(.home)
        app.activate()
        waitFor(crossing, "label BEGINSWITH %@", "Hear")
        app.buttons["Done"].tap()
        reveal(app.buttons["meiosisListenButton"], in: app, up: false)
        let guide = app.buttons["meiosisListenButton"]
        XCTAssertEqual(guide.value as? String, "Quiet")
        app.buttons["meiosisListenButton-options"].tap()
        app.buttons["Read transcript"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Why can siblings")).firstMatch.waitForExistence(timeout: 5))
        let transcriptGuide = app.buttons["narrationTranscriptListenButton"]
        transcriptGuide.tap()
        waitFor(transcriptGuide, "value CONTAINS %@", "Opening")
        app.buttons["Done"].tap()
        waitFor(guide, "value == %@", "Quiet")
    }

    @MainActor
    func testGameGuideFollowsAvailableActionsAndStaysOutsideScene() {
        let app = openLesson()
        app.buttons["meiosisPlayButton"].tap()
        let guide = app.buttons["meiosisGameListenButton"]
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        let scene = app.otherElements["meiosis-playfield"].firstMatch
        XCTAssertTrue(scene.exists)
        XCTAssertFalse(scene.frame.intersects(guide.frame))
        capture(app, "Meiosis game axolotl beside the instruction")
        guide.tap()
        waitFor(guide, "value CONTAINS %@", "Prophase I")
        for number in 1...4 {
            let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"),
                                                  object: app.buttons["meiosis-parts-hint"])
            XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 4), .completed)
            let chromosome = app.buttons["Condense chromosome \(number)"]
            XCTAssertTrue(chromosome.waitForExistence(timeout: 3))
            chromosome.tap()
            XCTAssertTrue(chromosome.waitForNonExistence(timeout: 3))
        }
        XCTAssertTrue(app.buttons["Open envelope"].waitForExistence(timeout: 4))
        waitFor(guide, "label == %@", "Replay instruction", timeout: 8)
        capture(app, "Prophase I instruction changes with the game")
        func act(_ label: String) {
            let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"),
                                                  object: app.buttons["meiosis-parts-hint"])
            XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 4), .completed)
            let button = app.buttons[label]
            XCTAssertTrue(button.waitForExistence(timeout: 4))
            button.tap()
        }
        act("Open envelope")
        act("Pair homologs 1")
        act("Pair homologs 2")
        act("Cross over matching non-sister segments in pair 1")
        act("Cross over matching non-sister segments in pair 2")
        let popupGuide = app.buttons["meiosisPopupListenButton"]
        XCTAssertTrue(popupGuide.waitForExistence(timeout: 5))
        waitFor(popupGuide, "value CONTAINS %@", "Prophase I complete")
        capture(app, "Completion popup has its own narration")
        app.buttons["Next: Metaphase I"].tap()
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        waitFor(guide, "value CONTAINS %@", "Metaphase I")
        XCUIDevice.shared.press(.home)
        app.activate()
        waitFor(guide, "value == %@", "Quiet")
    }

    @MainActor
    func testHomologousPairExplainerAndTranscriptShareTheBloodTypeExample() {
        let app = openLesson()
        let speaker = app.buttons["narration-player.term-4"]
        reveal(speaker, in: app)
        XCTAssertTrue(app.staticTexts["What is a homologous pair?"].exists)
        speaker.tap()
        waitFor(speaker, "label CONTAINS %@", "Stop")
        capture(app, "Matching chromosome 9s with the ABO gene at the same position")
        let details = app.buttons["Genes, alleles, and traits"]
        reveal(details, in: app)
        details.tap()
        let explanation = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@",
                                                               "both copies of chromosome 9 carry the ABO")).firstMatch
        XCTAssertTrue(explanation.waitForExistence(timeout: 4))
        capture(app, "Homologous chromosomes share a gene address but can carry different alleles")
        reveal(speaker, in: app, up: false)
        speaker.press(forDuration: 1)
        app.buttons["Read transcript"].tap()
        let transcript = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@",
                                                              "Your two alleles can also be the same")).firstMatch
        XCTAssertTrue(transcript.waitForExistence(timeout: 4))
        app.buttons["Done"].tap()
        waitFor(speaker, "label BEGINSWITH %@", "Hear")
    }

    @MainActor
    func testSmallPhoneLargeTextKeepsGuideAndPiecesReachable() {
        let app = openLesson()
        let guide = app.buttons["meiosisListenButton"]
        reveal(guide, in: app)
        XCTAssertGreaterThanOrEqual(guide.frame.height, 44)
        XCTAssertLessThanOrEqual(guide.frame.maxX, app.frame.maxX)
        guide.tap()
        XCTAssertEqual(guide.label, "Stop narration")
        capture(app, "Meiosis at largest text size with Reduce Motion")
        guide.tap()
        let play = app.buttons["meiosisPlayButton"]
        reveal(play, in: app, up: false)
        play.tap()
        let gameGuide = app.buttons["meiosisGameListenButton"]
        reveal(gameGuide, in: app)
        XCTAssertGreaterThanOrEqual(gameGuide.frame.height, 44)
        gameGuide.tap()
        XCTAssertEqual(gameGuide.label, "Stop narration")
        let scene = app.otherElements["meiosis-playfield"].firstMatch
        XCTAssertGreaterThanOrEqual(scene.frame.height, 250)
        XCTAssertFalse(scene.frame.intersects(gameGuide.frame))
        capture(app, "Meiosis game at largest text size")
        let chromosome = app.buttons["Condense chromosome 1"]
        reveal(chromosome, in: app, up: false)
        chromosome.tap()
        XCTAssertTrue(chromosome.waitForNonExistence(timeout: 3))
    }
}
