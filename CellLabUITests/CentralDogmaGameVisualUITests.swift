import XCTest

final class CentralDogmaGameVisualUITests: XCTestCase {
    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication,
                                   file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<14 {
            let dock = app.otherElements["rna-relay-tool-dock"]
            let bottom = dock.exists ? dock.frame.minY - 8 : app.frame.maxY - 12
            let bar = app.navigationBars.firstMatch
            let top = bar.exists ? bar.frame.maxY + 8 : app.frame.minY + 50
            if element.isHittable, element.frame.midY > top,
               element.frame.midY < bottom { return }
            let below = !element.exists || element.frame.midY > app.frame.midY
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: below ? 0.63 : 0.28))
            start.press(forDuration: 0.01, thenDragTo: start.withOffset(CGVector(dx: 0, dy: below ? -140 : 140)),
                        withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        XCTAssertTrue(element.isHittable, file: file, line: line)
    }
    @MainActor private func openGame() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let module = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Central Dogma,")).firstMatch
        XCTAssertTrue(module.waitForExistence(timeout: 8))
        reveal(module, in: app)
        module.tap()
        let play = app.buttons["central-dogma-play-game"]
        XCTAssertTrue(play.waitForExistence(timeout: 5))
        reveal(play, in: app)
        play.tap()
        let start = app.buttons["Let’s make a message"]
        XCTAssertTrue(start.waitForExistence(timeout: 4))
        reveal(start, in: app)
        start.tap()
        XCTAssertTrue(app.otherElements["rna-relay-board"].waitForExistence(timeout: 4))
        return app
    }
    @MainActor private func act(_ step: String, _ payload: String?, _ target: String,
                               automatic: String? = nil, in app: XCUIApplication) {
        if let payload {
            let tool = app.buttons["rna-tool-\(payload)"]
            XCTAssertTrue(tool.waitForExistence(timeout: 3), payload)
            XCTAssertTrue(tool.isHittable, "Tool dock must remain reachable: \(payload)")
            tool.tap()
        }
        if !step.hasPrefix("rna-") {
            let spot = app.buttons["rna-target-\(step)-\(target)-\(automatic ?? "drop")"]
            XCTAssertTrue(spot.waitForExistence(timeout: 3), step)
            reveal(spot, in: app)
            spot.tap()
        }
        let keepGoing = app.buttons["Keep going"]
        if keepGoing.exists { keepGoing.tap() }
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
    }
    @MainActor private func startCopying(in app: XCUIApplication) {
        act("factors", "tool:factors", "dna:promoter", in: app)
        act("polymerase", "tool:polymerase", "dna:promoter", in: app)
        act("open", nil, "enzyme:polymerase", automatic: "action:open", in: app)
    }

    @MainActor func testRNAControlsStayVisibleAtCurrentScreenSize() {
        let app = openGame()
        capture(app, "DNA inside the nucleus with a permanent tool dock")
        startCopying(in: app)
        for base in ["A", "U", "C", "G"] {
            XCTAssertTrue(app.buttons["rna-tool-rna:\(base)"].isHittable)
        }
        let guide = app.buttons["central-dogma-game-listen"]
        reveal(guide, in: app)
        guide.tap()
        let speaking = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value BEGINSWITH %@", "Speaking"), object: guide)
        XCTAssertEqual(XCTWaiter.wait(for: [speaking], timeout: 3), .completed)
        guide.tap()
        capture(app, "DNA template and growing RNA use recognizable molecular shapes")
        app.buttons["rna-tool-rna:U"].tap()
        XCTAssertTrue(app.buttons["rna-target-rna-0-rna:0-drop"].exists)
        act("rna-0", "rna:A", "rna:0", in: app)
        XCTAssertTrue(app.buttons["rna-target-rna-1-rna:1-drop"].waitForExistence(timeout: 3))
    }

    @MainActor func testMessageLeavesNucleusAndRibosomeBuildsChain() {
        let app = openGame()
        startCopying(in: app)
        let pair: [Character: String] = ["A": "U", "T": "A", "G": "C", "C": "G"]
        for (i, base) in "TACGCAGTACTACATT".enumerated() {
            act("rna-\(i)", "rna:\(pair[base]!)", "rna:\(i)", in: app)
        }
        act("terminate", nil, "dna:terminator", in: app)
        act("cap", "tool:cap", "rna:end5", in: app)
        act("tail", "tool:tail", "rna:end3", in: app)
        act("splice", "tool:splice", "region:intron", in: app)
        act("join", nil, "rna:join", automatic: "action:join", in: app)
        act("export", "rna:mature", "nucleus:exit", in: app)
        let journey = app.otherElements["rna-relay-stage"]
        XCTAssertTrue((journey.value as? String)?.contains("Cytoplasm") == true)
        reveal(journey, in: app)
        capture(app, "The mRNA leaves the nucleus and reaches the ribosome")
        act("small", "ribosome:small", "rna:end5", in: app)
        act("initiator", "trna:UAC", "codon:0", in: app)
        act("large", "ribosome:large", "ribosome:assembly", in: app)
        for i in 1...2 {
            act("deliver-\(i)", "trna:UAC", "codon:\(i)", in: app)
            act("bond-\(i)", nil, "protein:bond", automatic: "action:bond", in: app)
            XCTAssertTrue((journey.value as? String)?.contains("\(i + 1) amino acids") == true)
            if i == 2 {
                reveal(journey, in: app)
                capture(app, "Three amino acids join as the ribosome reads mRNA")
            }
            act("move-\(i)", nil, "ribosome:move", automatic: "move:5to3", in: app)
            act("recycle-\(i)", "trna:empty", "cytosol:recycle", in: app)
        }
        act("release", "factor:release", "codon:3", in: app)
        act("fold", "protein:chaperone", "protein:fold", in: app)
        act("cleave", "protein:cleavage", "protein:cleave", in: app)
        for i in 0..<4 { act("assemble-\(i)", "subunit:\(i)", "hemoglobin:\(i)", in: app) }
        app.buttons["See my results"].tap()
        XCTAssertTrue(app.staticTexts["Message delivered!"].waitForExistence(timeout: 3))
    }
}
