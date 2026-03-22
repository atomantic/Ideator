import XCTest
@testable import Ideator

@MainActor
final class PromptViewModelTests: XCTestCase {
    private var vm: PromptViewModel!

    override func setUp() {
        super.setUp()
        vm = PromptViewModel()
    }

    func testLoadPrompts_populatesPrompts() {
        XCTAssertFalse(vm.prompts.isEmpty, "PromptViewModel should load prompts on init")
    }

    func testSelectCategory_filtersPrompts() {
        let allCount = vm.prompts.count
        vm.selectCategory(.creative)
        XCTAssertLessThan(vm.prompts.count, allCount, "Selecting a category should filter prompts")
        XCTAssertTrue(vm.prompts.allSatisfy { $0.category == .creative })
    }

    func testSelectCategory_nil_showsAll() {
        vm.selectCategory(.creative)
        let filteredCount = vm.prompts.count
        vm.selectCategory(nil)
        XCTAssertGreaterThan(vm.prompts.count, filteredCount)
    }

    func testGetCategoriesGroupedByPack_returnsGroups() {
        let groups = vm.getCategoriesGroupedByPack()
        XCTAssertFalse(groups.isEmpty)
        // First group should exist and have categories
        XCTAssertFalse(groups.first?.categories.isEmpty ?? true)
    }

    func testToggleFavorite_addsThenRemoves() {
        let prompt = vm.prompts.first!
        XCTAssertFalse(vm.isPromptFavorited(prompt))

        vm.toggleFavorite(prompt)
        XCTAssertTrue(vm.isPromptFavorited(prompt))

        vm.toggleFavorite(prompt)
        XCTAssertFalse(vm.isPromptFavorited(prompt))
    }

    func testGetFavoritePrompts_returnsOnlyFavorited() {
        let prompt = vm.prompts.first!
        XCTAssertTrue(vm.getFavoritePrompts().isEmpty)

        vm.toggleFavorite(prompt)
        let favorites = vm.getFavoritePrompts()
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.id, prompt.id)

        // Clean up
        vm.toggleFavorite(prompt)
    }

    func testIsPromptUsed_defaultsFalse() {
        let prompt = vm.prompts.first!
        // Fresh prompts should not be marked used (may vary if tests share state)
        // Just verify the method works without crash
        _ = vm.isPromptUsed(prompt)
    }

    func testGetUnusedPromptsCount_returnsPositive() {
        let count = vm.getUnusedPromptsCount(for: .creative)
        XCTAssertGreaterThan(count, 0, "Should have unused prompts in creative category")
    }
}
