import XCTest
@testable import Ideator

final class ModelTests: XCTestCase {

    // MARK: - Prompt

    func testPrompt_deterministicId_isConsistent() {
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: "test", packName: "Test Pack")
        let prompt1 = Prompt(text: "Make tea", flexibleCategory: cat)
        let prompt2 = Prompt(text: "Make tea", flexibleCategory: cat)
        XCTAssertEqual(prompt1.id, prompt2.id)
    }

    func testPrompt_slugBasedId_differsFromTextBasedId() {
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: "test", packName: "Test Pack")
        let textBased = Prompt(text: "Make tea", flexibleCategory: cat, slug: nil)
        let slugBased = Prompt(text: "Make tea", flexibleCategory: cat, slug: "make-tea")
        XCTAssertNotEqual(textBased.id, slugBased.id)
    }

    func testPrompt_formattedTitle_returnsText() {
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: nil, packName: nil)
        let prompt = Prompt(text: "Write a poem", flexibleCategory: cat)
        XCTAssertEqual(prompt.formattedTitle, "Write a poem")
    }

    // MARK: - IdeaList progress

    func testIdeaList_progress_zeroIdeas() {
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: nil, packName: nil)
        let prompt = Prompt(text: "Ideas", flexibleCategory: cat, suggestedCount: 10)
        let list = IdeaList(prompt: prompt, ideas: [])
        XCTAssertEqual(list.progress, 0.0, accuracy: 0.001)
    }

    func testIdeaList_progress_partialIdeas() {
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: nil, packName: nil)
        let prompt = Prompt(text: "Ideas", flexibleCategory: cat, suggestedCount: 10)
        let list = IdeaList(prompt: prompt, ideas: ["One", "Two", "", "Four", ""])
        // 3 non-empty out of 10
        XCTAssertEqual(list.progress, 0.3, accuracy: 0.001)
    }

    func testIdeaList_progress_fullIdeas() {
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: nil, packName: nil)
        let prompt = Prompt(text: "Ideas", flexibleCategory: cat, suggestedCount: 3)
        let list = IdeaList(prompt: prompt, ideas: ["One", "Two", "Three"])
        XCTAssertEqual(list.progress, 1.0, accuracy: 0.001)
    }

    func testIdeaList_formattedForExport_containsExpectedSections() {
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: nil, packName: nil)
        let prompt = Prompt(text: "Best books", flexibleCategory: cat)
        let list = IdeaList(prompt: prompt, ideas: ["Dune", "", "Foundation"])
        let export = list.formattedForExport

        XCTAssertTrue(export.contains("Idea Loom List: Best books"))
        XCTAssertTrue(export.contains("Category: Test"))
        XCTAssertTrue(export.contains("1. Dune"))
        XCTAssertTrue(export.contains("3. Foundation"))
        // Empty ideas should be skipped
        XCTAssertFalse(export.contains("2. "))
    }

    // MARK: - Category

    func testCategory_icon_returnsExpectedValues() {
        XCTAssertEqual(Category.creative.icon, "paintbrush.fill")
        XCTAssertEqual(Category.travel.icon, "airplane")
        XCTAssertEqual(Category.financial.icon, "dollarsign.circle.fill")
        XCTAssertEqual(Category.custom.icon, "sparkles.rectangle.stack")
    }

    func testCategory_color_returnsExpectedValues() {
        XCTAssertEqual(Category.creative.color, "orange")
        XCTAssertEqual(Category.professional.color, "purple")
        XCTAssertEqual(Category.travel.color, "green")
        XCTAssertEqual(Category.personalDevelopment.color, "blue")
    }

    func testCategory_colorValue_allCasesHaveNonEmptyColorString() {
        for category in Category.allCases {
            XCTAssertFalse(category.color.isEmpty, "\(category.rawValue) should have a non-empty color string")
            // Verify colorValue computes without crash for every case
            _ = category.colorValue
        }
    }

    // MARK: - FlexibleCategory

    func testFlexibleCategory_fromCategory_setsCorrectFields() {
        let flex = FlexibleCategory.from(category: .creative)
        XCTAssertEqual(flex.name, "Creative")
        XCTAssertEqual(flex.icon, "paintbrush.fill")
        XCTAssertEqual(flex.color, "orange")
        XCTAssertNil(flex.packId)
        XCTAssertNil(flex.packName)
        XCTAssertEqual(flex.id, "creative")
    }

    func testFlexibleCategory_fromCategory_travelAdventure_removesSpecialChars() {
        let flex = FlexibleCategory.from(category: .travel)
        XCTAssertEqual(flex.id, "traveladventure")
        XCTAssertEqual(flex.name, "Travel & Adventure")
    }

    func testFlexibleCategory_fromPackCategory_setsPackInfo() {
        let packCat = PackCategory(id: "mvp", name: "MVP Ideas", file: "mvp.tsv", icon: "rocket", color: "orange")
        let flex = FlexibleCategory.from(packCategory: packCat, packId: "startup", packName: "Tech Startup")
        XCTAssertEqual(flex.id, "startup.mvp")
        XCTAssertEqual(flex.name, "MVP Ideas")
        XCTAssertEqual(flex.packId, "startup")
        XCTAssertEqual(flex.packName, "Tech Startup")
    }

    @MainActor func testFlexibleCategory_allCategories_isNonEmpty_withCustomFirst() {
        let categories = FlexibleCategory.allCategories()
        XCTAssertGreaterThan(categories.count, 0)
        XCTAssertEqual(categories[0].name, "Custom")
    }
}
