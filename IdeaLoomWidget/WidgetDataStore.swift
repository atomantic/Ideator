import Foundation

// Shared read-only access to widget data stored by the main app via App Group UserDefaults
enum WidgetDataStore {
    static let suiteName = "group.net.shadowpuppet.ideator"

    private static let streakKey = "widget_streak"
    private static let longestStreakKey = "widget_longest_streak"
    private static let totalCompletedKey = "widget_total_completed"
    private static let completedTodayKey = "widget_completed_today"
    private static let promptTextKey = "widget_prompt_text"
    private static let promptCategoryKey = "widget_prompt_category"
    private static let promptCategoryIconKey = "widget_prompt_category_icon"

    static func readStreak() -> Int {
        UserDefaults(suiteName: suiteName)?.integer(forKey: streakKey) ?? 0
    }

    static func readLongestStreak() -> Int {
        UserDefaults(suiteName: suiteName)?.integer(forKey: longestStreakKey) ?? 0
    }

    static func readTotalCompleted() -> Int {
        UserDefaults(suiteName: suiteName)?.integer(forKey: totalCompletedKey) ?? 0
    }

    static func readCompletedToday() -> Bool {
        UserDefaults(suiteName: suiteName)?.bool(forKey: completedTodayKey) ?? false
    }

    static func readPromptText() -> String? {
        UserDefaults(suiteName: suiteName)?.string(forKey: promptTextKey)
    }

    static func readPromptCategory() -> String? {
        UserDefaults(suiteName: suiteName)?.string(forKey: promptCategoryKey)
    }

    static func readPromptCategoryIcon() -> String? {
        UserDefaults(suiteName: suiteName)?.string(forKey: promptCategoryIconKey)
    }
}
