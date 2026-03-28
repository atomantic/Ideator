import Foundation

/// Provides rotating creative prompts based on the current season and nearby holidays.
struct SeasonalPromptProvider {

    enum Season: String {
        case spring = "Spring"
        case summer = "Summer"
        case autumn = "Autumn"
        case winter = "Winter"

        var icon: String {
            switch self {
            case .spring: return "leaf.fill"
            case .summer: return "sun.max.fill"
            case .autumn: return "wind"
            case .winter: return "snowflake"
            }
        }

        var color: String {
            switch self {
            case .spring: return "green"
            case .summer: return "orange"
            case .autumn: return "brown"
            case .winter: return "blue"
            }
        }
    }

    enum Holiday: String {
        case newYear = "New Year"
        case valentines = "Valentine's Day"
        case stPatricks = "St. Patrick's Day"
        case earthDay = "Earth Day"
        case halloween = "Halloween"
        case thanksgiving = "Thanksgiving"
        case christmas = "Christmas"

        var icon: String {
            switch self {
            case .newYear: return "party.popper.fill"
            case .valentines: return "heart.fill"
            case .stPatricks: return "shamrock.fill"
            case .earthDay: return "globe.americas.fill"
            case .halloween: return "moon.stars.fill"
            case .thanksgiving: return "leaf.fill"
            case .christmas: return "gift.fill"
            }
        }

        var color: String {
            switch self {
            case .newYear: return "yellow"
            case .valentines: return "red"
            case .stPatricks: return "green"
            case .earthDay: return "teal"
            case .halloween: return "orange"
            case .thanksgiving: return "brown"
            case .christmas: return "red"
            }
        }
    }

    struct SeasonalResult {
        let title: String
        let icon: String
        let color: String
        let prompts: [Prompt]
    }

    static func currentSeason(for date: Date = Date()) -> Season {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .autumn
        default: return .winter
        }
    }

    static func nearbyHoliday(for date: Date = Date()) -> Holiday? {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        switch (month, day) {
        case (12, 26...31), (1, 1...6): return .newYear
        case (2, 8...14): return .valentines
        case (3, 11...17): return .stPatricks
        case (4, 16...22): return .earthDay
        case (10, 25...31): return .halloween
        case (11, 21...28): return .thanksgiving
        case (12, 18...25): return .christmas
        default: return nil
        }
    }

    static func getSeasonalPrompts(for date: Date = Date()) -> SeasonalResult {
        if let holiday = nearbyHoliday(for: date) {
            return holidayPrompts(for: holiday)
        }
        return seasonPrompts(for: currentSeason(for: date))
    }

    // MARK: - Season prompts

    private static func seasonPrompts(for season: Season) -> SeasonalResult {
        let category = FlexibleCategory(
            id: "seasonal-\(season.rawValue.lowercased())",
            name: "\(season.rawValue) Inspiration",
            icon: season.icon,
            color: season.color,
            packId: nil,
            packName: nil
        )

        let texts: [(String, String?, String)] // (text, help, slug)
        switch season {
        case .spring:
            texts = [
                ("things I want to plant or grow this spring", "gardens, habits, or projects", "seasonal-spring-grow"),
                ("ways to refresh my daily routine", "shake off winter and try something new", "seasonal-spring-refresh"),
                ("outdoor activities to try before summer", nil, "seasonal-spring-outdoor"),
            ]
        case .summer:
            texts = [
                ("adventures to have this summer", "big or small, local or far", "seasonal-summer-adventures"),
                ("skills I could learn while the days are long", nil, "seasonal-summer-skills"),
                ("ways to make the most of warm evenings", nil, "seasonal-summer-evenings"),
            ]
        case .autumn:
            texts = [
                ("cozy rituals to start this fall", "drinks, reads, routines", "seasonal-autumn-rituals"),
                ("things I want to finish before the year ends", nil, "seasonal-autumn-finish"),
                ("creative projects inspired by the changing seasons", nil, "seasonal-autumn-creative"),
            ]
        case .winter:
            texts = [
                ("ways to stay creative during the dark months", nil, "seasonal-winter-creative"),
                ("indoor hobbies I've been meaning to try", nil, "seasonal-winter-hobbies"),
                ("things that bring me warmth and comfort", "people, places, rituals", "seasonal-winter-warmth"),
            ]
        }

        let prompts = texts.map { text, help, slug in
            Prompt(text: text, flexibleCategory: category, help: help, slug: slug)
        }

        return SeasonalResult(
            title: "\(season.rawValue) Inspiration",
            icon: season.icon,
            color: season.color,
            prompts: prompts
        )
    }

    // MARK: - Holiday prompts

    private static func holidayPrompts(for holiday: Holiday) -> SeasonalResult {
        let category = FlexibleCategory(
            id: "seasonal-\(holiday.rawValue.lowercased().replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "'", with: ""))",
            name: "\(holiday.rawValue) Inspiration",
            icon: holiday.icon,
            color: holiday.color,
            packId: nil,
            packName: nil
        )

        let texts: [(String, String?, String)]
        switch holiday {
        case .newYear:
            texts = [
                ("things I want to leave behind in the old year", nil, "seasonal-newyear-leave"),
                ("adventures I want to have this year", nil, "seasonal-newyear-adventures"),
                ("small daily habits that could change everything", nil, "seasonal-newyear-habits"),
            ]
        case .valentines:
            texts = [
                ("ways to show love to the people in my life", "not just romantic", "seasonal-valentines-love"),
                ("things I appreciate about myself", nil, "seasonal-valentines-self"),
                ("unexpected acts of kindness I could do this week", nil, "seasonal-valentines-kindness"),
            ]
        case .stPatricks:
            texts = [
                ("things that make me feel lucky", nil, "seasonal-stpatricks-lucky"),
                ("risks worth taking this month", nil, "seasonal-stpatricks-risks"),
                ("green things I could add to my life", "food, nature, sustainability", "seasonal-stpatricks-green"),
            ]
        case .earthDay:
            texts = [
                ("ways I could reduce my environmental footprint", nil, "seasonal-earthday-footprint"),
                ("nature experiences I want to have", nil, "seasonal-earthday-nature"),
                ("inventions that could help the planet", nil, "seasonal-earthday-inventions"),
            ]
        case .halloween:
            texts = [
                ("fears I could turn into creative fuel", nil, "seasonal-halloween-fears"),
                ("spooky story premises I'd love to read", nil, "seasonal-halloween-stories"),
                ("costumes or alter egos I'd want to try", nil, "seasonal-halloween-costumes"),
            ]
        case .thanksgiving:
            texts = [
                ("things I'm grateful for that I usually overlook", nil, "seasonal-thanksgiving-grateful"),
                ("people who shaped who I am today", nil, "seasonal-thanksgiving-people"),
                ("traditions I'd love to start", nil, "seasonal-thanksgiving-traditions"),
            ]
        case .christmas:
            texts = [
                ("thoughtful gifts that don't cost money", nil, "seasonal-christmas-gifts"),
                ("memories from past holidays that make me smile", nil, "seasonal-christmas-memories"),
                ("ways to spread joy to strangers", nil, "seasonal-christmas-joy"),
            ]
        }

        let prompts = texts.map { text, help, slug in
            Prompt(text: text, flexibleCategory: category, help: help, slug: slug)
        }

        return SeasonalResult(
            title: "\(holiday.rawValue) Inspiration",
            icon: holiday.icon,
            color: holiday.color,
            prompts: prompts
        )
    }
}
