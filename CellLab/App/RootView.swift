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
                    CellLabHomeView(catalog: catalog)
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
                    CellLabLoadingView()
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
}
