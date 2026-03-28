import XCTest
@testable import Ideator

final class SeasonalPromptProviderTests: XCTestCase {

    // MARK: - Season detection

    func testCurrentSeason_january_isWinter() {
        let date = makeDate(month: 1, day: 15)
        XCTAssertEqual(SeasonalPromptProvider.currentSeason(for: date), .winter)
    }

    func testCurrentSeason_april_isSpring() {
        let date = makeDate(month: 4, day: 10)
        XCTAssertEqual(SeasonalPromptProvider.currentSeason(for: date), .spring)
    }

    func testCurrentSeason_july_isSummer() {
        let date = makeDate(month: 7, day: 4)
        XCTAssertEqual(SeasonalPromptProvider.currentSeason(for: date), .summer)
    }

    func testCurrentSeason_october_isAutumn() {
        let date = makeDate(month: 10, day: 1)
        XCTAssertEqual(SeasonalPromptProvider.currentSeason(for: date), .autumn)
    }

    func testCurrentSeason_december_isWinter() {
        let date = makeDate(month: 12, day: 15)
        XCTAssertEqual(SeasonalPromptProvider.currentSeason(for: date), .winter)
    }

    // MARK: - Holiday detection

    func testNearbyHoliday_newYearsDay_returnsNewYear() {
        let date = makeDate(month: 1, day: 1)
        XCTAssertEqual(SeasonalPromptProvider.nearbyHoliday(for: date), .newYear)
    }

    func testNearbyHoliday_feb14_returnsValentines() {
        let date = makeDate(month: 2, day: 14)
        XCTAssertEqual(SeasonalPromptProvider.nearbyHoliday(for: date), .valentines)
    }

    func testNearbyHoliday_mar17_returnsStPatricks() {
        let date = makeDate(month: 3, day: 17)
        XCTAssertEqual(SeasonalPromptProvider.nearbyHoliday(for: date), .stPatricks)
    }

    func testNearbyHoliday_apr22_returnsEarthDay() {
        let date = makeDate(month: 4, day: 22)
        XCTAssertEqual(SeasonalPromptProvider.nearbyHoliday(for: date), .earthDay)
    }

    func testNearbyHoliday_oct31_returnsHalloween() {
        let date = makeDate(month: 10, day: 31)
        XCTAssertEqual(SeasonalPromptProvider.nearbyHoliday(for: date), .halloween)
    }

    func testNearbyHoliday_nov25_returnsThanksgiving() {
        let date = makeDate(month: 11, day: 25)
        XCTAssertEqual(SeasonalPromptProvider.nearbyHoliday(for: date), .thanksgiving)
    }

    func testNearbyHoliday_dec25_returnsChristmas() {
        let date = makeDate(month: 12, day: 25)
        XCTAssertEqual(SeasonalPromptProvider.nearbyHoliday(for: date), .christmas)
    }

    func testNearbyHoliday_midMarch_returnsNil() {
        let date = makeDate(month: 3, day: 5)
        XCTAssertNil(SeasonalPromptProvider.nearbyHoliday(for: date))
    }

    func testNearbyHoliday_midJune_returnsNil() {
        let date = makeDate(month: 6, day: 10)
        XCTAssertNil(SeasonalPromptProvider.nearbyHoliday(for: date))
    }

    // MARK: - Seasonal result

    func testGetSeasonalPrompts_returnsThreePrompts() {
        let date = makeDate(month: 7, day: 15) // mid-summer, no holiday
        let result = SeasonalPromptProvider.getSeasonalPrompts(for: date)
        XCTAssertEqual(result.prompts.count, 3)
    }

    func testGetSeasonalPrompts_summerTitle() {
        let date = makeDate(month: 7, day: 15)
        let result = SeasonalPromptProvider.getSeasonalPrompts(for: date)
        XCTAssertEqual(result.title, "Summer Inspiration")
    }

    func testGetSeasonalPrompts_holidayTakesPriority() {
        let date = makeDate(month: 10, day: 31)
        let result = SeasonalPromptProvider.getSeasonalPrompts(for: date)
        XCTAssertEqual(result.title, "Halloween Inspiration")
    }

    func testGetSeasonalPrompts_promptsHaveDeterministicIds() {
        let date = makeDate(month: 4, day: 10)
        let result1 = SeasonalPromptProvider.getSeasonalPrompts(for: date)
        let result2 = SeasonalPromptProvider.getSeasonalPrompts(for: date)
        XCTAssertEqual(result1.prompts.map(\.id), result2.prompts.map(\.id))
    }

    func testGetSeasonalPrompts_promptsHaveSlugs() {
        let date = makeDate(month: 1, day: 15)
        let result = SeasonalPromptProvider.getSeasonalPrompts(for: date)
        for prompt in result.prompts {
            XCTAssertNotNil(prompt.slug)
            XCTAssertTrue(prompt.slug?.hasPrefix("seasonal-") ?? false)
        }
    }

    func testGetSeasonalPrompts_allSeasonsReturnPrompts() {
        let dates = [
            makeDate(month: 1, day: 15),  // winter (no holiday)
            makeDate(month: 4, day: 10),  // spring (no holiday)
            makeDate(month: 7, day: 15),  // summer
            makeDate(month: 10, day: 5),  // autumn (no holiday)
        ]
        for date in dates {
            let result = SeasonalPromptProvider.getSeasonalPrompts(for: date)
            XCTAssertEqual(result.prompts.count, 3, "Expected 3 prompts for date \(date)")
            XCTAssertFalse(result.title.isEmpty)
            XCTAssertFalse(result.icon.isEmpty)
        }
    }

    func testGetSeasonalPrompts_allHolidaysReturnPrompts() {
        let holidayDates = [
            makeDate(month: 1, day: 1),   // New Year
            makeDate(month: 2, day: 14),  // Valentine's
            makeDate(month: 3, day: 17),  // St. Patrick's
            makeDate(month: 4, day: 22),  // Earth Day
            makeDate(month: 10, day: 31), // Halloween
            makeDate(month: 11, day: 25), // Thanksgiving
            makeDate(month: 12, day: 25), // Christmas
        ]
        for date in holidayDates {
            let result = SeasonalPromptProvider.getSeasonalPrompts(for: date)
            XCTAssertEqual(result.prompts.count, 3, "Expected 3 prompts for holiday date \(date)")
        }
    }

    // MARK: - Helpers

    private func makeDate(month: Int, day: Int, year: Int = 2026) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }
}
