//
//  RootView.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/11/26.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @State private var content: CellLabContent?
    @State private var loadingError: String?

    var body: some View {
        Group {
            if let content {
                NavigationStack {
                    CellLabHomeView(catalog: content.catalog)
                        .navigationTitle("CellLab")
                }
                .tint(.teal)
                .modelContainer(content.progressContainer)
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
        .task {
            guard content == nil, loadingError == nil else { return }

            // Avoid a flash on fast launches; longer preparation keeps the
            // loading screen visible for as long as the app actually needs.
            async let minimumDisplay: Void = Task.sleep(for: .milliseconds(800))
            do {
                let loaded = try await CellLabContent.load()
                try await minimumDisplay
                try Task.checkCancellation()
                content = loaded
            } catch is CancellationError {
                // SwiftUI can cancel preparation when this root disappears.
            } catch {
                loadingError = error.localizedDescription
            }
        }
    }
}
