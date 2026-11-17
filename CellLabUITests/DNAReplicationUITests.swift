import XCTest

final class DNAReplicationUITests: XCTestCase {
    @MainActor
    private func openLesson() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let module = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "S Phase,")).firstMatch
        XCTAssertTrue(module.waitForExistence(timeout: 8))
        for _ in 0..<8 where !module.isHittable { app.swipeUp() }
        XCTAssertTrue(module.isHittable)
        module.tap()
        XCTAssertTrue(app.buttons["dna-play-pause"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, up: Bool = true) {
        for _ in 0..<8 where !element.isHittable {
            if up { app.swipeUp() } else { app.swipeDown() }
        }
        XCTAssertTrue(element.isHittable)
    }

    @MainActor
    private func waitFor(_ element: XCUIElement, _ predicate: String, _ value: String, timeout: TimeInterval = 6,
                         file: StaticString = #filePath, line: UInt = #line) {
        let expected = XCTNSPredicateExpectation(predicate: NSPredicate(format: predicate, value), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expected], timeout: timeout), .completed, file: file, line: line)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func select(_ slug: String, in app: XCUIApplication) {
        let dot = app.buttons["dna-step-\(slug)"]
        reveal(dot, in: app)
        dot.tap()
        XCTAssertEqual(dot.value as? String, "Selected")
    }

    @MainActor
    func testNineCardsAndAnimationPauseReplayAndWait() async throws {
        let app = openLesson()
        XCTAssertTrue(app.staticTexts["S phase"].exists)
        let guide = app.buttons["dna-play-pause"]
        XCTAssertEqual(guide.label, "Watch animation")
        XCTAssertEqual(guide.frame.height, 48, accuracy: 1)
        capture(app, "S phase matches the Meiosis lesson layout")
        select("unzip", in: app)
        reveal(guide, in: app, up: false)
        waitFor(guide, "label == %@", "Pause animation")
        guide.tap()
        XCTAssertEqual(guide.label, "Resume animation")
        let value = guide.value as? String
        try await Task.sleep(for: .milliseconds(400))
        XCTAssertEqual(guide.value as? String, value)
        capture(app, "Helicase paused at the DNA fork")
        guide.tap()
        waitFor(guide, "label == %@", "Pause animation")
        XCUIDevice.shared.press(.home)
        app.activate()
        waitFor(guide, "label == %@", "Resume animation")
        guide.tap()
        waitFor(guide, "label == %@", "Replay animation", timeout: 9)
        XCTAssertEqual(app.buttons["dna-step-unzip"].value as? String, "Selected")
        for slug in ["origins", "stabilize", "prime", "build", "proofread", "replace", "seal", "result"] {
            select(slug, in: app)
        }
        reveal(guide, in: app, up: false)
        guide.tap() // Pause the selected result clip before inspecting its details.
        let details = app.buttons["One old + one new"]
        reveal(details, in: app)
        details.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "two matching double-stranded")).firstMatch.exists)
    }

    @MainActor
    func testEnlargedDiagramSharesOneClockAndHelicaseReferenceIsReachable() async throws {
        let app = openLesson()
        select("unzip", in: app)
        let enlarge = app.buttons["dna-enlarge-unzip"]
        reveal(enlarge, in: app, up: false)
        enlarge.tap()
        let replay = app.buttons["Replay this card"]
        XCTAssertTrue(replay.waitForExistence(timeout: 5))
        replay.tap()
        let diagram = app.otherElements["dna-replication-diagram-unzip"].firstMatch
        XCTAssertTrue(diagram.exists)
        func percentage() -> Double {
            Double((diagram.value as? String ?? "").split(separator: " ").first ?? "") ?? -1
        }
        let before = percentage()
        let started = Date()
        try await Task.sleep(for: .milliseconds(700))
        let after = percentage()
        let expected = min(100 - before, Date().timeIntervalSince(started) / 6 * 100)
        XCTAssertGreaterThan(after, before)
        XCTAssertEqual(after - before, expected, accuracy: 6)
        capture(app, "The close-up runs the helicase animation at one playback speed")
        app.buttons["Done"].tap()
        let players = app.buttons["dna-key-players"]
        reveal(players, in: app)
        players.tap()
        XCTAssertTrue(app.staticTexts["Helicase"].firstMatch.waitForExistence(timeout: 5))
        capture(app, "Helicase reference demonstrates unzipping")
        app.buttons["dna-players-done"].tap()
        let guide = app.buttons["dna-play-pause"]
        reveal(guide, in: app, up: false)
        XCTAssertNotEqual(guide.label, "Pause animation")
    }

    @MainActor
    private func startGame(_ app: XCUIApplication) {
        let play = app.buttons["dna-play-game"]
        reveal(play, in: app, up: false)
        play.tap()
        let origin = app.buttons["Origin of replication"].firstMatch
        XCTAssertTrue(origin.waitForExistence(timeout: 5))
        reveal(origin, in: app)
        origin.tap()
        advance(app)
    }

    @MainActor
    private func advance(_ app: XCUIApplication) {
        let next = app.buttons["dna-game-continue"]
        XCTAssertTrue(next.waitForExistence(timeout: 6))
        next.tap()
    }

    @MainActor
    private func chooseTool(_ name: String, in app: XCUIApplication) {
        let button = app.buttons["dna-game-tool-\(name)"]
        let tools = app.scrollViews["dna-game-tools"]
        reveal(tools, in: app)
        for _ in 0..<7 where !button.isHittable { tools.swipeLeft() }
        if !button.isHittable {
            for _ in 0..<7 where !button.isHittable { tools.swipeRight() }
        }
        XCTAssertTrue(button.isHittable)
        button.tap()
    }

    @MainActor
    private func apply(_ app: XCUIApplication) {
        let button = app.buttons["dna-game-apply-selection"]
        XCTAssertTrue(button.waitForExistence(timeout: 4))
        reveal(button, in: app)
        XCTAssertTrue(button.isEnabled)
        button.tap()
    }

    @MainActor
    func testGameHelicaseUnzipsBeforeContinuingAndReturnIsPaused() {
        let app = openLesson()
        select("unzip", in: app)
        startGame(app)
        chooseTool("helicase", in: app)
        let target = app.buttons["Unzip here with helicase"].firstMatch
        reveal(target, in: app)
        XCTAssertEqual(target.frame.width, 56, accuracy: 1)
        XCTAssertEqual(target.frame.height, 56, accuracy: 1)
        target.tap()
        XCTAssertTrue(app.staticTexts["Unzipped!"].waitForExistence(timeout: 6))
        capture(app, "The game celebrates after the zipper has opened the DNA")
        advance(app)
        XCTAssertTrue(app.buttons["Stabilize this single DNA strand"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["Back to S phase"].tap()
        let guide = app.buttons["dna-play-pause"]
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        XCTAssertNotEqual(guide.label, "Pause animation")
    }

    @MainActor
    func testSmallPhoneReduceMotionKeepsAllStepsAndGameTargetsReachable() {
        let app = openLesson()
        let guide = app.buttons["dna-play-pause"]
        XCTAssertEqual(guide.label, "Still illustrations")
        XCTAssertFalse(guide.isEnabled)
        select("unzip", in: app)
        capture(app, "Helicase has a complete still diagram with Reduce Motion")
        select("result", in: app)
        startGame(app)
        chooseTool("helicase", in: app)
        apply(app)
        XCTAssertTrue(app.staticTexts["Unzipped!"].waitForExistence(timeout: 5))
        advance(app)
        chooseTool("binding", in: app)
        for _ in 0..<3 { apply(app) }
        advance(app)
        chooseTool("primase", in: app)
        apply(app)
        advance(app)
        XCTAssertTrue(app.buttons["dna-game-tool-polymerase"].exists)
        capture(app, "Small-phone tools still work after helicase, binding, and priming")
    }
}
