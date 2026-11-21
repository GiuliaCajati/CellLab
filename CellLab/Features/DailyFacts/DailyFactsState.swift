import Combine
import Foundation
import UIKit
import UserNotifications
import WidgetKit

enum DailyFactRoute: Hashable { case settings }

@MainActor final class DailyFactRouter: ObservableObject {
    struct Request: Equatable { let token = UUID(); let factID: String? }
    static let shared = DailyFactRouter()
    @Published private(set) var request: Request?
    nonisolated deinit {}

    func open(_ url: URL) {
        if DailyFactIdentity.isHomeURL(url) {
            request = Request(factID: nil)
            return
        }
        // Cached widgets and older alerts may still carry a fact URL.
        guard let id = DailyFactIdentity.factID(from: url) else { return }
        open(factID: id)
    }
    func open(factID: String) {
        guard BiologyFactCatalog.stableIDs.contains(factID) else { return }
        request = Request(factID: factID)
    }
    func open(notificationPayload: [AnyHashable: Any]) {
        guard let id = DailyFactIdentity.factID(from: notificationPayload) else { return }
        open(factID: id)
    }
}

@MainActor final class DailyFactsState: ObservableObject {
    let catalog: BiologyFactCatalog?
    let reminders: DailyFactReminders
    @Published private(set) var today: BiologyFact?
    @Published private(set) var loadError: String?
    nonisolated deinit {}

    init() {
        do {
            let catalog = try BiologyFactCatalog.load()
            self.catalog = catalog
            today = catalog.fact(on: Date())
            reminders = DailyFactReminders(catalog: catalog)
        } catch {
            catalog = nil
            today = nil
            loadError = "The daily facts couldn’t be loaded."
            reminders = DailyFactReminders(catalog: nil)
        }
    }

    func refresh() async {
        today = catalog?.fact(on: Date())
        WidgetCenter.shared.reloadTimelines(ofKind: DailyFactIdentity.widgetKind)
        await reminders.reconcile()
    }
}

/// Installed before SwiftUI loads, so cold-launch responses wait safely in the router.
final class CellLabNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                           didReceive response: UNNotificationResponse) async {
        guard let id = DailyFactIdentity.factID(from: response.notification.request.content.userInfo) else { return }
        await MainActor.run { DailyFactRouter.shared.open(factID: id) }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                           willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
