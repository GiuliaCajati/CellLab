import XCTest

/// Captures real, reachable gameplay through normal controls; no injected game state.
final class AppStoreCaptureUITests: XCTestCase {
    @MainActor private func launchHome() -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["home-guide-listen"].waitForExistence(timeout: 15))
        return app
    }
    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<12 {
            if element.isHittable, element.frame.midY > 115, element.frame.midY < app.frame.maxY - 100 { return }
            let below = !element.exists || element.frame.midY > app.frame.midY
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: below ? 0.72 : 0.3))
            start.press(forDuration: 0.02, thenDragTo: start.withOffset(CGVector(dx: 0, dy: below ? -280 : 280)))
        }
        XCTAssertTrue(element.isHittable)
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let item = XCTAttachment(screenshot: app.screenshot())
        item.name = name; item.lifetime = .keepAlways; add(item)
    }
    @MainActor private func dump(_ app: XCUIApplication, _ name: String) {
        let item = XCTAttachment(string: app.debugDescription)
        item.name = name; item.lifetime = .keepAlways; add(item)
    }
    @MainActor func testCaptureAnimalCell() {
        let app = launchHome()
        app.buttons["home-lesson-structures"].tap()
        XCTAssertTrue(app.buttons["structures-listen"].waitForExistence(timeout: 8))
        capture(app, "animal-cell-nucleus")
        let mitochondria = app.buttons["Mitochondria"].firstMatch
        if mitochondria.exists && mitochondria.isHittable {
            mitochondria.tap()
        } else {
            let browse = app.buttons["structures-browse"]
            reveal(browse, in: app); browse.tap()
            let search = app.searchFields.firstMatch
            XCTAssertTrue(search.waitForExistence(timeout: 5))
            search.tap(); search.typeText("mitochondria")
            app.buttons["structure-browser-mitochondria"].tap()
            for _ in 0..<5 { app.swipeDown() }
        }
        XCTAssertTrue(app.staticTexts["structure-image-selection"].label.contains("Mitochondria"))
        capture(app, "animal-cell-mitochondria")
    }
    @MainActor func testCaptureMitosis() {
        let app = launchHome()
        let lesson = app.buttons["home-lesson-mitosis"]
        reveal(lesson, in: app); lesson.tap()
        XCTAssertTrue(app.buttons["mitosisListenButton"].waitForExistence(timeout: 8))
        app.buttons["mitosis-phase-metaphase"].tap()
        XCTAssertTrue(app.staticTexts["Metaphase"].firstMatch.waitForExistence(timeout: 5))
        capture(app, "mitosis-metaphase")
        app.buttons["mitosis-phase-anaphase"].tap()
        XCTAssertTrue(app.staticTexts["Anaphase"].firstMatch.waitForExistence(timeout: 5))
        capture(app, "mitosis-anaphase")
    }
    @MainActor func testCaptureAxolotlGuide() {
        let app = launchHome()
        let lesson = app.buttons["home-lesson-dogma"]
        reveal(lesson, in: app); lesson.tap()
        let guide = app.buttons["central-dogma-overview"]
        XCTAssertTrue(guide.waitForExistence(timeout: 8))
        app.collectionViews["central-dogma-carousel"].swipeLeft()
        XCTAssertTrue(app.staticTexts["Write the RNA"].waitForExistence(timeout: 5))
        let selected = app.buttons["central-dogma-step-transcriptionBuild"]
        XCTAssertEqual(selected.value as? String, "Selected")
        guide.tap()
        let speaking = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value CONTAINS[c] %@", "Speaking"), object: guide)
        XCTAssertEqual(XCTWaiter.wait(for: [speaking], timeout: 5), .completed)
        capture(app, "axolotl-central-dogma-speaking")
        guide.tap()
        XCTAssertEqual(guide.value as? String, "Quiet")
        capture(app, "axolotl-central-dogma-quiet")
    }
    @MainActor func testCaptureWidget() {
        let app = launchHome()
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        dump(springboard, "widget-initial-tree")
        // The current simulator's actual CellLab icon is visually verified on page two.
        // SpringBoard can expose duplicate offscreen icon elements, so prefer the visible one.
        let icons = springboard.icons.matching(NSPredicate(format: "label == %@", "CellLab")).allElementsBoundByIndex
        if let icon = icons.first(where: { $0.frame.width > 1 && $0.frame.midY > 0 && $0.frame.midY < springboard.frame.height * 0.8 }) {
            icon.press(forDuration: 1.4)
        } else {
            springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.666, dy: 0.255)).press(forDuration: 1.4)
        }
        dump(springboard, "widget-icon-menu-tree")
        XCTAssertTrue(springboard.buttons["Edit Home Screen"].waitForExistence(timeout: 5))
        springboard.buttons["Edit Home Screen"].tap()
        let edit = springboard.buttons["Edit"].firstMatch
        if edit.waitForExistence(timeout: 3) { edit.tap() }
        let addWidget = springboard.buttons["Add Widget"].firstMatch
        if addWidget.waitForExistence(timeout: 3) { addWidget.tap() }
        else { springboard.buttons["Add"].firstMatch.tap() }
        dump(springboard, "widget-gallery-tree")
        let search = springboard.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 6))
        search.tap(); search.typeText("CellLab")
        dump(springboard, "widget-search-tree")
        let result = springboard.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "CellLab")).firstMatch
        if result.waitForExistence(timeout: 5) { result.tap() }
        else { springboard.staticTexts["CellLab"].firstMatch.tap() }
        dump(springboard, "widget-configuration-tree")
        capture(springboard, "widget-configuration")
        let add = springboard.buttons["Add Widget"].firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 6))
        add.tap()
        let done = springboard.buttons["Done"].firstMatch
        if done.waitForExistence(timeout: 5) { done.tap() }
        capture(springboard, "daily-fact-home-screen")
        dump(springboard, "widget-home-tree")
        // Tap the real widget and verify its deep link returns to the main app.
        let widget = springboard.otherElements.matching(NSPredicate(format: "label CONTAINS[c] %@", "Daily Biology Fact")).firstMatch
        XCTAssertTrue(widget.waitForExistence(timeout: 5))
        widget.tap()
        XCTAssertTrue(app.buttons["celllab-settings"].waitForExistence(timeout: 10))
        capture(app, "widget-opens-celllab")
    }
    @MainActor func testCaptureQuickWidget() {
        let app = launchHome()
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        // Capture-only automation: SpringBoard's menu animation never becomes idle.
        // These XCTest interaction flags skip its pre/post animation-idle waits.
        // This helper lives outside all shipping targets.
        springboard.setValue(3, forKey: "currentInteractionOptions")
        defer { springboard.setValue(0, forKey: "currentInteractionOptions") }
        let icons = springboard.icons.matching(NSPredicate(format: "label == %@", "CellLab")).allElementsBoundByIndex
        guard let icon = icons.first(where: { $0.frame.width > 1 && $0.frame.midY > 0 && $0.frame.midY < springboard.frame.height * 0.8 }) else {
            dump(springboard, "quick-widget-missing-icon"); XCTFail("CellLab icon not visible"); return
        }
        springboard.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: icon.frame.midX, dy: icon.frame.midY)).press(forDuration: 1.3)
        let medium = springboard.buttons["Medium-sized widget"]
        XCTAssertTrue(medium.waitForExistence(timeout: 5))
        medium.tap()
        let done = springboard.buttons["Done"].firstMatch
        if done.waitForExistence(timeout: 3) { done.tap() }
        dump(springboard, "quick-widget-home-tree")
        let fact = springboard.staticTexts["CellLab · Today’s Fact"].firstMatch
        XCTAssertTrue(fact.waitForExistence(timeout: 15))
        capture(springboard, "daily-fact-home-screen")
        fact.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["celllab-settings"].waitForExistence(timeout: 10))
        capture(app, "widget-opens-celllab")
    }
    @MainActor func testCaptureSmallWidget() {
        let app = launchHome()
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.setValue(3, forKey: "currentInteractionOptions")
        defer { springboard.setValue(0, forKey: "currentInteractionOptions") }
        let icons = springboard.icons.matching(NSPredicate(format: "label == %@", "CellLab")).allElementsBoundByIndex
        guard let icon = icons.first(where: { $0.frame.width > 1 && $0.frame.midY > 0 && $0.frame.midY < springboard.frame.height * 0.8 }) else { XCTFail("CellLab widget not visible"); return }
        springboard.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: icon.frame.midX, dy: icon.frame.midY)).press(forDuration: 1.3)
        let small = springboard.buttons["Small widget"]
        XCTAssertTrue(small.waitForExistence(timeout: 5)); small.tap()
        let done = springboard.buttons["Done"].firstMatch
        if done.waitForExistence(timeout: 2) { done.tap() }
        let fact = springboard.staticTexts["A sea slug can steal a sting."].firstMatch
        XCTAssertTrue(fact.waitForExistence(timeout: 12))
        capture(springboard, "daily-fact-small-home-screen")
        dump(springboard, "small-widget-home-tree")
        fact.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["celllab-settings"].waitForExistence(timeout: 10))
    }
    @MainActor func testCaptureDNAReplicationOpening() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()
        let play = app.buttons["home-play-sphase"]
        XCTAssertTrue(app.buttons["home-guide-listen"].waitForExistence(timeout: 20))
        for _ in 0..<8 {
            if play.isHittable && play.frame.midY < app.frame.maxY - 110 { break }
            app.swipeUp()
        }
        XCTAssertTrue(play.isHittable)
        play.tap()
        let origin = app.buttons["Origin of replication"].firstMatch
        XCTAssertTrue(origin.waitForExistence(timeout: 8))
        origin.tap()
        func advance() {
            let next = app.buttons["dna-game-continue"]
            XCTAssertTrue(next.waitForExistence(timeout: 8))
            next.tap()
        }
        func tool(_ id: String) {
            let tray = app.scrollViews["dna-game-tools"]
            let button = app.buttons["dna-game-tool-\(id)"]
            for _ in 0..<6 where !button.isHittable { tray.swipeLeft() }
            for _ in 0..<6 where !button.isHittable { tray.swipeRight() }
            XCTAssertTrue(button.isHittable)
            button.tap()
        }
        func apply() {
            let action = app.buttons["dna-game-apply-selection"]
            XCTAssertTrue(action.isEnabled)
            action.tap()
        }
        func selectMatchingBase() -> String {
            let target = app.buttons["dna-game-target"].firstMatch
            XCTAssertTrue(target.exists)
            let base = String(target.label.suffix(1))
            XCTAssertTrue(["A", "T", "C", "G"].contains(base))
            let button = app.buttons.matching(NSPredicate(format: "label == %@", "\(base) DNA nucleotide"))
                .allElementsBoundByIndex.first { $0.isHittable }
            XCTAssertNotNil(button)
            button?.tap()
            return base
        }
        func capture(_ name: String) {
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        advance()
        tool("helicase"); apply(); advance()
        tool("binding")
        for _ in 0..<3 { apply() }
        advance()
        tool("primase"); apply(); advance()
        tool("polymerase"); apply()
        _ = selectMatchingBase(); apply()
        capture("DNA-replication-one-base-built")
        let nextBase = selectMatchingBase()
        XCTAssertEqual(app.buttons["dna-game-apply-selection"].label, "Attach \(nextBase)")
        capture("DNA-replication-next-base-selected")
        apply(); advance() // A simulated mismatch appears after this correct pair.
        tool("polymerase"); apply() // Proofread and remove the mismatch.
        _ = selectMatchingBase(); apply(); advance()
        _ = selectMatchingBase(); apply()
        let laterBase = selectMatchingBase()
        XCTAssertEqual(app.buttons["dna-game-apply-selection"].label, "Attach \(laterBase)")
        capture("DNA-replication-four-bases-next-selected")
    }
}
