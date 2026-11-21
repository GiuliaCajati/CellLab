//
//  CellLabApp.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/11/26.
//

import SwiftUI

@main
struct CellLabApp: App {
    @UIApplicationDelegateAdaptor(CellLabNotificationDelegate.self) private var notificationDelegate
    @StateObject private var facts = DailyFactsState()
    @StateObject private var factRouter = DailyFactRouter.shared
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(facts)
                .environmentObject(facts.reminders)
                .environmentObject(factRouter)
        }
    }
}
