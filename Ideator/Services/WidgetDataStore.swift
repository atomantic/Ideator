import Foundation
import WidgetKit

enum WidgetDataStore {
    static let suiteName = "group.net.shadowpuppet.ideator"

    private static let streakKey = "widget_streak"
    private static let longestStreakKey = "widget_longest_streak"
    private static let totalCompletedKey = "widget_total_completed"
    private static let completedTodayKey = "widget_completed_today"
    private static let promptTextKey = "widget_prompt_text"
    private static let promptCategoryKey = "widget_prompt_category"
    private static let promptCategoryIconKey = "widget_prompt_category_icon"
    private static let promptDateKey = "widget_prompt_date"

    // MARK: - Write (from main app)

    static func syncStreak(current: Int, longest: Int, total: Int, completedToday: Bool) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(current, forKey: streakKey)
        defaults.set(longest, forKey: longestStreakKey)
        defaults.set(total, forKey: totalCompletedKey)
        defaults.set(completedToday, forKey: completedTodayKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func syncPrompt(text: String, category: String, icon: String) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(text, forKey: promptTextKey)
        defaults.set(category, forKey: promptCategoryKey)
        defaults.set(icon, forKey: promptCategoryIconKey)
        // Store today's date so we know when to refresh
        let dateString = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
        defaults.set(dateString, forKey: promptDateKey)
    }

    // MARK: - Read (from widget)

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

    static func isPromptFresh() -> Bool {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let storedDate = defaults.string(forKey: promptDateKey) else { return false }
        let todayString = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
        return storedDate == todayString
    }
}
