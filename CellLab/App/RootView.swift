//
//  RootView.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/11/26.
//

import SwiftUI
import SwiftData
import UIKit
import Combine

struct RootView: View {
    @State private var content: CellLabContent?
    @State private var loadingError: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var facts: DailyFactsState
    @EnvironmentObject private var factRouter: DailyFactRouter
    @State private var path = NavigationPath()
    @State private var navigationIdentity = UUID()

    var body: some View {
        ZStack {
            if let content {
                NavigationStack(path: $path) {
                    CellLabHomeView(catalog: content.catalog)
                        .navigationTitle("CellLab")
                        .navigationDestination(for: DailyFactRoute.self) { route in
                            switch route {
                            case .settings: CellLabSettingsView()
                            }
                        }
                }
                .id(navigationIdentity)
                .tint(.teal)
                .modelContainer(content.progressContainer)
                .transition(.opacity)
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
                    .transition(.opacity)
            }
        }
        .onOpenURL { factRouter.open($0) }
        .onChange(of: factRouter.request, initial: true) { _, request in
            guard let request else { return }
            // Reset view-based lesson/game pushes as well as value-based routes.
            navigationIdentity = request.token
            path = NavigationPath()
        }
        .task { await facts.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await facts.refresh() } }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            Task { await facts.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
            Task { await facts.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            Task { await facts.refresh() }
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
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
                    content = loaded
                }
            } catch is CancellationError {
                // SwiftUI can cancel preparation when this root disappears.
            } catch {
                loadingError = error.localizedDescription
            }
        }
    }
}
