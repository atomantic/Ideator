import XCTest
@testable import Ideator

@MainActor
final class PromptServiceTests: XCTestCase {
    private var service: PromptService!

    override func setUp() {
        super.setUp()
        service = PromptService.shared
    }

    // MARK: - Prompt Loading

    func testGetPrompts_returnsNonEmpty() {
        let prompts = service.getPrompts()
        XCTAssertFalse(prompts.isEmpty, "Service should load prompts from packs")
    }

    func testGetPrompts_forCategory_filtersCorrectly() {
        let creative = service.getPrompts(for: .creative)
        XCTAssertFalse(creative.isEmpty, "Should have creative prompts")
        XCTAssertTrue(creative.allSatisfy { $0.category == .creative }, "All returned prompts should be creative category")
    }

    func testGetPrompts_forFlexibleCategory_filtersCorrectly() {
        let groups = service.getCategoriesGroupedByPack()
        guard let firstCategory = groups.first?.categories.first else {
            XCTFail("Should have at least one category")
            return
        }
        let prompts = service.getPrompts(for: firstCategory)
        XCTAssertFalse(prompts.isEmpty)
        XCTAssertTrue(prompts.allSatisfy { $0.flexibleCategory.id == firstCategory.id })
    }

    func testGetPrompts_allHaveValidIds() {
        let prompts = service.getPrompts()
        let ids = prompts.map(\.id)
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All prompt IDs should be unique")
    }

    func testGetPrompts_allHaveNonEmptyText() {
        let prompts = service.getPrompts()
        XCTAssertTrue(prompts.allSatisfy { !$0.text.isEmpty }, "All prompts should have non-empty text")
    }

    // MARK: - Random Prompt

    func testGetRandomPrompt_returnsPrompt() {
        let prompt = service.getRandomPrompt()
        XCTAssertNotNil(prompt, "Should return a random prompt")
    }

    func testGetRandomPrompt_forFlexibleCategory_returnsMatchingPrompt() {
        let groups = service.getCategoriesGroupedByPack()
        guard let firstCategory = groups.first?.categories.first else {
            XCTFail("Should have at least one category")
            return
        }
        let prompt = service.getRandomPrompt(for: firstCategory)
        XCTAssertNotNil(prompt)
        XCTAssertEqual(prompt?.flexibleCategory.id, firstCategory.id)
    }

    // MARK: - Used Prompts

    func testMarkAndUnmarkPromptAsUsed() {
        let prompt = service.getPrompts().first!
        let wasUsed = service.isPromptUsed(prompt)

        service.markPromptAsUsed(prompt)
        XCTAssertTrue(service.isPromptUsed(prompt))

        service.unmarkPromptAsUsed(prompt)
        XCTAssertFalse(service.isPromptUsed(prompt))

        // Restore original state
        if wasUsed {
            service.markPromptAsUsed(prompt)
        }
    }

    func testGetUnusedPromptsCount_decreasesAfterMarking() {
        let prompt = service.getPrompts(for: .creative).first!
        let wasUsed = service.isPromptUsed(prompt)

        if wasUsed {
            service.unmarkPromptAsUsed(prompt)
        }

        let countBefore = service.getUnusedPromptsCount(for: .creative)
        service.markPromptAsUsed(prompt)
        let countAfter = service.getUnusedPromptsCount(for: .creative)
        XCTAssertEqual(countAfter, countBefore - 1)

        // Restore
        if !wasUsed {
            service.unmarkPromptAsUsed(prompt)
        }
    }

    // MARK: - Favorites

    func testToggleFavorite_addsAndRemoves() {
        let prompt = service.getPrompts().first!
        let wasFavorited = service.isPromptFavorited(prompt)

        service.toggleFavorite(prompt)
        XCTAssertNotEqual(service.isPromptFavorited(prompt), wasFavorited)

        service.toggleFavorite(prompt)
        XCTAssertEqual(service.isPromptFavorited(prompt), wasFavorited)
    }

    func testGetFavoritePrompts_returnsOnlyFavorited() {
        let prompt = service.getPrompts().first!
        let wasFavorited = service.isPromptFavorited(prompt)

        if !wasFavorited {
            service.toggleFavorite(prompt)
        }

        let favorites = service.getFavoritePrompts()
        XCTAssertTrue(favorites.contains { $0.id == prompt.id })

        // Restore
        if !wasFavorited {
            service.toggleFavorite(prompt)
        }
    }

    func testGetFavoritePromptIds_matchesFavoritePrompts() {
        let ids = service.getFavoritePromptIds()
        let prompts = service.getFavoritePrompts()
        XCTAssertEqual(ids.count, prompts.count)
        XCTAssertTrue(prompts.allSatisfy { ids.contains($0.id) })
    }

    // MARK: - Categories Grouped By Pack

    func testGetCategoriesGroupedByPack_returnsGroups() {
        let groups = service.getCategoriesGroupedByPack()
        XCTAssertFalse(groups.isEmpty, "Should return at least one pack group")
    }

    func testGetCategoriesGroupedByPack_sortedAlphabetically() {
        let groups = service.getCategoriesGroupedByPack()
        let names = groups.compactMap(\.packName)
        let sorted = names.sorted()
        XCTAssertEqual(names, sorted, "Pack groups should be sorted alphabetically")
    }

    func testGetCategoriesGroupedByPack_allCategoriesHaveIds() {
        let groups = service.getCategoriesGroupedByPack()
        for group in groups {
            for category in group.categories {
                XCTAssertFalse(category.id.isEmpty, "Category should have non-empty id")
                XCTAssertFalse(category.name.isEmpty, "Category should have non-empty name")
            }
        }
    }

    func testGetCategoriesGroupedByPack_isCached() {
        let groups1 = service.getCategoriesGroupedByPack()
        let groups2 = service.getCategoriesGroupedByPack()
        // Same result structure
        XCTAssertEqual(groups1.count, groups2.count)
        for (g1, g2) in zip(groups1, groups2) {
            XCTAssertEqual(g1.packName, g2.packName)
            XCTAssertEqual(g1.categories.count, g2.categories.count)
        }
    }

    // MARK: - Flexible Category Unused Count

    func testGetUnusedPromptsCount_forFlexibleCategory() {
        let groups = service.getCategoriesGroupedByPack()
        guard let firstCategory = groups.first?.categories.first else {
            XCTFail("Should have at least one category")
            return
        }
        let count = service.getUnusedPromptsCount(for: firstCategory)
        let total = service.getPrompts(for: firstCategory).count
        XCTAssertLessThanOrEqual(count, total)
        XCTAssertGreaterThanOrEqual(count, 0)
    }
}
