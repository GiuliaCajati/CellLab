// CellStructuresView.swift — drop into CellLab's existing NavigationStack.
// Requires iOS 17+. All CS-prefixed types are self-contained.
import SwiftUI

struct CellStructuresView: View {
    private let kind: CSCellKind = .animal
    @State private var selected: CSPart = .nucleus
    @State private var playing = true
    @State private var browserOpen = false
    @State private var clock = CSClock()
    @State private var selectedAt: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var shouldAnimate: Bool { playing && !reduceMotion && scenePhase == .active }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                header

                TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !shouldAnimate)) { timeline in
                    let time = clock.time(at: timeline.date)
                    let activeTime = reduceMotion ? 3.1 : max(0, time - selectedAt)
                    VStack(alignment: .leading, spacing: 17) {
                        specimen(time: activeTime)
                        Text("Parts of the cell")
                            .font(.system(.headline, design: .rounded))
                            .accessibilityAddTraits(.isHeader)
                        structurePicker
                        CSStructureCard(part: selected, kind: kind, time: activeTime,
                                        replay: replay, onSelect: select)
                            .id(selected)
                    }
                }

                Button { browserOpen = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "square.grid.2x2")
                        Text("Explore all \(CSPart.allCases.count) structures")
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.caption.bold())
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .padding(18)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(Color(csHex: 0xD0E5C2), in: RoundedRectangle(cornerRadius: 22))
                    .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(CSPalette.ink.opacity(0.65), lineWidth: 1.3))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("structures-browse")
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .background(CSPalette.cream.ignoresSafeArea())
        .foregroundStyle(CSPalette.ink)
        .tint(CSPalette.teal)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { clock.setRunning(shouldAnimate) }
        .onDisappear { clock.setRunning(false) }
        .onChange(of: shouldAnimate) { _, value in clock.setRunning(value) }
        .sheet(isPresented: $browserOpen) {
            CSStructureBrowser(selected: selected) { part in
                select(part)
                browserOpen = false
            }
            .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Cell Structures")
                .font(.system(.largeTitle, design: .serif, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Text("Small parts. Busy lives.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(CSPalette.muted)
        }
    }

    private func specimen(time: Double) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(kind.specimen)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .tracking(1)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Button { playing.toggle() } label: {
                    Image(systemName: playing && !reduceMotion ? "pause.fill" : "play.fill")
                        .font(.system(.subheadline, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(CSPalette.cream, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(reduceMotion)
                .accessibilityLabel(reduceMotion ? "Motion reduced by system setting" : playing ? "Pause animations" : "Play animations")
                .accessibilityIdentifier("structures-motion")
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            CSAtlas(kind: kind, selected: selected, time: time, onSelect: select)
                .padding(.horizontal, 6)

            Text("Tap a part. See it work.")
                .font(.system(.footnote, design: .rounded, weight: .medium))
                .padding(.top, 5)
            Label(selected.content.title, systemImage: "checkmark.circle.fill")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(CSPalette.teal)
                .padding(.top, 7)
                .padding(.bottom, 16)
                .accessibilityIdentifier("structure-image-selection")
        }
        .background(CSPalette.paper, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(CSPalette.ink.opacity(0.38), lineWidth: 1.2))
    }

    private var structurePicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CSPart.allCases) { part in
                        Button { select(part) } label: {
                            Text(part.content.title)
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .padding(.horizontal, 15)
                                .frame(minHeight: 44)
                                .foregroundStyle(selected == part ? CSPalette.paper : CSPalette.ink)
                                .background(selected == part ? CSPalette.ink : Color(csHex: part.content.hex).opacity(0.55), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .id(part)
                        .accessibilityValue(selected == part ? "Selected" : "")
                        .accessibilityIdentifier("structure-chip-\(part.rawValue)")
                    }
                }
                .padding(.vertical, 2)
            }
            .onAppear { proxy.scrollTo(selected, anchor: .center) }
            .onChange(of: selected) { _, part in
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { proxy.scrollTo(part, anchor: .center) }
            }
        }
    }

    private func select(_ part: CSPart) {
        selected = part
        selectedAt = clock.time(at: Date())
    }
    private func replay() {
        selectedAt = clock.time(at: Date())
        playing = true
    }
}

private struct CSStructureCard: View {
    let part: CSPart
    let kind: CSCellKind
    let time: Double
    let replay: () -> Void
    let onSelect: (CSPart) -> Void
    @State private var expanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(part.content.group.uppercased())
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(CSPalette.muted)
                    Text(part.content.title)
                        .font(.system(.title, design: .serif, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("structure-title")
                }
                Spacer(minLength: 5)
                Button(action: replay) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .background(CSPalette.paper.opacity(0.7), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(reduceMotion)
                .accessibilityLabel("Replay \(part.content.title) demonstration")
            }

            Text(part.content.nickname)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))

            Text(part.content.summary)
                .font(.system(.subheadline, design: .rounded))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                CSFunctionArt(part: part, kind: kind, time: time)
                    .frame(height: 155)
                Text(action)
                    .font(.system(.footnote, design: .rounded, weight: .medium))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity)
            .background(CSPalette.paper.opacity(0.65), in: RoundedRectangle(cornerRadius: 19))

            DisclosureGroup("Look closer", isExpanded: $expanded) {
                VStack(alignment: .leading, spacing: 11) {
                    ForEach(Array(part.content.details.enumerated()), id: \.offset) { _, detail in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("•").fontWeight(.bold).accessibilityHidden(true)
                            Text(detail).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .font(.system(.subheadline, design: .rounded))
                .lineSpacing(2)
                .padding(.top, 10)
            }
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .tint(CSPalette.ink)

            ViewThatFits(in: .horizontal) {
                relatedRow
                ScrollView(.horizontal, showsIndicators: false) { relatedRow }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(csHex: part.content.hex).opacity(0.65), in: RoundedRectangle(cornerRadius: 27))
        .overlay(RoundedRectangle(cornerRadius: 27).strokeBorder(CSPalette.ink.opacity(0.65), lineWidth: 1.4))
        .accessibilityIdentifier("structure-detail")
    }

    private var action: String { part.content.action }
    private var relatedRow: some View {
        HStack(spacing: 7) {
            ForEach(part.content.related) { other in
                Button { onSelect(other) } label: {
                    HStack(spacing: 4) {
                        Text(other.content.title)
                        Image(systemName: "arrow.up.right").font(.system(size: 8, weight: .bold))
                    }
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .padding(.horizontal, 9)
                    .frame(minHeight: 44)
                    .background(CSPalette.paper.opacity(0.7), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Explore this related structure.")
            }
        }
    }
}

private struct CSStructureBrowser: View {
    let selected: CSPart
    let onSelect: (CSPart) -> Void
    @State private var query = ""
    @Environment(\.dismiss) private var dismiss
    private let groups = ["Boundaries", "Genetic control", "Build & deliver", "Recycle & store", "Energy", "Support & motion"]
    private var filtered: [CSPart] {
        CSPart.allCases.filter {
            query.isEmpty || ([$0.content.title, $0.content.nickname, $0.content.summary, $0.content.group] + $0.content.details)
                .joined(separator: " ").localizedCaseInsensitiveContains(query)
        }
    }
    var body: some View {
        NavigationStack {
            List {
                ForEach(groups, id: \.self) { group in
                    let items = filtered.filter { $0.content.group == group }
                    if !items.isEmpty {
                        Section(group) {
                            ForEach(items) { part in
                                Button { onSelect(part) } label: {
                                    HStack(spacing: 12) {
                                        Canvas { c, _ in CSVector.draw(part, in: &c, rect: CGRect(x: 0, y: 0, width: 40, height: 40)) }
                                            .frame(width: 40, height: 40).accessibilityHidden(true)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(part.content.title).font(.system(.subheadline, design: .rounded, weight: .semibold))
                                            Text(part.content.nickname)
                                                .font(.caption).foregroundStyle(CSPalette.muted)
                                        }
                                        Spacer()
                                        if part == selected { Image(systemName: "checkmark.circle.fill") }
                                    }
                                    .foregroundStyle(CSPalette.ink)
                                    .frame(minHeight: 48)
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(CSPalette.paper)
                            }
                        }
                    }
                }
            }
            .overlay { if filtered.isEmpty { ContentUnavailableView.search(text: query) } }
            .scrollContentBackground(.hidden)
            .background(CSPalette.cream.ignoresSafeArea())
            .navigationTitle("Meet the cell crew")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Find a structure or function")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .tint(CSPalette.teal)
        }
    }
}

#Preview("Cell Structures") {
    NavigationStack { CellStructuresView() }
}
