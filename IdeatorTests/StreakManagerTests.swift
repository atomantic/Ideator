import XCTest
@testable import Ideator

final class StreakManagerTests: XCTestCase {
    private var manager: StreakManager!

    override func setUp() {
        super.setUp()
        manager = StreakManager.shared
        manager.resetAllStats()
    }

    override func tearDown() {
        manager.resetAllStats()
        super.tearDown()
    }

    // MARK: - recordCompletion

    func testRecordCompletion_incrementsTotalCompletedLists() {
        XCTAssertEqual(manager.totalCompletedLists, 0)
        manager.recordCompletion()
        XCTAssertEqual(manager.totalCompletedLists, 1)
        manager.recordCompletion()
        XCTAssertEqual(manager.totalCompletedLists, 2)
    }

    func testRecordCompletion_firstEver_setsStreakToOne() {
        manager.recordCompletion()
        XCTAssertEqual(manager.currentStreak, 1)
        XCTAssertEqual(manager.longestStreak, 1)
    }

    func testRecordCompletion_sameDaySecondCompletion_doesNotIncrementStreak() {
        manager.recordCompletion()
        XCTAssertEqual(manager.currentStreak, 1)
        manager.recordCompletion()
        // Streak should remain 1 since both completions are on the same day
        XCTAssertEqual(manager.currentStreak, 1)
    }

    // MARK: - getStreakStatus

    func testGetStreakStatus_neverStarted_whenNoCompletions() {
        let status = manager.getStreakStatus()
        XCTAssertEqual(status.message, "Start today!")
    }

    func testGetStreakStatus_completedToday_afterCompletion() {
        manager.recordCompletion()
        let status = manager.getStreakStatus()
        XCTAssertEqual(status.message, "Great job! See you tomorrow!")
    }

    // MARK: - Milestones

    func testMilestone_allAchievementDefinitionsAreValid() {
        let achievements = StreakManager.allAchievements
        XCTAssertGreaterThan(achievements.count, 0, "Should have at least one achievement")

        let ids = achievements.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Achievement IDs must be unique")

        for achievement in achievements {
            XCTAssertFalse(achievement.name.isEmpty, "\(achievement.id) must have a name")
            XCTAssertFalse(achievement.icon.isEmpty, "\(achievement.id) must have an icon")
            XCTAssertFalse(achievement.requirement.isEmpty, "\(achievement.id) must have a requirement description")
            XCTAssertTrue(
                achievement.streakRequired != nil || achievement.totalRequired != nil,
                "\(achievement.id) must have either a streak or total requirement"
            )
        }
    }

    // MARK: - StreakStatus messages

    func testStreakStatus_neverStarted_message() {
        XCTAssertEqual(StreakManager.StreakStatus.neverStarted.message, "Start today!")
    }

    func testStreakStatus_completedToday_message() {
        XCTAssertEqual(StreakManager.StreakStatus.completedToday.message, "Great job! See you tomorrow!")
    }

    func testStreakStatus_needsCompletionToday_message() {
        XCTAssertEqual(StreakManager.StreakStatus.needsCompletionToday.message, "Keep it going!")
    }

    func testStreakStatus_broken_message() {
        XCTAssertEqual(StreakManager.StreakStatus.broken.message, "Start again!")
    }

    // MARK: - resetAllStats

    func testResetAllStats_clearsEverything() {
        manager.recordCompletion()
        XCTAssertGreaterThan(manager.totalCompletedLists, 0)

        manager.resetAllStats()

        XCTAssertEqual(manager.currentStreak, 0)
        XCTAssertEqual(manager.longestStreak, 0)
        XCTAssertEqual(manager.totalCompletedLists, 0)
        XCTAssertNil(manager.lastCompletionDate)
    }
}
