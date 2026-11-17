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
        XCTAssertTrue(app.buttons["sphaseListenButton"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, up: Bool = true) {
        func ready() -> Bool {
            guard element.isHittable else { return false }
            if element.elementType == .scrollView { return true }
            let frame = element.frame
            return frame.midY >= 70 && frame.midY <= app.frame.maxY - 55
        }
        for _ in 0..<12 where !ready() {
            let below = element.exists ? element.frame.midY > app.frame.midY : up
            if below { app.swipeUp() } else { app.swipeDown() }
        }
        XCTAssertTrue(ready())
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
        waitFor(dot, "value == %@", "Selected", timeout: 3)
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

    @MainActor
    func testNarrationOverviewSwipesTranscriptStopAndReturn() {
        let app = openLesson()
        let guide = app.buttons["sphaseListenButton"]
        XCTAssertEqual(guide.label, "Hear s phase overview")
        guide.tap()
        waitFor(guide, "value CONTAINS %@", "Opening")
        capture(app, "S phase axolotl reads the overview above the carousel")
        select("unzip", in: app)
        reveal(guide, in: app, up: false)
        waitFor(guide, "value CONTAINS %@", "Helicase")
        select("stabilize", in: app)
        select("prime", in: app)
        reveal(guide, in: app, up: false)
        waitFor(guide, "value CONTAINS %@", "RNA primer")
        guide.tap()
        waitFor(guide, "value == %@", "Quiet")
        select("unzip", in: app)
        reveal(guide, in: app, up: false)
        XCTAssertEqual(guide.value as? String, "Quiet")
        app.buttons["sphaseListenButton-options"].tap()
        app.buttons["Read transcript"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Here comes helicase")).firstMatch.waitForExistence(timeout: 5))
        app.buttons["narrationTranscriptListenButton"].tap()
        app.navigationBars["Transcript"].buttons["Done"].tap()
        waitFor(guide, "value == %@", "Quiet")
        guide.tap()
        XCUIDevice.shared.press(.home)
        app.activate()
        waitFor(guide, "value == %@", "Quiet")
    }

    @MainActor
    func testVocabularyReadsTheSelectedDefinitionAndStopsOnChange() {
        let app = openLesson()
        select("unzip", in: app)
        let players = app.buttons["dna-key-players"]
        reveal(players, in: app)
        players.tap()
        let guide = app.buttons["sphaseVocabularyListenButton"]
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        guide.tap()
        waitFor(guide, "value CONTAINS %@", "Meet the key players")
        let speaker = app.buttons["narration-player.helicase"]
        reveal(speaker, in: app)
        speaker.tap()
        waitFor(speaker, "label CONTAINS %@", "Stop")
        capture(app, "S phase vocabulary has an axolotl introduction and definition speakers")
        let next = app.buttons["Next key player"]
        reveal(next, in: app)
        next.tap()
        waitFor(guide, "value == %@", "Quiet")
        let ligase = app.buttons["narration-player.ligation"]
        reveal(ligase, in: app, up: false)
        ligase.press(forDuration: 1)
        app.buttons["Read transcript"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "A nick is a break in the backbone")).firstMatch.waitForExistence(timeout: 5))
        app.navigationBars["Transcript"].buttons["Done"].tap()
        app.buttons["dna-players-done"].tap()
        let main = app.buttons["sphaseListenButton"]
        reveal(main, in: app, up: false)
        XCTAssertEqual(main.value as? String, "Quiet")
    }

    @MainActor
    func testGameNarrationFollowsInstructionsPopupsAndFieldGuide() {
        let app = openLesson()
        app.buttons["dna-play-game"].tap()
        let guide = app.buttons["sphaseGameListenButton"]
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        let drawing = app.otherElements["dna-game-drawing"]
        XCTAssertTrue(drawing.exists)
        XCTAssertLessThanOrEqual(guide.frame.maxY, drawing.frame.minY)
        guide.tap()
        waitFor(guide, "value CONTAINS %@", "How to play")
        capture(app, "S phase axolotl explains the game outside the DNA drawing")
        let origin = app.buttons["Origin of replication"].firstMatch
        reveal(origin, in: app)
        origin.tap()
        let popup = app.buttons["sphasePopupListenButton"]
        XCTAssertTrue(popup.waitForExistence(timeout: 5))
        waitFor(popup, "value CONTAINS %@", "Starting line found")
        advance(app)
        waitFor(guide, "value CONTAINS %@", "Unzip the DNA")
        chooseTool("helicase", in: app)
        apply(app)
        XCTAssertTrue(popup.waitForExistence(timeout: 6))
        waitFor(popup, "value CONTAINS %@", "Unzipped")
        advance(app)
        waitFor(guide, "value CONTAINS %@", "Keep the strands apart")
        app.buttons["Open the DNA field guide"].tap()
        let fieldGuide = app.buttons["sphaseFieldGuideListenButton"]
        XCTAssertTrue(fieldGuide.waitForExistence(timeout: 5))
        XCTAssertEqual(fieldGuide.value as? String, "Quiet")
        let term = app.buttons["narration-term.helicase"]
        reveal(term, in: app)
        term.tap()
        waitFor(term, "label CONTAINS %@", "Stop")
        capture(app, "The in-game vocabulary reads the live term definition")
        app.navigationBars["DNA field guide"].buttons["Done"].tap()
        XCTAssertEqual(guide.value as? String, "Quiet")
        app.buttons["Back to S phase"].tap()
        XCTAssertEqual(app.buttons["sphaseListenButton"].value as? String, "Quiet")
        app.buttons["dna-play-game"].tap()
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        guide.tap()
        let newOrigin = app.buttons["Origin of replication"].firstMatch
        reveal(newOrigin, in: app)
        newOrigin.tap()
        XCTAssertTrue(popup.waitForExistence(timeout: 5))
        waitFor(popup, "value CONTAINS %@", "Starting line found")
    }

    @MainActor
    func testSmallPhoneNarrationWorksWithLargestTextAndReduceMotion() {
        let app = openLesson()
        let guide = app.buttons["sphaseListenButton"]
        reveal(guide, in: app)
        XCTAssertTrue(guide.isEnabled)
        XCTAssertGreaterThanOrEqual(guide.frame.height, 44)
        XCTAssertLessThanOrEqual(guide.frame.maxX, app.frame.maxX)
        guide.tap()
        waitFor(guide, "value CONTAINS %@", "Opening")
        capture(app, "Audio remains available with Reduce Motion and largest text")
        let play = app.buttons["dna-play-game"]
        reveal(play, in: app, up: false)
        play.tap()
        let gameGuide = app.buttons["sphaseGameListenButton"]
        reveal(gameGuide, in: app)
        XCTAssertEqual(gameGuide.value as? String, "Quiet")
        gameGuide.tap()
        waitFor(gameGuide, "value CONTAINS %@", "How to play")
        let drawing = app.otherElements["dna-game-drawing"]
        XCTAssertLessThanOrEqual(gameGuide.frame.maxY, drawing.frame.minY)
        let origin = app.buttons["Origin of replication"].firstMatch
        reveal(origin, in: app)
        origin.tap()
        let popup = app.buttons["sphasePopupListenButton"]
        reveal(popup, in: app)
        waitFor(popup, "value CONTAINS %@", "Starting line found")
        capture(app, "Large-text game narration leaves targets and Continue reachable")
        advance(app)
        reveal(gameGuide, in: app, up: false)
        waitFor(gameGuide, "value CONTAINS %@", "Unzip the DNA")
        gameGuide.tap()
        let back = app.buttons["Back to S phase"]
        reveal(back, in: app, up: false)
        back.tap()
        let players = app.buttons["dna-key-players"]
        reveal(players, in: app)
        players.tap()
        let vocabularyGuide = app.buttons["sphaseVocabularyListenButton"]
        reveal(vocabularyGuide, in: app)
        XCTAssertGreaterThanOrEqual(vocabularyGuide.frame.height, 44)
        vocabularyGuide.tap()
        waitFor(vocabularyGuide, "value CONTAINS %@", "Meet the key players")
        let definition = app.buttons["narration-player.genome"]
        reveal(definition, in: app)
        definition.tap()
        waitFor(definition, "label CONTAINS %@", "Stop")
        capture(app, "Large-text vocabulary keeps the selected definition and its speaker reachable")
    }
}
