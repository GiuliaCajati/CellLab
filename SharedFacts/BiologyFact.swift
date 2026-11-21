import Foundation

nonisolated struct BiologyFact: Codable, Identifiable, Equatable, Sendable {
    struct Source: Codable, Equatable, Sendable {
        let label: String
        let url: URL
    }
    let id: String
    let emoji: String
    let widgetText: String
    let title: String
    let detail: String
    let sources: [Source]

    var deepLink: URL { URL(string: "celllab://fact/\(id)")! }
}

nonisolated struct BiologyFactCatalog: Sendable {
    static let stableIDs = (1...69).map { String(format: "fact-%03d", $0) }
    let facts: [BiologyFact]

    init(data: Data) throws {
        let decoded = try JSONDecoder().decode([BiologyFact].self, from: data)
        guard decoded.count == 69, Set(decoded.map(\.id)) == Set(Self.stableIDs),
              decoded.allSatisfy({ !$0.title.isEmpty && !$0.detail.isEmpty && !$0.widgetText.isEmpty
                  && !$0.emoji.isEmpty && !$0.sources.isEmpty
                  && $0.sources.allSatisfy { !$0.label.isEmpty && ["http", "https"].contains($0.url.scheme?.lowercased() ?? "") } }) else {
            throw CocoaError(.coderReadCorrupt)
        }
        facts = decoded.sorted { $0.id < $1.id }
    }

    static func load(bundle: Bundle = .main) throws -> Self {
        guard let url = bundle.url(forResource: "daily-facts", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try Self(data: Data(contentsOf: url))
    }

    func fact(id: String) -> BiologyFact? { facts.first { $0.id == id } }
    func fact(on date: Date, timeZone: TimeZone = .autoupdatingCurrent) -> BiologyFact {
        facts[DailyFactCalendar.index(on: date, timeZone: timeZone)]
    }
}

nonisolated enum DailyFactIdentity {
    static let homeURL = URL(string: "celllab://home")!
    static let widgetKind = "CellLabDailyFacts"
    static let notificationPrefix = "celllab.daily-fact."
    static let factIDKey = "celllab.factID"
    static let urlKey = "celllab.factURL"

    static func isHomeURL(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "celllab"
            && (url.host?.lowercased() == "home" || (url.host?.isEmpty ?? true))
            && (url.path.isEmpty || url.path == "/")
    }

    static func factID(from url: URL) -> String? {
        guard url.scheme?.lowercased() == "celllab", url.host?.lowercased() == "fact",
              url.pathComponents.count == 2,
              BiologyFactCatalog.stableIDs.contains(url.lastPathComponent) else { return nil }
        return url.lastPathComponent
    }

    static func factID(from payload: [AnyHashable: Any]) -> String? {
        if let id = payload[factIDKey] as? String, BiologyFactCatalog.stableIDs.contains(id) { return id }
        if let value = payload[urlKey] as? String, let url = URL(string: value) { return factID(from: url) }
        return nil
    }
}

/// Gregorian civil dates, anchored at 2024-01-01. No elapsed-seconds arithmetic.
nonisolated enum DailyFactCalendar {
    static func calendar(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = timeZone
        return calendar
    }

    static func index(on date: Date, timeZone: TimeZone = .autoupdatingCurrent) -> Int {
        let local = calendar(in: timeZone).dateComponents([.year, .month, .day], from: date)
        let civil = calendar(in: TimeZone(secondsFromGMT: 0)!)
        let day = civil.date(from: local)!
        let anchor = civil.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let days = civil.dateComponents([.day], from: anchor, to: day).day!
        return ((days % 69) + 69) % 69
    }

    static func dayID(_ date: Date, timeZone: TimeZone) -> String {
        let parts = calendar(in: timeZone).dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }
}

nonisolated struct DatedBiologyFact: Equatable, Sendable {
    let date: Date
    let fact: BiologyFact
}

nonisolated enum DailyFactTimeline {
    /// Today plus seven precomputed local midnights; WidgetKit can advance offline.
    static func entries(catalog: BiologyFactCatalog, now: Date, timeZone: TimeZone = .autoupdatingCurrent,
                        upcomingDays: Int = 7) -> [DatedBiologyFact] {
        let calendar = DailyFactCalendar.calendar(in: timeZone)
        let start = calendar.startOfDay(for: now)
        guard upcomingDays > 0 else { return [DatedBiologyFact(date: now, fact: catalog.fact(on: now, timeZone: timeZone))] }
        return [DatedBiologyFact(date: now, fact: catalog.fact(on: now, timeZone: timeZone))]
            + (1...upcomingDays).compactMap { offset in
                guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
                return DatedBiologyFact(date: date, fact: catalog.fact(on: date, timeZone: timeZone))
            }
    }
}

nonisolated struct DailyFactReminderTime: Equatable, Sendable {
    let hour: Int
    let minute: Int
    static let morning = Self(hour: 9, minute: 0)
    init(hour: Int, minute: Int) {
        self.hour = (0...23).contains(hour) ? hour : 9
        self.minute = (0...59).contains(minute) ? minute : 0
    }
}

nonisolated struct DailyFactAlert: Equatable, Sendable {
    let identifier: String
    let fireDate: Date
    let components: DateComponents
    let fact: BiologyFact
    var body: String { fact.widgetText }
    var payload: [String: String] {
        [DailyFactIdentity.factIDKey: fact.id, DailyFactIdentity.urlKey: DailyFactIdentity.homeURL.absoluteString]
    }
}

nonisolated enum DailyFactReminderPlan {
    static let pendingRequestLimit = 64
    static let window = 30

    static func alerts(catalog: BiologyFactCatalog, now: Date, timeZone: TimeZone = .autoupdatingCurrent,
                       time: DailyFactReminderTime, availableCapacity: Int) -> [DailyFactAlert] {
        let limit = min(window, max(0, availableCapacity))
        guard limit > 0 else { return [] }
        let calendar = DailyFactCalendar.calendar(in: timeZone)
        let start = calendar.startOfDay(for: now)
        var result: [DailyFactAlert] = []
        for offset in 0...window {
            guard result.count < limit else { break }
            guard let day = calendar.date(byAdding: .day, value: offset, to: start),
                  let beforeDay = calendar.date(byAdding: .second, value: -1, to: day),
                  let fire = calendar.nextDate(after: beforeDay,
                                               matching: DateComponents(hour: time.hour, minute: time.minute, second: 0),
                                               matchingPolicy: .nextTimePreservingSmallerComponents,
                                               repeatedTimePolicy: .first, direction: .forward),
                  calendar.isDate(day, inSameDayAs: fire), fire > now else { continue }
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fire)
            // Floating local calendar components let iOS follow the device time zone.
            // Foreground/significant-time reconciliation also rebuilds DST-adjusted days.
            var floatingCalendar = Calendar(identifier: .gregorian)
            floatingCalendar.timeZone = .autoupdatingCurrent
            components.calendar = floatingCalendar
            components.timeZone = nil
            result.append(DailyFactAlert(identifier: DailyFactIdentity.notificationPrefix
                                        + DailyFactCalendar.dayID(day, timeZone: timeZone),
                                        fireDate: fire, components: components,
                                        fact: catalog.fact(on: day, timeZone: timeZone)))
        }
        return result
    }
}
