import XCTest

final class DNATechnologyNarrationUITests: XCTestCase {
    @MainActor private func reveal(_ element:XCUIElement,in app:XCUIApplication) {
        for _ in 0..<22 {
            let bar = app.navigationBars.firstMatch
            let top = bar.exists ? bar.frame.maxY + 6 : app.frame.minY + 45
            if element.isHittable,element.frame.midY > top,element.frame.midY < app.frame.maxY - 20 { return }
            let below = !element.exists || element.frame.midY > app.frame.midY
            let distance = element.exists ? min(max(abs(element.frame.midY - app.frame.midY),80),app.frame.height * 0.45)
                : app.frame.height * 0.45
            let start = app.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:below ? 0.72 : 0.3))
            start.press(forDuration:0.01,thenDragTo:start.withOffset(CGVector(dx:0,dy:below ? -distance : distance)),
                        withVelocity:.slow,thenHoldForDuration:0.05)
        }
        XCTAssertTrue(element.isHittable)
    }
    @MainActor private func openLesson() -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()
        let module = app.buttons.matching(NSPredicate(format:"label BEGINSWITH %@","DNA Technology,")).firstMatch
        XCTAssertTrue(module.waitForExistence(timeout:8))
        reveal(module,in:app)
        module.tap()
        XCTAssertTrue(app.buttons["dna-listen"].waitForExistence(timeout:5))
        return app
    }
    @MainActor private func waitFor(_ guide:XCUIElement,_ value:String) {
        let expectation = XCTNSPredicateExpectation(predicate:NSPredicate(format:"value CONTAINS[cd] %@",value),object:guide)
        XCTAssertEqual(XCTWaiter.wait(for:[expectation],timeout:5),.completed)
    }
    @MainActor private func capture(_ app:XCUIApplication,_ name:String) {
        let attachment = XCTAttachment(screenshot:app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor func testOpeningSelectedStagesTopicsStopAndBackground() {
        let app = openLesson()
        let guide = app.buttons["dna-listen"]
        let prime = app.buttons["dna-stage-prime"]
        reveal(prime,in:app)
        prime.tap()
        reveal(guide,in:app)
        XCTAssertEqual(guide.label,"Hear dna technology overview")
        guide.tap()
        waitFor(guide,"Opening")
        capture(app,"DNA Technology talking axolotl")
        let extend = app.buttons["dna-stage-extend"]
        reveal(extend,in:app)
        extend.tap()
        waitFor(guide,"Extend")
        let nextTopic = app.buttons["dna-next-topic"]
        reveal(nextTopic,in:app)
        nextTopic.tap()
        waitFor(guide,"CRISPR-Cas9")
        let repair = app.buttons["dna-stage-repair"]
        reveal(repair,in:app)
        repair.tap()
        waitFor(guide,"Repair")
        reveal(guide,in:app)
        guide.tap()
        waitFor(guide,"Quiet")
        let cut = app.buttons["dna-stage-cut"]
        reveal(cut,in:app)
        cut.tap()
        waitFor(guide,"Quiet")
        reveal(guide,in:app)
        guide.tap()
        waitFor(guide,"Cut")
        XCUIDevice.shared.press(.home)
        app.activate()
        waitFor(guide,"Quiet")
        app.navigationBars.buttons.firstMatch.tap()
        let module = app.buttons.matching(NSPredicate(format:"label BEGINSWITH %@","DNA Technology,")).firstMatch
        reveal(module,in:app)
        module.tap()
        XCTAssertTrue(guide.waitForExistence(timeout:3))
        waitFor(guide,"Quiet")
    }

    @MainActor func testCounterTermLinksSearchAndReturnToTopic() {
        let app = openLesson()
        let guide = app.buttons["dna-listen"]
        let counter = app.buttons["narration-reference.pcr-counter"]
        reveal(counter,in:app)
        counter.tap()
        waitFor(guide,"PCR counter")
        let cycle = app.buttons["dna-pcr-add-cycle"]
        reveal(cycle,in:app)
        cycle.tap()
        XCTAssertEqual(app.staticTexts["dna-pcr-copies"].label.filter(\.isNumber),"2097152")
        let pcr = app.buttons["dna-term-pcr"]
        reveal(pcr,in:app)
        pcr.tap()
        let definition = app.buttons["dna-term-listen"]
        XCTAssertTrue(definition.waitForExistence(timeout:3))
        XCTAssertEqual(definition.value as? String,"Quiet")
        definition.tap()
        waitFor(definition,"PCR")
        capture(app,"DNA Technology definition guide")
        let explore = app.buttons["dna-explore-term-topic"]
        reveal(explore,in:app)
        explore.tap()
        waitFor(guide,"Quiet")
        let tools = app.buttons["dna-open-tools"]
        reveal(tools,in:app)
        tools.tap()
        let toolsGuide = app.buttons["dna-tools-listen"]
        XCTAssertTrue(toolsGuide.waitForExistence(timeout:3))
        toolsGuide.tap()
        waitFor(toolsGuide,"Meet the tools")
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout:3))
        search.tap()
        search.typeText("ligase")
        waitFor(toolsGuide,"Quiet")
        let ligase = app.buttons["dna-tool-ligase"]
        XCTAssertTrue(ligase.waitForExistence(timeout:3))
        ligase.tap()
        XCTAssertTrue(definition.waitForExistence(timeout:3))
        definition.tap()
        waitFor(definition,"DNA ligase")
        XCUIDevice.shared.press(.home)
        app.activate()
        waitFor(definition,"Quiet")
        reveal(explore,in:app)
        explore.tap()
        XCTAssertEqual(app.staticTexts["dna-topic-title"].label,"Recombinant DNA")
        waitFor(guide,"Quiet")
    }

    @MainActor func testDirectStepAudioAndDefinitionGuideAtCurrentTextSize() {
        let app = openLesson()
        let guide = app.buttons["dna-listen"]
        let speaker = app.buttons["narration-lesson.pcr.heat"]
        reveal(speaker,in:app)
        speaker.tap()
        waitFor(guide,"Heat")
        let prime = app.buttons["dna-stage-prime"]
        reveal(prime,in:app)
        prime.tap()
        waitFor(guide,"Quiet")
        let primer = app.buttons["dna-term-primer"]
        reveal(primer,in:app)
        primer.tap()
        let definition = app.buttons["dna-term-listen"]
        XCTAssertTrue(definition.waitForExistence(timeout:3))
        reveal(definition,in:app)
        definition.tap()
        waitFor(definition,"Primer")
        capture(app,"DNA Technology definition guide with larger text")
        definition.tap()
        waitFor(definition,"Quiet")
        app.buttons["dna-tools-done"].tap()
        reveal(guide,in:app)
        XCTAssertEqual(guide.label,"Hear dna technology overview")
        guide.tap()
        waitFor(guide,"Opening")
        capture(app,"DNA Technology overview guide with larger text")
        guide.tap()
        waitFor(guide,"Quiet")
    }
}
