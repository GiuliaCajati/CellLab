import Combine
import Foundation
import UserNotifications

nonisolated enum DailyFactPermission: Equatable, Sendable {
    case notDetermined, allowed, denied, unknown
}

nonisolated struct PendingFactNotification: Equatable, Sendable {
    let identifier: String
    var body: String? = nil
    var factID: String? = nil
    var components: DateComponents? = nil
}

@MainActor protocol DailyFactNotificationClient: AnyObject {
    func permission() async -> DailyFactPermission
    func requestPermission() async throws -> Bool
    func pending() async -> [PendingFactNotification]
    func add(_ alert: DailyFactAlert) async throws
    func remove(identifiers: [String]) async
}

@MainActor final class SystemDailyFactNotifications: DailyFactNotificationClient {
    private let center = UNUserNotificationCenter.current()
    nonisolated deinit {}

    func permission() async -> DailyFactPermission {
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral: .allowed
        case .denied: .denied
        case .notDetermined: .notDetermined
        @unknown default: .unknown
        }
    }

    func requestPermission() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func pending() async -> [PendingFactNotification] {
        await center.pendingNotificationRequests().map {
            PendingFactNotification(identifier: $0.identifier, body: $0.content.body,
                                    factID: $0.content.userInfo[DailyFactIdentity.factIDKey] as? String,
                                    components: ($0.trigger as? UNCalendarNotificationTrigger)?.dateComponents)
        }
    }

    func add(_ alert: DailyFactAlert) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Today’s biology fact \(alert.fact.emoji)"
        content.body = alert.body
        content.sound = .default
        content.threadIdentifier = DailyFactIdentity.notificationPrefix
        content.userInfo = alert.payload
        let trigger = UNCalendarNotificationTrigger(dateMatching: alert.components, repeats: false)
        try await center.add(UNNotificationRequest(identifier: alert.identifier, content: content, trigger: trigger))
    }

    func remove(identifiers: [String]) async {
        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

@MainActor final class DailyFactReminders: ObservableObject {
    enum Key {
        static let enabled = "CellLab.dailyFact.reminder.enabled.v1"
        static let hour = "CellLab.dailyFact.reminder.hour.v1"
        static let minute = "CellLab.dailyFact.reminder.minute.v1"
    }
    @Published private(set) var enabled: Bool
    @Published private(set) var time: DailyFactReminderTime
    @Published private(set) var permission: DailyFactPermission = .notDetermined
    @Published private(set) var requestingPermission = false
    @Published private(set) var scheduledCount = 0
    @Published private(set) var errorMessage: String?
    private let catalog: BiologyFactCatalog?
    private let client: any DailyFactNotificationClient
    private let defaults: UserDefaults
    private let now: () -> Date
    private let timeZone: () -> TimeZone
    private var enableGeneration = 0
    private var workGeneration = 0
    private var work: Task<Void, Never>?
    nonisolated deinit {}

    init(catalog: BiologyFactCatalog?, client: (any DailyFactNotificationClient)? = nil,
         defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init,
         timeZone: @escaping () -> TimeZone = { .autoupdatingCurrent }) {
        self.catalog = catalog
        self.client = client ?? SystemDailyFactNotifications()
        self.defaults = defaults
        self.now = now
        self.timeZone = timeZone
        enabled = defaults.bool(forKey: Key.enabled)
        time = DailyFactReminderTime(hour: defaults.object(forKey: Key.hour) as? Int ?? 9,
                                    minute: defaults.object(forKey: Key.minute) as? Int ?? 0)
    }

    /// This is the ONLY path that requests authorization, called by the Settings toggle.
    func setEnabled(_ value: Bool) async {
        enableGeneration += 1
        let intent = enableGeneration
        enabled = value
        defaults.set(value, forKey: Key.enabled)
        workGeneration += 1 // Invalidate any scheduling pass already in flight.
        errorMessage = nil
        if value {
            requestingPermission = true
            permission = await client.permission()
            guard intent == enableGeneration else { requestingPermission = false; return }
            if permission == .notDetermined {
                do {
                    _ = try await client.requestPermission()
                    permission = await client.permission()
                } catch {
                    errorMessage = "Couldn’t request notifications. Please try again."
                    permission = await client.permission()
                }
            }
            guard intent == enableGeneration else { requestingPermission = false; return }
            requestingPermission = false
            if permission != .allowed {
                enabled = false
                defaults.set(false, forKey: Key.enabled)
            }
        }
        await reconcile()
    }

    func setTime(_ value: DailyFactReminderTime) async {
        time = value
        defaults.set(value.hour, forKey: Key.hour)
        defaults.set(value.minute, forKey: Key.minute)
        await reconcile()
    }

    /// Serialize center mutations. Newer settings supersede queued or suspended work.
    func reconcile() async {
        workGeneration += 1
        let generation = workGeneration
        let previous = work
        let next = Task { [weak self] in
            await previous?.value
            guard let self, generation == self.workGeneration else { return }
            await self.performReconciliation(generation)
        }
        work = next
        await next.value
        if generation == workGeneration { work = nil }
    }

    private func performReconciliation(_ generation: Int) async {
        let status = await client.permission()
        let pending = await client.pending()
        guard generation == workGeneration else { return }
        permission = status
        if status == .denied || (status != .allowed && !requestingPermission) {
            enabled = false
            defaults.set(false, forKey: Key.enabled)
        }
        let own = pending.filter { $0.identifier.hasPrefix(DailyFactIdentity.notificationPrefix) }
        guard enabled, status == .allowed, let catalog else {
            await client.remove(identifiers: own.map(\.identifier))
            scheduledCount = 0
            return
        }
        let otherCount = pending.count - own.count
        let alerts = DailyFactReminderPlan.alerts(catalog: catalog, now: now(), timeZone: timeZone(), time: time,
                                                availableCapacity: DailyFactReminderPlan.pendingRequestLimit - otherCount)
        let desiredIDs = Set(alerts.map(\.identifier))
        await client.remove(identifiers: own.filter { !desiredIDs.contains($0.identifier) }.map(\.identifier))
        guard generation == workGeneration else { return }
        let existing = Dictionary(own.map { ($0.identifier, $0) }, uniquingKeysWith: { _, newest in newest })
        errorMessage = nil
        if alerts.isEmpty && otherCount >= DailyFactReminderPlan.pendingRequestLimit {
            errorMessage = "Your other reminders are using the available slots. CellLab will try again next time you open it."
        }
        for alert in alerts {
            guard generation == workGeneration, enabled else { return }
            guard alert.fireDate > now() else { continue }
            let expected = PendingFactNotification(identifier: alert.identifier, body: alert.body,
                                                   factID: alert.fact.id, components: alert.components)
            if existing[alert.identifier] == expected { continue }
            do {
                // Adding an existing identifier replaces it; it never duplicates the date.
                try await client.add(alert)
            } catch {
                errorMessage = "Some reminders couldn’t be scheduled. Open CellLab to try again."
                break
            }
        }
        guard generation == workGeneration else { return }
        scheduledCount = await client.pending().filter { $0.identifier.hasPrefix(DailyFactIdentity.notificationPrefix) }.count
    }
}
