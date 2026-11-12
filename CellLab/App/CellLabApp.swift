//
//  CellLabApp.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/11/26.
//

import SwiftUI
import SwiftData

@main
struct CellLabApp: App {
    private let progressContainer: ModelContainer = {
        let schema = Schema(versionedSchema: PlayerDataV1.self)

        let configuration = ModelConfiguration(
            "CellLabProgress",
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .none,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Could not open CellLab progress: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(progressContainer)
    }
}
