import XCTest

final class CentralDogmaLessonUITests: XCTestCase {
    @MainActor
    private func openLesson() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let module = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Central Dogma,")).firstMatch
        XCTAssertTrue(module.waitForExistence(timeout: 8))
        reveal(module, in: app)
        module.tap()
        XCTAssertTrue(app.buttons["central-dogma-overview"].waitForExistence(timeout: 5))
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
            let end = start.withOffset(CGVector(dx: 0, dy: below ? -distance : distance))
            start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        XCTAssertTrue(element.isHittable, file: file, line: line)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func waitForSpeech(_ element: XCUIElement, containing title: String) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value CONTAINS[cd] %@", title), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
    }

    @MainActor
    func testSwipeCardsKeepGuideFixedAndDescriptionsExpand() {
        let app = openLesson()
        let guide = app.buttons["central-dogma-overview"]
        let game = app.buttons["central-dogma-play-game"]
        XCTAssertTrue(game.isHittable)
        XCTAssertTrue(app.staticTexts["Find the gene"].exists)
        XCTAssertTrue(app.staticTexts["1 / 9"].exists)
        XCTAssertFalse(app.buttons["central-dogma-step-overview"].exists)
        XCTAssertEqual(guide.frame.height, 48, accuracy: 1)
        capture(app, "Central Dogma uses the S phase lesson layout")

        guide.tap()
        waitForSpeech(guide, containing: "Opening")
        guide.tap()
        XCTAssertEqual(guide.value as? String, "Quiet")
        let origin = guide.frame.origin
        let carousel = app.collectionViews["central-dogma-carousel"]
        carousel.swipeLeft()
        XCTAssertTrue(app.staticTexts["Write the RNA"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons["central-dogma-step-transcriptionBuild"].value as? String, "Selected")
        XCTAssertEqual(guide.frame.minX, origin.x, accuracy: 1)
        XCTAssertEqual(guide.frame.minY, origin.y, accuracy: 1)

        let description = app.buttons["Read 3′ → 5′. Write 5′ → 3′."]
        reveal(description, in: app)
        description.tap()
        let explanation = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "RNA polymerase reads the DNA template")).firstMatch
        XCTAssertTrue(explanation.waitForExistence(timeout: 3))
        reveal(explanation, in: app)
        capture(app, "Transcription description expands inside the pastel card")

        let bigPicture = app.staticTexts["The big picture"]
        reveal(bigPicture, in: app)
        XCTAssertGreaterThan(bigPicture.frame.minY, carousel.frame.maxY)
        app.buttons["central-dogma-enlarge-overview"].tap()
        XCTAssertTrue(app.buttons["central-dogma-diagram-done"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Previous card"].isEnabled)
        XCTAssertFalse(app.buttons["Next card"].isEnabled)
        app.buttons["central-dogma-diagram-done"].tap()
        XCTAssertEqual(app.buttons["central-dogma-step-transcriptionBuild"].value as? String, "Selected")
        capture(app, "The big picture is separate below the nine process slides")
    }

    @MainActor
    func testPlaybackCloseUpKeyPlayersAndGameTransitions() async throws {
        let app = openLesson()
        let playback = app.buttons["central-dogma-animate"]
        reveal(playback, in: app)
        XCTAssertEqual(playback.label, "Watch animation")
        playback.tap()
        XCTAssertEqual(playback.label, "Pause animation")
        playback.tap()
        XCTAssertEqual(playback.label, "Resume animation")
        let paused = playback.value as? String
        try await Task.sleep(for: .milliseconds(400))
        XCTAssertEqual(playback.value as? String, paused)

        let enlarge = app.buttons["central-dogma-enlarge-transcriptionStart"]
        reveal(enlarge, in: app)
        enlarge.tap()
        XCTAssertTrue(app.navigationBars["Central Dogma close-up"].waitForExistence(timeout: 3))
        app.buttons["central-dogma-diagram-done"].tap()

        let players = app.buttons["central-dogma-key-players"]
        reveal(players, in: app)
        players.tap()
        let crew = app.collectionViews["central-dogma-players-carousel"]
        XCTAssertTrue(crew.waitForExistence(timeout: 3))
        let introduction = app.buttons["central-dogma-vocabulary-listen"]
        introduction.tap()
        waitForSpeech(introduction, containing: "Meet the key players")
        introduction.tap()
        crew.swipeLeft()
        XCTAssertTrue(app.staticTexts["Promoter & terminator"].waitForExistence(timeout: 3))
        let speaker = app.buttons["narration-player.signals"]
        reveal(speaker, in: app)
        speaker.tap()
        XCTAssertEqual(speaker.label, "Stop Promoter & terminator narration")
        capture(app, "Key player cards swipe like S phase")
        app.buttons["central-dogma-players-done"].tap()

        let game = app.buttons["central-dogma-play-game"]
        reveal(game, in: app)
        game.tap()
        XCTAssertTrue(app.staticTexts["RNA Relay"].waitForExistence(timeout: 3))
        capture(app, "Play game opens RNA Relay")
    }

    @MainActor
    func testOverviewAndLongDescriptionsAtCurrentTextSize() {
        let app = openLesson()
        let options = app.buttons["central-dogma-overview-options"]
        reveal(options, in: app)
        options.tap()
        app.buttons["Read transcript"].tap()
        let intro = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "How does a cell turn the instructions")).firstMatch
        XCTAssertTrue(intro.waitForExistence(timeout: 3))
        XCTAssertGreaterThanOrEqual(intro.frame.minX, 0)
        XCTAssertLessThanOrEqual(intro.frame.maxX, app.frame.maxX)
        capture(app, "Axolotl introduction at the current text size")
        app.buttons["Done"].tap()

        let processing = app.buttons["central-dogma-step-processing"]
        reveal(processing, in: app)
        processing.tap()
        let description = app.buttons["Cap. Tail. Splice. Send."]
        reveal(description, in: app)
        description.tap()
        let ending = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "The resulting mature mRNA exits the nucleus")).firstMatch
        XCTAssertTrue(ending.waitForExistence(timeout: 3))
        reveal(ending, in: app)
        XCTAssertGreaterThanOrEqual(ending.frame.minX, 0)
        XCTAssertLessThanOrEqual(ending.frame.maxX, app.frame.maxX)
        capture(app, "Full processing description remains readable")
    }

    @MainActor
    func testAxolotlFollowsSwipesAndGameInstructionsUntilStopped() {
        let app = openLesson()
        let axolotl = app.buttons["central-dogma-overview"]
        XCTAssertEqual(axolotl.value as? String, "Quiet")
        axolotl.tap()
        waitForSpeech(axolotl, containing: "Opening")
        app.collectionViews["central-dogma-carousel"].swipeLeft()
        waitForSpeech(axolotl, containing: "Write the RNA")
        axolotl.tap()
        XCTAssertEqual(axolotl.value as? String, "Quiet")
        let game = app.buttons["central-dogma-play-game"]
        reveal(game, in: app)
        game.tap()
        let introduction = app.buttons["central-dogma-game-introduction-listen"]
        XCTAssertTrue(introduction.waitForExistence(timeout: 4))
        XCTAssertEqual(introduction.value as? String, "Quiet")
        introduction.tap()
        waitForSpeech(introduction, containing: "How to play RNA Relay")
        let start = app.buttons["Let’s make a message"]
        reveal(start, in: app)
        start.tap()
        let instruction = app.buttons["central-dogma-game-listen"]
        XCTAssertTrue(instruction.waitForExistence(timeout: 4))
        waitForSpeech(instruction, containing: "Recruit the crew")
        let finished = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "Quiet"), object: instruction)
        XCTAssertEqual(XCTWaiter.wait(for: [finished], timeout: 10), .completed)
        instruction.tap()
        waitForSpeech(instruction, containing: "Recruit the crew")
        instruction.tap()
        XCTAssertEqual(instruction.value as? String, "Quiet")
        capture(app, "Axolotl narrates beside the instruction and outside the board")
    }
}
