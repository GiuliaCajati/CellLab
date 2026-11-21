import SwiftUI
import UIKit

/// Optional fact reading stays inside Settings rather than opening another page.
private struct DailyFactContents: View {
    let fact: BiologyFact

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(fact.title)
                .font(.system(.title3, design: .serif, weight: .bold))
                .accessibilityIdentifier("daily-fact-title")
            Text(fact.detail)
                .font(.system(.body, design: .rounded))
                .accessibilityIdentifier("daily-fact-detail")
            Text("Sources").font(.system(.subheadline, design: .rounded, weight: .bold))
            ForEach(Array(fact.sources.enumerated()), id: \.offset) { index, source in
                Link(destination: source.url) {
                    Label(source.label, systemImage: "arrow.up.right.square")
                        .font(.system(.subheadline, design: .rounded))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(FactPalette.teal)
                .accessibilityIdentifier("daily-fact-source-\(index)")
            }
        }
        .foregroundStyle(FactPalette.ink)
        .padding(.vertical, 10)
    }
}

struct CellLabSettingsView: View {
    @EnvironmentObject private var facts: DailyFactsState
    @EnvironmentObject private var reminders: DailyFactReminders
    @Environment(\.openURL) private var openURL

    private var pickerDate: Binding<Date> {
        Binding(get: {
            let calendar = DailyFactCalendar.calendar(in: .autoupdatingCurrent)
            return calendar.date(bySettingHour: reminders.time.hour, minute: reminders.time.minute, second: 0, of: Date()) ?? Date()
        }, set: { date in
            let parts = DailyFactCalendar.calendar(in: .autoupdatingCurrent).dateComponents([.hour, .minute], from: date)
            Task { await reminders.setTime(DailyFactReminderTime(hour: parts.hour ?? 9, minute: parts.minute ?? 0)) }
        })
    }

    var body: some View {
        Form {
            if let fact = facts.today {
                Section {
                    DisclosureGroup {
                        DailyFactContents(fact: fact)
                    } label: {
                        HStack(spacing: 10) {
                            Text(fact.emoji).font(.system(size: 22)).accessibilityHidden(true)
                            Text("Today’s Fact")
                        }
                    }
                    .accessibilityIdentifier("today-fact-entry")
                    .listRowBackground(FactPalette.paper)
                }
            }
            Section {
                Toggle("Daily fact reminder", isOn: Binding(get: { reminders.enabled }, set: { value in
                    Task { await reminders.setEnabled(value) }
                }))
                .disabled(reminders.requestingPermission)
                .accessibilityIdentifier("daily-fact-reminder-toggle")
                .listRowBackground(FactPalette.paper)
                DatePicker("Local time", selection: pickerDate, displayedComponents: .hourAndMinute)
                    .disabled(!reminders.enabled)
                    .accessibilityIdentifier("daily-fact-reminder-time")
                    .listRowBackground(FactPalette.paper)
            } header: {
                Text("A daily biology discovery")
            } footer: {
                Text("Reminders are optional and work offline. CellLab queues up to 30 days at a time. Open the app occasionally to keep them going; they may pause after the queued days run out.")
            }
            if reminders.permission == .denied {
                Section {
                    Text("Notifications are off for CellLab. Enable them in iOS Settings, then turn on the reminder here.")
                        .listRowBackground(FactPalette.paper)
                    Button("Open Settings", systemImage: "arrow.up.right.square") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                    .accessibilityIdentifier("daily-fact-open-settings")
                    .listRowBackground(FactPalette.paper)
                }
            }
            if let message = reminders.errorMessage {
                Section { Text(message).accessibilityIdentifier("daily-fact-reminder-error").listRowBackground(FactPalette.paper) }
            }
            if reminders.enabled {
                Section {
                    Text("\(reminders.scheduledCount) upcoming reminders ready")
                        .accessibilityIdentifier("daily-fact-reminder-count")
                        .listRowBackground(FactPalette.paper)
                }
            }
        }
        .font(.system(.body, design: .rounded))
        .foregroundStyle(FactPalette.ink)
        .tint(FactPalette.teal)
        .scrollContentBackground(.hidden)
        .background(FactPalette.paper.ignoresSafeArea())
        .environment(\.calendar, DailyFactCalendar.calendar(in: .autoupdatingCurrent))
        .environment(\.colorScheme, .light)
        .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
    }
}
