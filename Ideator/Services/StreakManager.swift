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
                return "Start your streak today!"
            case .completedToday:
                return "Great job! See you tomorrow!"
            case .needsCompletionToday:
                return "Complete today to continue your streak!"
            case .broken:
                return "Start a new streak today!"
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