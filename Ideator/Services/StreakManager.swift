import Foundation

@MainActor @Observable
final class StreakManager {
    static let shared = StreakManager()

    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastCompletionDate: Date?
    var totalCompletedLists: Int = 0
    
    private let streakKey = "daily_streak"
    private let longestStreakKey = "longest_streak"
    private let lastCompletionKey = "last_completion_date"
    private let totalCompletedKey = "total_completed_lists"
    private let streakDatesKey = "streak_dates"
    
    private var completionObserver: Any?

    private init() {
        loadStreakData()
        loadEarnedAchievements()
        rebuildFromCompletedIfNeeded()

        completionObserver = NotificationCenter.default.addObserver(
            forName: .ideaListCompleted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.recordCompletion()
            }
        }
    }


    private func loadStreakData() {
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
        longestStreak = UserDefaults.standard.integer(forKey: longestStreakKey)
        totalCompletedLists = UserDefaults.standard.integer(forKey: totalCompletedKey)
        
        if let dateData = UserDefaults.standard.data(forKey: lastCompletionKey),
           let date = try? JSONDecoder().decode(Date.self, from: dateData) {
            lastCompletionDate = date
        }
        
        // Check if streak is still valid (completed yesterday)
        validateStreak()
    }
    
    private func saveStreakData() {
        UserDefaults.standard.set(currentStreak, forKey: streakKey)
        UserDefaults.standard.set(longestStreak, forKey: longestStreakKey)
        UserDefaults.standard.set(totalCompletedLists, forKey: totalCompletedKey)
        
        if let lastDate = lastCompletionDate,
           let dateData = try? JSONEncoder().encode(lastDate) {
            UserDefaults.standard.set(dateData, forKey: lastCompletionKey)
        }
    }
    
    func recordCompletion() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Increment total completed lists
        totalCompletedLists += 1
        
        // Check if this is the first completion today
        if let lastDate = lastCompletionDate {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            
            if lastDay == today {
                // Already completed today, just save the total
                saveStreakData()
                return
            }
            
            // Check if this continues the streak (completed yesterday)
            if let dayAfterLast = Calendar.current.date(byAdding: .day, value: 1, to: lastDay),
               dayAfterLast == today {
                // Continuing streak!
                currentStreak += 1
                
                // Update longest streak if needed
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }
            } else {
                // Streak broken - start new streak
                currentStreak = 1
            }
        } else {
            // First completion ever
            currentStreak = 1
            if longestStreak == 0 {
                longestStreak = 1
            }
        }
        
        lastCompletionDate = Date()
        saveStreakData()
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .streakUpdated, object: nil)
    }

    private func validateStreak() {
        guard let lastDate = lastCompletionDate else { return }
        
        let lastDay = Calendar.current.startOfDay(for: lastDate)
        let today = Calendar.current.startOfDay(for: Date())
        
        // If last completion was not today or yesterday, reset streak
        if let dayAfterLast = Calendar.current.date(byAdding: .day, value: 1, to: lastDay) {
            if dayAfterLast < today {
                // Streak is broken
                currentStreak = 0
                saveStreakData()
            }
        }
    }

    // MARK: - Migration from completed lists
    private func rebuildFromCompletedIfNeeded() {
        let migrationFlag = "streak_migration_v1_done"
        if UserDefaults.standard.bool(forKey: migrationFlag) { return }

        let completed = PersistenceManager.shared.loadCompleted().filter { $0.isComplete }
        guard !completed.isEmpty else {
            UserDefaults.standard.set(true, forKey: migrationFlag)
            return
        }

        // Build set of unique completion days
        let calendar = Calendar.current
        let completionDays: Set<Date> = Set(completed.map { list in
            // Prefer modifiedDate as completion timestamp; fallback to createdDate
            let date = list.modifiedDate
            return calendar.startOfDay(for: date)
        })

        guard let latestDay = completionDays.max() else {
            UserDefaults.standard.set(true, forKey: migrationFlag)
            return
        }

        let today = calendar.startOfDay(for: Date())
        // Only reconstruct if latest completion is today or yesterday (active streak)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            UserDefaults.standard.set(true, forKey: migrationFlag)
            return
        }
        guard latestDay == today || latestDay == yesterday else {
            // No active streak; still set totals
            totalCompletedLists = completed.count
            saveStreakData()
            UserDefaults.standard.set(true, forKey: migrationFlag)
            return
        }

        // Walk backwards to count consecutive days up to today/yesterday
        var streak = 0
        var cursor = latestDay
        while completionDays.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }

        // Compute longest streak across all completion days
        var longest = 0
        var visited: Set<Date> = []
        for day in completionDays {
            guard let prevDay = calendar.date(byAdding: .day, value: -1, to: day) else { continue }
            if completionDays.contains(prevDay) { continue } // Not a run start
            var runLen = 0
            var runCursor = day
            while completionDays.contains(runCursor) {
                runLen += 1
                visited.insert(runCursor)
                guard let prev = calendar.date(byAdding: .day, value: 1, to: runCursor) else { break }
                runCursor = prev
            }
            if runLen > longest { longest = runLen }
        }

        currentStreak = streak
        longestStreak = max(longestStreak, longest)
        totalCompletedLists = completed.count
        lastCompletionDate = latestDay
        saveStreakData()
        UserDefaults.standard.set(true, forKey: migrationFlag)
        NotificationCenter.default.post(name: .streakUpdated, object: nil)
    }
    
    func resetStreak() {
        currentStreak = 0
        lastCompletionDate = nil
        saveStreakData()
        NotificationCenter.default.post(name: .streakUpdated, object: nil)
    }
    
    // MARK: - Achievements

    private let achievementsKey = "earned_achievements"
    var earnedAchievements: Set<String> = []

    private func loadEarnedAchievements() {
        guard let data = UserDefaults.standard.data(forKey: achievementsKey),
              let achievements = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            return
        }
        earnedAchievements = achievements
    }

    private func saveEarnedAchievements() {
        if let data = try? JSONEncoder().encode(earnedAchievements) {
            UserDefaults.standard.set(data, forKey: achievementsKey)
        }
    }

    static let allAchievements: [(id: String, name: String, icon: String, requirement: String, streakRequired: Int?, totalRequired: Int?)] = [
        ("first_list", "First Spark", "sparkle", "Complete your first idea list", nil, 1),
        ("streak_3", "On a Roll", "flame", "3-day streak", 3, nil),
        ("streak_7", "Week Warrior", "flame.fill", "7-day streak", 7, nil),
        ("streak_14", "Fortnight Force", "bolt.fill", "14-day streak", 14, nil),
        ("streak_30", "Monthly Master", "star.fill", "30-day streak", 30, nil),
        ("streak_60", "Idea Machine", "crown", "60-day streak", 60, nil),
        ("streak_100", "Century Club", "trophy.fill", "100-day streak", 100, nil),
        ("streak_365", "Legendary", "laurel.leading", "365-day streak", 365, nil),
        ("total_10", "Getting Started", "lightbulb", "Complete 10 idea lists", nil, 10),
        ("total_50", "Prolific Thinker", "lightbulb.fill", "Complete 50 idea lists", nil, 50),
        ("total_100", "Centurion", "brain.head.profile", "Complete 100 idea lists", nil, 100),
    ]

    func checkAndAwardAchievements() -> [(id: String, name: String, icon: String)]? {
        var newlyEarned: [(id: String, name: String, icon: String)] = []

        for achievement in Self.allAchievements {
            guard !earnedAchievements.contains(achievement.id) else { continue }

            var qualifies = false
            if let streakReq = achievement.streakRequired, currentStreak >= streakReq {
                qualifies = true
            }
            if let totalReq = achievement.totalRequired, totalCompletedLists >= totalReq {
                qualifies = true
            }

            if qualifies {
                earnedAchievements.insert(achievement.id)
                newlyEarned.append((id: achievement.id, name: achievement.name, icon: achievement.icon))
            }
        }

        if !newlyEarned.isEmpty {
            saveEarnedAchievements()
        }

        return newlyEarned.isEmpty ? nil : newlyEarned
    }

    func resetAllStats() {
        currentStreak = 0
        longestStreak = 0
        lastCompletionDate = nil
        totalCompletedLists = 0
        UserDefaults.standard.removeObject(forKey: streakKey)
        UserDefaults.standard.removeObject(forKey: longestStreakKey)
        UserDefaults.standard.removeObject(forKey: lastCompletionKey)
        UserDefaults.standard.removeObject(forKey: totalCompletedKey)
        UserDefaults.standard.removeObject(forKey: streakDatesKey)
        UserDefaults.standard.removeObject(forKey: achievementsKey)
        earnedAchievements = []
        NotificationCenter.default.post(name: .streakUpdated, object: nil)
    }
    
    func getStreakStatus() -> StreakStatus {
        guard let lastDate = lastCompletionDate else {
            return .neverStarted
        }
        
        let lastDay = Calendar.current.startOfDay(for: lastDate)
        let today = Calendar.current.startOfDay(for: Date())
        
        if lastDay == today {
            return .completedToday
        } else if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today),
                  lastDay == yesterday {
            return .needsCompletionToday
        } else {
            return .broken
        }
    }
    
    enum StreakStatus {
        case neverStarted
        case completedToday
        case needsCompletionToday
        case broken
        
        var message: String {
            switch self {
            case .neverStarted:
                return "Start today!"
            case .completedToday:
                return "Great job! See you tomorrow!"
            case .needsCompletionToday:
                return "Keep it going!"
            case .broken:
                return "Start again!"
            }
        }
        
        var emoji: String {
            switch self {
            case .neverStarted:
                return "🌱"
            case .completedToday:
                return "✅"
            case .needsCompletionToday:
                return "⏰"
            case .broken:
                return "💔"
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let ideaListCompleted = Notification.Name("ideaListCompleted")
    static let streakUpdated = Notification.Name("streakUpdated")
}
