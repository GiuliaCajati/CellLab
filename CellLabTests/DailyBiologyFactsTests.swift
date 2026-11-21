import CryptoKit
import UserNotifications
import XCTest
@testable import CellLab

@MainActor private final class FactNotificationMock: DailyFactNotificationClient {
    var status: DailyFactPermission = .notDetermined
    var answer: DailyFactPermission = .allowed
    var permissionRequests = 0
    var items: [String: PendingFactNotification] = [:]
    var added: [DailyFactAlert] = []
    var removed: [String] = []
    var suspendNextAdd = false
    var addGate: CheckedContinuation<Void, Never>?
    nonisolated deinit {}

    func permission() async -> DailyFactPermission { status }
    func requestPermission() async throws -> Bool {
        permissionRequests += 1
        status = answer
        return status == .allowed
    }
    func pending() async -> [PendingFactNotification] { Array(items.values) }
    func add(_ alert: DailyFactAlert) async throws {
        if suspendNextAdd {
            suspendNextAdd = false
            await withCheckedContinuation { addGate = $0 }
        }
        added.append(alert)
        items[alert.identifier] = PendingFactNotification(identifier: alert.identifier, body: alert.body,
                                                         factID: alert.fact.id, components: alert.components)
    }
    func remove(identifiers: [String]) async {
        removed += identifiers
        for id in identifiers { items[id] = nil }
    }
}

@MainActor final class DailyBiologyFactsTests: XCTestCase {
    private let ny = TimeZone(identifier: "America/New_York")!
    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 8, _ minute: Int = 0,
                      zone: TimeZone? = nil) -> Date {
        DailyFactCalendar.calendar(in: zone ?? ny).date(from: DateComponents(year: year, month: month, day: day,
                                                                           hour: hour, minute: minute))!
    }
    private func defaults() -> UserDefaults {
        let name = "CellLab.FactTests.\(UUID().uuidString)"
        addTeardownBlock { UserDefaults(suiteName: name)?.removePersistentDomain(forName: name) }
        return UserDefaults(suiteName: name)!
    }
    private func catalog() throws -> BiologyFactCatalog { try .load() }
    private func service(_ mock: FactNotificationMock, storage: UserDefaults? = nil,
                         clock: @escaping () -> Date) throws -> DailyFactReminders {
        DailyFactReminders(catalog: try catalog(), client: mock, defaults: storage ?? defaults(), now: clock,
                           timeZone: { TimeZone(identifier: "America/New_York")! })
    }

    func testAll69OriginalFactsAndSourcesAreByteIdenticalInBothBundles() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "daily-facts", withExtension: "json"))
        let data = try Data(contentsOf: url)
        XCTAssertEqual(SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined(),
                       "c5897c3cd6c45a0c73cb4a9cf9ee26fb226bafb3be0d2ee2b6865a17db3f44e3")
        let facts = try BiologyFactCatalog(data: data)
        XCTAssertEqual(facts.facts.map(\.id), BiologyFactCatalog.stableIDs)
        XCTAssertEqual(Set(facts.facts.map(\.id)).count, 69)
        let plugin = try XCTUnwrap(Bundle.main.builtInPlugInsURL).appendingPathComponent("CellLabDailyFactsWidget.appex")
        let widgetBundle = try XCTUnwrap(Bundle(url: plugin))
        let widgetURL = try XCTUnwrap(widgetBundle.url(forResource: "daily-facts", withExtension: "json"))
        XCTAssertEqual(try Data(contentsOf: widgetURL), data)
        XCTAssertEqual(try BiologyFactCatalog.load(bundle: widgetBundle).facts, facts.facts)
        for fact in facts.facts {
            XCTAssertEqual(DailyFactIdentity.factID(from: fact.deepLink), fact.id)
            XCTAssertFalse(fact.sources.isEmpty)
            XCTAssertTrue(fact.sources.allSatisfy { ["http", "https"].contains($0.url.scheme ?? "") })
        }
    }

    func testGregorianAnchorNegativeModuloCycleWrapAndRestarts() throws {
        let facts = try catalog()
        XCTAssertEqual(facts.fact(on: date(2024, 1, 1), timeZone: ny).id, "fact-001")
        XCTAssertEqual(facts.fact(on: date(2023, 12, 31), timeZone: ny).id, "fact-069")
        let calendar = DailyFactCalendar.calendar(in: ny)
        for offset in [-139, -69, -1, 0, 1, 68, 69, 138, 1000] {
            let day = calendar.date(byAdding: .day, value: offset, to: date(2024, 1, 1))!
            let index = ((offset % 69) + 69) % 69
            XCTAssertEqual(facts.fact(on: day, timeZone: ny).id, BiologyFactCatalog.stableIDs[index])
            XCTAssertEqual(try catalog().fact(on: day, timeZone: ny), facts.fact(on: day, timeZone: ny))
        }
        let utc = TimeZone(secondsFromGMT: 0)!
        let sameInstant = date(2024, 1, 1, 2, zone: utc)
        XCTAssertEqual(facts.fact(on: sameInstant, timeZone: utc).id, "fact-001")
        XCTAssertEqual(facts.fact(on: sameInstant, timeZone: ny).id, "fact-069")
    }

    func testDSTYearBoundariesAndWidgetMidnightsAdvanceOneCivilDay() throws {
        let facts = try catalog()
        for start in [date(2024, 3, 9), date(2024, 11, 2), date(2024, 12, 31)] {
            let entries = DailyFactTimeline.entries(catalog: facts, now: start, timeZone: ny)
            XCTAssertEqual(entries.count, 8)
            for (index, entry) in entries.enumerated() {
                XCTAssertEqual(entry.fact.id, BiologyFactCatalog.stableIDs[(DailyFactCalendar.index(on: start, timeZone: ny) + index) % 69])
                if index > 0 {
                    XCTAssertEqual(DailyFactCalendar.calendar(in: ny).component(.hour, from: entry.date), 0)
                    XCTAssertGreaterThan(entry.date, entries[index - 1].date)
                }
            }
        }
        let calendar = DailyFactCalendar.calendar(in: ny)
        let spring = DailyFactTimeline.entries(catalog: facts, now: date(2024, 3, 9), timeZone: ny)
        XCTAssertEqual(calendar.dateComponents([.hour], from: spring[1].date, to: spring[2].date).hour, 23)
        let fall = DailyFactTimeline.entries(catalog: facts, now: date(2024, 11, 2), timeZone: ny)
        XCTAssertEqual(calendar.dateComponents([.hour], from: fall[1].date, to: fall[2].date).hour, 25)
    }

    func testAppWidgetAndNotificationAgreeAndWidgetLinkOpensHome() throws {
        let facts = try catalog()
        let today = date(2024, 3, 10)
        let appFact = facts.fact(on: today, timeZone: ny)
        let widget = DailyFactTimeline.entries(catalog: facts, now: today, timeZone: ny)[0]
        let alert = try XCTUnwrap(DailyFactReminderPlan.alerts(catalog: facts, now: today, timeZone: ny,
                                                            time: .morning, availableCapacity: 64).first)
        XCTAssertEqual(appFact, widget.fact)
        XCTAssertEqual(widget.fact, alert.fact)
        XCTAssertEqual(alert.body, appFact.widgetText)
        XCTAssertEqual(DailyFactIdentity.factID(from: alert.payload), appFact.id)
        XCTAssertEqual(alert.payload[DailyFactIdentity.urlKey], DailyFactIdentity.homeURL.absoluteString)
        let yesterday = facts.fact(on: date(2024, 3, 9), timeZone: ny)
        let router = DailyFactRouter()
        router.open(yesterday.deepLink) // Stored before the UI/cold-launch loading completes.
        XCTAssertEqual(router.request?.factID, yesterday.id)
        XCTAssertNotEqual(router.request?.factID, appFact.id)
        router.open(notificationPayload: [DailyFactIdentity.factIDKey: yesterday.id])
        XCTAssertEqual(router.request?.factID, yesterday.id)
        let previousToken = router.request?.token
        router.open(yesterday.deepLink)
        XCTAssertNotEqual(previousToken, router.request?.token)
        router.open(DailyFactIdentity.homeURL)
        XCTAssertNotNil(router.request)
        XCTAssertNil(router.request?.factID)
        XCTAssertTrue(DailyFactIdentity.isHomeURL(URL(string: "celllab://")!))
        XCTAssertFalse(DailyFactIdentity.isHomeURL(URL(string: "https://home")!))
        for bad in ["https://fact/fact-001", "celllab://fact/fact-999", "celllab://fact/fact-001/other"] {
            XCTAssertNil(DailyFactIdentity.factID(from: URL(string: bad)!))
        }
    }

    func testPlanUsesOnlyFutureDatesCapacityAndDSTGapAndOverlap() throws {
        let facts = try catalog()
        let now = date(2024, 3, 9, 10)
        let alerts = DailyFactReminderPlan.alerts(catalog: facts, now: now, timeZone: ny, time: .morning, availableCapacity: 64)
        XCTAssertEqual(alerts.count, 30)
        XCTAssertEqual(Set(alerts.map(\.identifier)).count, 30)
        XCTAssertTrue(alerts.allSatisfy { $0.fireDate > now })
        XCTAssertTrue(alerts[0].identifier.hasSuffix("2024-03-10"))
        XCTAssertEqual(DailyFactReminderPlan.alerts(catalog: facts, now: now, timeZone: ny, time: .morning, availableCapacity: 2).count, 2)
        XCTAssertTrue(DailyFactReminderPlan.alerts(catalog: facts, now: now, timeZone: ny, time: .morning, availableCapacity: 0).isEmpty)
        let spring = DailyFactReminderPlan.alerts(catalog: facts, now: date(2024, 3, 10, 0), timeZone: ny,
                                                  time: .init(hour: 2, minute: 30), availableCapacity: 1)[0]
        XCTAssertEqual(spring.components.hour, 3)
        XCTAssertEqual(spring.components.minute, 30)
        let midnight = DailyFactReminderPlan.alerts(catalog: facts, now: now, timeZone: ny,
                                                    time: .init(hour: 0, minute: 0), availableCapacity: 1)[0]
        XCTAssertEqual(midnight.components.hour, 0)
        XCTAssertEqual(midnight.components.minute, 0)
        let fall = DailyFactReminderPlan.alerts(catalog: facts, now: date(2024, 11, 3, 0), timeZone: ny,
                                                time: .init(hour: 1, minute: 30), availableCapacity: 30)
        XCTAssertEqual(Set(fall.map(\.identifier)).count, 30)
        XCTAssertTrue(fall.allSatisfy { $0.components.calendar?.identifier == .gregorian && $0.components.timeZone == nil })
    }

    func testDefaultOffNeverPromptsAndOptOutCancelsOnlyOwnRequests() async throws {
        let mock = FactNotificationMock()
        mock.items["other.feature"] = PendingFactNotification(identifier: "other.feature")
        let oldID = DailyFactIdentity.notificationPrefix + "old"
        mock.items[oldID] = PendingFactNotification(identifier: oldID)
        let now = date(2024, 3, 9)
        let reminders = try service(mock, clock: { now })
        XCTAssertFalse(reminders.enabled)
        XCTAssertEqual(reminders.time, .morning)
        await reminders.reconcile()
        XCTAssertEqual(mock.permissionRequests, 0)
        XCTAssertEqual(Set(mock.items.keys), ["other.feature"])
        await reminders.setEnabled(true)
        XCTAssertEqual(mock.permissionRequests, 1)
        XCTAssertEqual(reminders.scheduledCount, 30)
        await reminders.setEnabled(false)
        XCTAssertFalse(reminders.enabled)
        XCTAssertEqual(reminders.scheduledCount, 0)
        XCTAssertEqual(Set(mock.items.keys), ["other.feature"])
        XCTAssertFalse(mock.removed.contains("other.feature"))
    }

    func testActualSystemCalendarTriggersMatchPlannedFutureDates() throws {
        let now = Date()
        let alerts = DailyFactReminderPlan.alerts(catalog: try catalog(), now: now, time: .morning, availableCapacity: 30)
        XCTAssertEqual(alerts.count, 30)
        for alert in alerts {
            let trigger = UNCalendarNotificationTrigger(dateMatching: alert.components, repeats: false)
            XCTAssertFalse(trigger.repeats)
            XCTAssertEqual(trigger.nextTriggerDate(), alert.fireDate, alert.identifier)
        }
    }

    func testTimeZoneAndClockChangesRebuildTheWindowWithoutPrompting() async throws {
        let mock = FactNotificationMock()
        mock.status = .allowed
        var now = date(2024, 1, 10)
        var zone = ny
        let reminders = DailyFactReminders(catalog: try catalog(), client: mock, defaults: defaults(),
                                          now: { now }, timeZone: { zone })
        await reminders.setEnabled(true)
        XCTAssertTrue(mock.items.keys.contains(where: { $0.hasSuffix("2024-01-10") }))
        zone = TimeZone(identifier: "Asia/Tokyo")! // Same instant, now past 9 AM locally.
        await reminders.reconcile()
        XCTAssertFalse(mock.items.keys.contains(where: { $0.hasSuffix("2024-01-10") }))
        XCTAssertEqual(mock.items.count, 30)
        now = date(2024, 1, 9)
        let before = mock.added.count
        await reminders.reconcile()
        XCTAssertTrue(mock.items.keys.contains(where: { $0.hasSuffix("2024-01-10") }))
        XCTAssertTrue(mock.added.dropFirst(before).allSatisfy { $0.fireDate > now })
        XCTAssertEqual(mock.permissionRequests, 0)
    }

    func testDenialKeepsSwitchOffAndAuthorizationIsOnlyRequestedInContext() async throws {
        let mock = FactNotificationMock()
        mock.answer = .denied
        let now = date(2024, 3, 9)
        let reminders = try service(mock, clock: { now })
        await reminders.reconcile()
        XCTAssertEqual(mock.permissionRequests, 0)
        await reminders.setEnabled(true)
        XCTAssertEqual(mock.permissionRequests, 1)
        XCTAssertFalse(reminders.enabled)
        XCTAssertEqual(reminders.permission, .denied)
        XCTAssertTrue(mock.items.isEmpty)
        await reminders.setEnabled(true)
        XCTAssertEqual(mock.permissionRequests, 1)
        XCTAssertFalse(reminders.enabled)
    }

    func testChangingTimeReplacesDatesPersistsAndReconciliationDoesNotDuplicate() async throws {
        let mock = FactNotificationMock()
        mock.status = .allowed
        let storage = defaults()
        var now = date(2024, 3, 9)
        let reminders = try service(mock, storage: storage, clock: { now })
        await reminders.setEnabled(true)
        let morningIDs = Set(mock.items.keys)
        await reminders.setTime(.init(hour: 14, minute: 25))
        XCTAssertEqual(Set(mock.items.keys), morningIDs)
        XCTAssertTrue(mock.items.values.allSatisfy { $0.components?.hour == 14 && $0.components?.minute == 25 })
        let adds = mock.added.count
        await reminders.reconcile()
        XCTAssertEqual(mock.added.count, adds)
        let restarted = try service(mock, storage: storage, clock: { now })
        XCTAssertTrue(restarted.enabled)
        XCTAssertEqual(restarted.time, .init(hour: 14, minute: 25))
        now = date(2024, 3, 10, 16)
        await restarted.reconcile()
        XCTAssertEqual(mock.items.count, 30)
        XCTAssertFalse(mock.items.keys.contains(where: { $0.hasSuffix("2024-03-09") || $0.hasSuffix("2024-03-10") }))
        XCTAssertTrue(mock.items.keys.contains(where: { $0.hasSuffix("2024-04-09") }))
        XCTAssertEqual(mock.permissionRequests, 0)
    }

    func testCapacityLeavesOtherFeaturesIntactAndPermissionRevocationCancelsOnlyFacts() async throws {
        let mock = FactNotificationMock()
        mock.status = .allowed
        for n in 0..<62 { mock.items["other.\(n)"] = PendingFactNotification(identifier: "other.\(n)") }
        let now = date(2024, 3, 9)
        let reminders = try service(mock, clock: { now })
        await reminders.setEnabled(true)
        XCTAssertEqual(reminders.scheduledCount, 2)
        XCTAssertEqual(mock.items.count, 64)
        mock.status = .denied
        await reminders.reconcile()
        XCTAssertFalse(reminders.enabled)
        XCTAssertEqual(mock.items.count, 62)
        XCTAssertTrue(mock.items.keys.allSatisfy { $0.hasPrefix("other.") })
    }

    func testOptOutDuringAnInFlightAddCannotLeaveAStaleNotification() async throws {
        let mock = FactNotificationMock()
        mock.status = .allowed
        mock.suspendNextAdd = true
        let now = date(2024, 3, 9)
        let reminders = try service(mock, clock: { now })
        let enabling = Task { await reminders.setEnabled(true) }
        for _ in 0..<100 where mock.addGate == nil { await Task.yield() }
        XCTAssertNotNil(mock.addGate)
        let disabling = Task { await reminders.setEnabled(false) }
        for _ in 0..<10 { await Task.yield() }
        mock.addGate?.resume()
        mock.addGate = nil
        await enabling.value
        await disabling.value
        XCTAssertFalse(reminders.enabled)
        XCTAssertTrue(mock.items.isEmpty)
    }
}
