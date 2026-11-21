import XCTest

final class HomeGuideUITests: XCTestCase {
    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<24 {
            let bar = app.navigationBars.firstMatch
            let top = bar.exists ? bar.frame.maxY + 6 : app.frame.minY + 45
            let tab = app.buttons["home-guide-listen"]
            let bottom = tab.isHittable ? tab.frame.minY : app.frame.maxY - 30
            if element.isHittable, element.frame.midY > top, element.frame.midY < bottom { return }
            let below = !element.exists || element.frame.midY > app.frame.midY
            let distance = element.exists ? min(max(abs(element.frame.midY - app.frame.midY), 90), app.frame.height * 0.42)
                : app.frame.height * 0.42
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: below ? 0.70 : 0.32))
            start.press(forDuration: 0.01, thenDragTo: start.withOffset(CGVector(dx: 0, dy: below ? -distance : distance)),
                        withVelocity: .slow, thenHoldForDuration: 0.05)
        }
        XCTAssertTrue(element.isHittable)
    }
    @MainActor private func launch() -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["home-guide-listen"].waitForExistence(timeout: 10))
        return app
    }
    @MainActor private func waitFor(_ element: XCUIElement, _ value: String) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value CONTAINS[cd] %@", value), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor func testInlineWelcomePreviewsHideStopBackgroundAndOpenLesson() {
        let app = launch()
        let guide = app.buttons["home-guide-listen"]
        waitFor(guide, "Quiet")
        capture(app, "Main CellLab page with talking axolotl control")
        guide.tap()
        waitFor(guide, "Speaking Welcome to CellLab")
        XCTAssertFalse(app.buttons["home-guide-done"].exists)
        XCTAssertTrue(app.buttons["home-lesson-structures"].exists)
        capture(app, "Welcome plays directly on CellLab")
        guide.tap()
        waitFor(guide, "Quiet")

        let mitosis = app.buttons["home-preview-mitosis"]
        reveal(mitosis, in: app)
        mitosis.tap()
        waitFor(guide, "Speaking Mitosis")
        XCTAssertTrue(app.buttons["home-lesson-mitosis"].exists)
        XCTAssertFalse(app.buttons["mitosisPlayButton"].exists)
        let hide = app.buttons["home-hide-mitosis"]
        reveal(hide, in: app)
        capture(app, "Mitosis explanation and game preview inline on home")
        XCUIDevice.shared.press(.home)
        app.activate()
        waitFor(guide, "Quiet")
        reveal(mitosis, in: app)
        mitosis.tap()
        waitFor(guide, "Speaking Mitosis")
        mitosis.tap()
        waitFor(guide, "Quiet")
        XCTAssertTrue(hide.exists)
        mitosis.tap()
        waitFor(guide, "Speaking Mitosis")
        reveal(hide, in: app)
        hide.tap()
        XCTAssertFalse(hide.exists)
        waitFor(guide, "Quiet")

        let cycle = app.buttons["home-preview-cycle"]
        reveal(cycle, in: app)
        cycle.tap()
        waitFor(guide, "Speaking Cell Life Cycle")
        XCTAssertFalse(app.buttons["home-hide-mitosis"].exists)
        let cycleCard = app.buttons["home-lesson-cycle"]
        reveal(cycleCard, in: app)
        cycleCard.tap()
        let cycleGuide = app.buttons["cycle-listen"]
        XCTAssertTrue(cycleGuide.waitForExistence(timeout: 5))
        waitFor(cycleGuide, "Quiet")
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label == %@", "Play game")).firstMatch.exists)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        waitFor(guide, "Quiet")
        guide.tap()
        waitFor(guide, "Speaking Welcome to CellLab")
        XCTAssertFalse(app.buttons["home-hide-cycle"].exists)
        guide.tap()
        waitFor(guide, "Quiet")
    }

    @MainActor func testGameBadgesMatchReachableGamesAndOtherLessonsStayUnmarked() {
        let app = launch()
        let modules: [(String, String?)] = [
            ("structures", nil), ("cycle", nil), ("mitosis", "mitosisPlayButton"),
            ("meiosis", "meiosisPlayButton"), ("sphase", "dna-play-game"),
            ("dogma", "central-dogma-play-game"), ("respiration", nil), ("technology", nil)
        ]
        for (id, playID) in modules {
            let card = app.buttons["home-lesson-\(id)"]
            reveal(card, in: app)
            XCTAssertEqual(card.value as? String, playID == nil ? "Lesson" : "Game included", id)
            if let playID {
                if id == "mitosis" { capture(app, "Home game badges") }
                card.tap()
                XCTAssertTrue(app.buttons[playID].waitForExistence(timeout: 5), id)
                app.navigationBars.buttons.firstMatch.tap()
                XCTAssertTrue(app.buttons["home-guide-listen"].waitForExistence(timeout: 5))
            }
        }
        capture(app, "Home final lessons reachable above axolotl")
    }

    @MainActor func testGameBadgeShortcutsOpenGamesWithWorkingAudioAndReturnQuietly() {
        let app = launch()
        let homeGuide = app.buttons["home-guide-listen"]
        let games = [("mitosis", "mitosisGameListenButton"), ("meiosis", "meiosisGameListenButton"),
                     ("sphase", "sphaseGameListenButton"), ("dogma", "central-dogma-game-introduction-listen")]
        for (id, guideID) in games {
            let preview = app.buttons["home-preview-\(id)"]
            reveal(preview, in: app)
            preview.tap()
            waitFor(homeGuide, "Speaking")
            let play = app.buttons["home-play-\(id)"]
            reveal(play, in: app)
            play.tap()
            let gameGuide = app.buttons[guideID]
            XCTAssertTrue(gameGuide.waitForExistence(timeout: 5), id)
            waitFor(gameGuide, "Quiet")
            gameGuide.tap()
            waitFor(gameGuide, "Speaking")
            capture(app, "Direct \(id) game with its own audio guide")
            if id == "sphase" { app.buttons["Back to CellLab"].tap() }
            else { app.navigationBars.buttons.firstMatch.tap() }
            XCTAssertTrue(homeGuide.waitForExistence(timeout: 5))
            waitFor(homeGuide, "Quiet")
        }
        for id in ["structures", "cycle", "respiration", "technology"] {
            XCTAssertFalse(app.buttons["home-play-\(id)"].exists)
        }
    }
}
