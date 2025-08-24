import Foundation

class StreakManager {
    static let shared = StreakManager()
    
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var lastCompletionDate: Date?
    @Published var totalCompletedLists: Int = 0
    
    private let streakKey = "daily_streak"
    private let longestStreakKey = "longest_streak"
    private let lastCompletionKey = "last_completion_date"
    private let totalCompletedKey = "total_completed_lists"
    private let streakDatesKey = "streak_dates"
    
    private init() {
        loadStreakData()
        rebuildFromCompletedIfNeeded()
        
        // Listen for completed lists
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleListCompleted),
            name: .ideaListCompleted,
            object: nil
        )
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
    
    @objc private func handleListCompleted() {
        recordCompletion()
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
        
        // Check for milestone achievements
        checkMilestones()
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

    private func checkMilestones() {
        // Check for milestone streaks (3, 7, 14, 30, 60, 100, 365)
        let milestones = [3, 7, 14, 30, 60, 100, 365]
        
        if milestones.contains(currentStreak) {
            // Post notification for milestone celebration
            NotificationCenter.default.post(
                name: .streakMilestone,
                object: nil,
                userInfo: ["streak": currentStreak]
            )
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
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
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
            let prevDay = calendar.date(byAdding: .day, value: -1, to: day)!
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
    static let streakMilestone = Notification.Name("streakMilestone")
}
