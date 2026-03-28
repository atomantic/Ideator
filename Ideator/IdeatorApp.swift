//
//  IdeatorApp.swift
//  Ideator
//
//  Created by Adam Eivy on 8/11/25.
//

import SwiftUI

@main
struct IdeatorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    guard url.scheme == "idealoom", url.host == "start" else { return }
                    NotificationCenter.default.post(name: .widgetStartTapped, object: nil)
                }
                .task {
                    syncWidgetData()
                }
                .onReceive(NotificationCenter.default.publisher(for: .streakUpdated)) { _ in
                    syncWidgetData()
                }
        }
    }

    private func syncWidgetData() {
        let streakManager = StreakManager.shared
        let status = streakManager.getStreakStatus()
        WidgetDataStore.syncStreak(
            current: streakManager.currentStreak,
            longest: streakManager.longestStreak,
            total: streakManager.totalCompletedLists,
            completedToday: status == .completedToday
        )

        // Sync a daily prompt if needed
        if !WidgetDataStore.isPromptFresh() {
            if let prompt = PromptService.shared.getRandomPrompt() {
                WidgetDataStore.syncPrompt(
                    text: prompt.text,
                    category: prompt.flexibleCategory.name,
                    icon: prompt.flexibleCategory.icon
                )
            }
        }
    }
}
