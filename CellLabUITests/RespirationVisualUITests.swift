import XCTest

final class RespirationVisualUITests: XCTestCase {
    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<20 {
            let bar = app.navigationBars.firstMatch
            let top = bar.exists ? bar.frame.maxY + 6 : app.frame.minY + 45
            if element.isHittable, element.frame.midY > top,
               element.frame.midY < app.frame.maxY - 15 { return }
            let below = !element.exists || element.frame.midY > app.frame.midY
            let distance = element.exists ? min(max(abs(element.frame.midY - app.frame.midY), 80), app.frame.height * 0.45)
                : app.frame.height * 0.45
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: below ? 0.7 : 0.3))
            start.press(forDuration: 0.01, thenDragTo: start.withOffset(CGVector(dx: 0, dy: below ? -distance : distance)),
                        withVelocity: .slow, thenHoldForDuration: 0.05)
        }
        XCTAssertTrue(element.isHittable)
    }

    @MainActor private func openLesson() -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()
        let module = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Cellular Respiration,")).firstMatch
        XCTAssertTrue(module.waitForExistence(timeout: 8))
        reveal(module, in: app)
        module.tap()
        XCTAssertTrue(app.otherElements["respiration-card-glycolysis"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["respiration-card-overview"].exists)
        return app
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor func testEveryStageAndItsExplanationRemainReachable() {
        let app = openLesson()
        let ids = ["glycolysis", "transition", "krebs", "transport", "chemiosmosis",
                   "accounting", "efficiency", "anaerobic", "fermentation"]
        XCTAssertFalse(app.buttons["respiration-previous"].isEnabled)
        for (index, id) in ids.enumerated() {
            XCTAssertTrue(app.otherElements["respiration-card-" + id].waitForExistence(timeout: 3))
            // Show the drawing rather than leaving the scroll position at the controls.
            app.swipeDown()
            capture(app, "Respiration - " + id)
            let explanation = app.buttons["respiration-explanation"]
            reveal(explanation, in: app)
            explanation.tap()
            XCTAssertEqual(explanation.value as? String, "Expanded")
            explanation.tap()
            XCTAssertEqual(explanation.value as? String, "Collapsed")
            let next = app.buttons["respiration-next"]
            reveal(next, in: app)
            if index == ids.count - 1 { XCTAssertFalse(next.isEnabled) }
            else { next.tap() }
        }
        let previous = app.buttons["respiration-previous"]
        previous.tap()
        XCTAssertTrue(app.otherElements["respiration-card-anaerobic"].waitForExistence(timeout: 3))
        app.swipeDown()
        let enlarge = app.buttons["Enlarge diagram"]
        reveal(enlarge, in: app)
        enlarge.tap()
        let zoom = app.sliders["Diagram zoom"]
        XCTAssertTrue(zoom.waitForExistence(timeout: 3))
        zoom.adjust(toNormalizedSliderPosition: 0.6)
        capture(app, "Respiration - zoomed close-up")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.otherElements["respiration-card-anaerobic"].waitForExistence(timeout: 3))
        let overview = app.otherElements["respiration-big-picture"]
        reveal(overview, in: app)
        let equation = app.otherElements["respiration-equation"]
        reveal(equation, in: app)
        XCTAssertTrue(equation.label.contains("six oxygen"))
        XCTAssertGreaterThan(overview.frame.minY, app.otherElements["respiration-card-anaerobic"].frame.maxY)
        capture(app, "Respiration - big picture and overall reaction below the slides")
    }

    @MainActor func testKeyPlayerArtworkAndReturnToLesson() {
        let app = openLesson()
        let players = app.buttons["respiration-key-players"]
        reveal(players, in: app)
        players.tap()
        XCTAssertTrue(app.otherElements["respiration-player-cytosol"].waitForExistence(timeout: 3))
        let previous = app.buttons["respiration-players-previous"]
        reveal(previous, in: app)
        previous.tap()
        let ids = ["atp", "cytosol", "mitochondrion", "matrix", "membrane", "compartment", "nad", "fad", "acetyl",
                   "cycle", "synthase", "phosphorylation", "redox", "fermentation"]
        for id in ids {
            XCTAssertTrue(app.otherElements["respiration-player-" + id].waitForExistence(timeout: 3))
            if ["mitochondrion", "synthase", "redox"].contains(id) {
                app.swipeDown()
                capture(app, "Respiration player - " + id)
            }
            let next = app.buttons["respiration-players-next"]
            reveal(next, in: app)
            if id == "fermentation" { XCTAssertFalse(next.isEnabled) }
            else { next.tap() }
        }
        app.buttons["respiration-players-done"].tap()
        XCTAssertTrue(app.otherElements["respiration-card-glycolysis"].waitForExistence(timeout: 3))
    }

    @MainActor func testCloseUpAndDefinitionsStayReachableAtCurrentTextSize() {
        let app = openLesson()
        let animate = app.buttons["respiration-animate"]
        reveal(animate, in: app)
        if animate.isEnabled {
            animate.tap()
            XCTAssertEqual(animate.label, "Pause animation")
            animate.tap()
            XCTAssertEqual(animate.label, "Animate steps")
        }
        let enlarge = app.buttons["Enlarge diagram"]
        reveal(enlarge, in: app)
        enlarge.tap()
        let zoom = app.sliders["Diagram zoom"]
        XCTAssertTrue(zoom.waitForExistence(timeout: 3))
        XCTAssertTrue(zoom.isHittable)
        let chooser = app.buttons["respiration-diagram-card"]
        chooser.tap()
        app.collectionViews.buttons["Prepare the fuel"].tap()
        XCTAssertEqual(chooser.value as? String, "Prepare the fuel")
        chooser.tap()
        app.collectionViews.buttons["Split the sugar"].tap()
        XCTAssertEqual(chooser.value as? String, "Split the sugar")
        zoom.adjust(toNormalizedSliderPosition: 0.3)
        capture(app, "Respiration close-up with larger text")
        app.buttons["Done"].tap()
        let explanation = app.buttons["respiration-explanation"]
        reveal(explanation, in: app)
        explanation.tap()
        XCTAssertEqual(explanation.value as? String, "Expanded")
        explanation.tap()
        let players = app.buttons["respiration-key-players"]
        reveal(players, in: app)
        players.tap()
        XCTAssertTrue(app.otherElements["respiration-player-cytosol"].waitForExistence(timeout: 3))
        let sheetGuide = app.buttons["respiration-players-listen"]
        reveal(sheetGuide, in: app)
        sheetGuide.tap()
        waitForSpeech(sheetGuide, "energy-making crew")
        capture(app, "Respiration definitions with larger text")
        sheetGuide.tap()
        app.buttons["respiration-players-done"].tap()
        XCTAssertTrue(app.otherElements["respiration-card-glycolysis"].waitForExistence(timeout: 3))
    }

    @MainActor private func waitForSpeech(_ guide: XCUIElement, _ title: String) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value CONTAINS[cd] %@", title), object: guide)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
    }

    @MainActor func testAxolotlReadsOpeningTracksSlidesAndStops() {
        let app = openLesson()
        let guide = app.buttons["respiration-listen"]
        XCTAssertEqual(guide.value as? String, "Quiet")
        capture(app, "Respiration - colorful first card and axolotl")
        let next = app.buttons["respiration-next"]
        reveal(next, in: app)
        next.tap()
        reveal(guide, in: app)
        XCTAssertEqual(guide.label, "Hear cellular respiration overview")
        guide.tap()
        waitForSpeech(guide, "Opening")
        capture(app, "Respiration - speaking axolotl")
        reveal(next, in: app)
        next.tap()
        waitForSpeech(guide, "Turn the cycle")
        reveal(guide, in: app)
        guide.tap()
        XCTAssertEqual(guide.value as? String, "Quiet")
        let bigPicture = app.buttons["narration-reference.big-picture"]
        reveal(bigPicture, in: app)
        bigPicture.tap()
        waitForSpeech(guide, "The big picture")
        let equation = app.buttons["narration-reference.equation"]
        reveal(equation, in: app)
        equation.tap()
        waitForSpeech(guide, "The overall reaction")
        equation.tap()
        XCTAssertEqual(guide.value as? String, "Quiet")
        reveal(guide, in: app)
        guide.tap()
        waitForSpeech(guide, "Turn the cycle")
        XCUIDevice.shared.press(.home)
        app.activate()
        waitForSpeech(guide, "Quiet")
        app.navigationBars.buttons.firstMatch.tap()
        let module = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Cellular Respiration,")).firstMatch
        reveal(module, in: app)
        module.tap()
        XCTAssertTrue(guide.waitForExistence(timeout: 3))
        XCTAssertEqual(guide.value as? String, "Quiet")
    }

    @MainActor func testVocabularyGuideAndCloseUpUseCurrentRecording() {
        let app = openLesson()
        let guide = app.buttons["respiration-listen"]
        guide.tap()
        waitForSpeech(guide, "Opening")
        let players = app.buttons["respiration-key-players"]
        reveal(players, in: app)
        players.tap()
        let sheetGuide = app.buttons["respiration-players-listen"]
        XCTAssertTrue(sheetGuide.waitForExistence(timeout: 3))
        XCTAssertEqual(sheetGuide.value as? String, "Quiet")
        sheetGuide.tap()
        waitForSpeech(sheetGuide, "energy-making crew")
        let next = app.buttons["respiration-players-next"]
        reveal(next, in: app)
        next.tap()
        waitForSpeech(sheetGuide, "Mitochondrion")
        reveal(sheetGuide, in: app)
        sheetGuide.tap()
        XCTAssertEqual(sheetGuide.value as? String, "Quiet")
        let definition = app.buttons["narration-player.mitochondrion"]
        reveal(definition, in: app)
        definition.tap()
        waitForSpeech(sheetGuide, "Mitochondrion")
        capture(app, "Respiration - colorful key player and talking guide")
        app.buttons["respiration-players-done"].tap()
        XCTAssertEqual(guide.value as? String, "Quiet")
        let enlarge = app.buttons["Enlarge diagram"]
        reveal(enlarge, in: app)
        enlarge.tap()
        let speaker = app.buttons["narration-lesson.glycolysis"]
        XCTAssertTrue(speaker.waitForExistence(timeout: 3))
        speaker.tap()
        waitForSpeech(guide, "Split the sugar")
        app.buttons["respiration-diagram-card"].tap()
        app.collectionViews.buttons["Prepare the fuel"].tap()
        XCTAssertEqual(guide.value as? String, "Quiet")
        app.buttons["narration-lesson.transition"].tap()
        waitForSpeech(guide, "Prepare the fuel")
        app.buttons["Done"].tap()
        XCTAssertEqual(guide.value as? String, "Quiet")
    }
}
