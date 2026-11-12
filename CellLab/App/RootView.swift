//
//  RootView.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/11/26.
//

import SwiftUI

struct RootView: View {
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
                    MitosisView(catalog: catalog)
                } label: {
                    Label(
                        "Mitosis.. aka Cell Division",
                        systemImage: "circle.grid.2x2"
                    )
                    .padding(.vertical, 8)
                }

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
