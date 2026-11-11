//
//  ContentView.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/11/26.
//

import SwiftUI

struct ContentView: View {
    @State private var catalog: BiologyCatalog?
    @State private var loadingError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let catalog {
                    home(catalog: catalog)
                } else if let loadingError {
                    ContentUnavailableView {
                        Label(
                            "Unable to Open CellLab",
                            systemImage: "exclamationmark.triangle"
                        )
                    } description: {
                        Text(loadingError)
                    }
                } else {
                    ProgressView("Opening CellLab…")
                }
            }
            .navigationTitle("CellLab")
            .tint(.teal)
        }
        .task {
            guard catalog == nil, loadingError == nil else { return }

            do {
                let loaded = try BiologyCatalog.load()

                guard loaded.entry(
                    id: "process.human-nuclear-transcription"
                ) != nil else {
                    throw CatalogError.invalid(
                        "Missing transcription entry"
                    )
                }

                catalog = loaded
            } catch {
                loadingError = error.localizedDescription
            }
        }
    }

    private func home(catalog: BiologyCatalog) -> some View {
        List {
            Section {
                Text("Little cells. Big discoveries.")
                    .font(.title3)
                    .fontWeight(.medium)
                    .listRowBackground(Color.clear)
            }

            Section("Explore") {
                NavigationLink {
                    GeneExpressionView(catalog: catalog)
                } label: {
                    Label(
                        "Gene Expression",
                        systemImage: "text.book.closed"
                    )
                    .padding(.vertical, 8)
                }

                comingSoon("Cell Division", symbol: "square.split.2x2")
                comingSoon("Cellular Respiration", symbol: "bolt")
                comingSoon("Photosynthesis", symbol: "leaf")
                comingSoon("Parts of the Cell", symbol: "magnifyingglass")
            }
        }
    }

    private func comingSoon(
        _ title: String,
        symbol: String
    ) -> some View {
        HStack {
            Label(title, systemImage: symbol)
            Spacer()
            Text("Coming soon")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}

private struct GeneExpressionView: View {
    let catalog: BiologyCatalog

    var body: some View {
        List {
            Section("Discover") {
                if let entry = catalog.entry(
                    id: "process.human-nuclear-transcription"
                ) {
                    NavigationLink {
                        BiologyEntryView(entry: entry, catalog: catalog)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.title)
                                .font(.headline)

                            Text(entry.context)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }

            Section {
                Label(
                    "Playable activity coming soon",
                    systemImage: "gamecontroller"
                )
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Gene Expression")
    }
}

private struct BiologyEntryView: View {
    let entry: BiologyCatalog.Entry
    let catalog: BiologyCatalog
    @State private var showingSources = false

    var body: some View {
        List {
            Section {
                Text(entry.summary)
                    .font(.title3)
                    .fontWeight(.medium)

                Text(entry.explanation)

                if let aside = entry.playfulAside {
                    Text(aside)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(entry.context)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("Some details still need review", systemImage: "doc.text.magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("A closer look") {
                DisclosureGroup("More detail") {
                    Text(entry.deeperDetail)
                }
            }

            Section("Connected biology") {
                ForEach(entry.links, id: \.self) { link in
                    if let target = catalog.entry(id: link.targetID) {
                        NavigationLink {
                            BiologyEntryView(
                                entry: target,
                                catalog: catalog
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(target.title)

                                Text(link.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    showingSources = true
                } label: {
                    Label("Sources & accuracy", systemImage: "text.book.closed")
                }
            }

            Section("Keep in mind") {
                Text(entry.simplification)
                    .font(.subheadline)
            }
        }
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSources) {
            SourcesAccuracySheet(entry: entry, catalog: catalog)
        }
    }
}

private struct SourcesAccuracySheet: View {
    let entry: BiologyCatalog.Entry
    let catalog: BiologyCatalog
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Review status") {
                    Text("Some details still need review")
                    Text("This lesson is a draft. Source checks support only the claims listed with each source; they are not an expert review of CellLab.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Context and simplifications") {
                    LabeledContent("Context", value: entry.context)
                    Text(entry.simplification)
                        .font(.subheadline)
                }

                Section("Sources") {
                    ForEach(catalog.sources(for: entry)) { source in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(source.title)
                                .font(.headline)
                            if let provider = source.provider {
                                Text(provider)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            if let url = source.url {
                                Link("Open source", destination: url)
                            } else if let note = source.note {
                                Text(note)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            let claims = catalog.evidence(for: source, in: entry)
                            let checkedClaims = claims.filter { $0.status == .sourceChecked }
                            let pendingClaims = claims.filter { $0.status == .pending }
                            if claims.isEmpty {
                                Text(source.note ?? "Background source; no claim-level evidence is recorded here.")
                                    .font(.subheadline)
                            }
                            if !checkedClaims.isEmpty {
                                Text("Source-checked support")
                                    .font(.subheadline.weight(.semibold))
                                ForEach(checkedClaims) { claim in
                                    Label(claim.statement, systemImage: "checkmark.circle")
                                        .font(.subheadline)
                                }
                            }
                            if !pendingClaims.isEmpty {
                                Text("Still to check")
                                    .font(.subheadline.weight(.semibold))
                                ForEach(pendingClaims) { claim in
                                    Label(claim.statement, systemImage: "clock")
                                        .font(.subheadline)
                                }
                            }
                            if let note = source.verificationNote {
                                Text(note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    DisclosureGroup("Credits & reuse") {
                        ForEach(catalog.sources(for: entry)) { source in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(source.title).font(.subheadline.weight(.semibold))
                                if let credits = source.credits { Text(credits).font(.subheadline) }
                                if let identifier = source.licenseIdentifier {
                                    Text("License: \(identifier)").font(.caption).foregroundStyle(.secondary)
                                }
                                if let url = source.licenseURL { Link("License details", destination: url) }
                                if let accessedOn = source.accessedOn {
                                    Text("Accessed on \(accessedOn)").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Sources & accuracy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
