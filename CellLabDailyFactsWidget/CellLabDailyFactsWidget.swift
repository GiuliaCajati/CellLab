import SwiftUI
import WidgetKit

struct BiologyFactWidgetEntry: TimelineEntry {
    let date: Date
    let fact: BiologyFact?
}

struct BiologyFactWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BiologyFactWidgetEntry { snapshot() }

    func getSnapshot(in context: Context, completion: @escaping (BiologyFactWidgetEntry) -> Void) {
        completion(snapshot())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BiologyFactWidgetEntry>) -> Void) {
        let now = Date()
        if let catalog = try? BiologyFactCatalog.load() {
            let entries = DailyFactTimeline.entries(catalog: catalog, now: now).map {
                BiologyFactWidgetEntry(date: $0.date, fact: $0.fact)
            }
            completion(Timeline(entries: entries, policy: .atEnd))
        } else {
            let calendar = DailyFactCalendar.calendar(in: .autoupdatingCurrent)
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
            completion(Timeline(entries: [BiologyFactWidgetEntry(date: now, fact: nil)], policy: .after(tomorrow)))
        }
    }

    private func snapshot() -> BiologyFactWidgetEntry {
        let now = Date()
        return BiologyFactWidgetEntry(date: now, fact: (try? BiologyFactCatalog.load())?.fact(on: now))
    }
}

struct BiologyFactWidgetView: View {
    let entry: BiologyFactWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let fact = entry.fact {
                if family == .systemSmall {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(fact.emoji).font(.system(size: 30)).accessibilityHidden(true)
                        Text(fact.widgetText)
                            .font(.system(.callout, design: .rounded, weight: .semibold))
                            .lineLimit(4).minimumScaleFactor(0.85)
                    }
                } else {
                    HStack(alignment: .top, spacing: 12) {
                        Text(fact.emoji).font(.system(size: 38)).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(fact.title).font(.system(.headline, design: .serif, weight: .bold))
                                .lineLimit(2).minimumScaleFactor(0.85)
                            Text(fact.detail).font(.system(.caption, design: .rounded))
                                .lineLimit(3)
                            Spacer(minLength: 0)
                            Text("CellLab · Today’s Fact").font(.system(.caption2, design: .rounded, weight: .semibold))
                                .foregroundStyle(FactPalette.teal)
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🧬").font(.largeTitle)
                    Text("A little biology wonder").font(.system(.headline, design: .serif))
                    Text("Open CellLab to explore.").font(.system(.caption, design: .rounded))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(FactPalette.ink)
        .containerBackground(FactPalette.paper, for: .widget)
        .widgetURL(DailyFactIdentity.homeURL)
    }
}

@main struct CellLabDailyFactsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: DailyFactIdentity.widgetKind, provider: BiologyFactWidgetProvider()) {
            BiologyFactWidgetView(entry: $0)
        }
        .configurationDisplayName("Daily Biology Fact")
        .description("A tiny discovery every day. Tap to open CellLab and explore the lab.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    CellLabDailyFactsWidget()
} timeline: {
    BiologyFactWidgetEntry(date: Date(), fact: (try? BiologyFactCatalog.load())?.facts.first)
}

#Preview(as: .systemMedium) {
    CellLabDailyFactsWidget()
} timeline: {
    BiologyFactWidgetEntry(date: Date(), fact: (try? BiologyFactCatalog.load())?.facts.first)
}
