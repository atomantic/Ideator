import XCTest
@testable import Ideator

final class CodableTests: XCTestCase {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Prompt Codable

    func testPrompt_withSlug_roundTrip() throws {
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: "test", packName: "Test Pack")
        let prompt = Prompt(text: "Make tea", flexibleCategory: cat, suggestedCount: 10, help: "(e.g., with lemon)", slug: "make-tea")

        let data = try encoder.encode(prompt)
        let decoded = try decoder.decode(Prompt.self, from: data)

        XCTAssertEqual(decoded.id, prompt.id)
        XCTAssertEqual(decoded.text, "Make tea")
        XCTAssertEqual(decoded.slug, "make-tea")
        XCTAssertEqual(decoded.help, "(e.g., with lemon)")
        XCTAssertEqual(decoded.suggestedCount, 10)
        XCTAssertEqual(decoded.flexibleCategory.id, "test.cat")
    }

    func testPrompt_withoutSlug_roundTrip() throws {
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: nil, packName: nil)
        let prompt = Prompt(text: "Read a book", flexibleCategory: cat, suggestedCount: 5, help: nil, slug: nil)

        let data = try encoder.encode(prompt)
        let decoded = try decoder.decode(Prompt.self, from: data)

        XCTAssertEqual(decoded.id, prompt.id)
        XCTAssertEqual(decoded.text, "Read a book")
        XCTAssertNil(decoded.slug)
        XCTAssertNil(decoded.help)
        XCTAssertEqual(decoded.suggestedCount, 5)
    }

    // MARK: - IdeaList Codable

    func testIdeaList_emptyIdeas_roundTrip() throws {
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: nil, packName: nil)
        let prompt = Prompt(text: "Ideas", flexibleCategory: cat)
        let list = IdeaList(prompt: prompt, ideas: [], isComplete: false)

        let data = try encoder.encode(list)
        let decoded = try decoder.decode(IdeaList.self, from: data)

        XCTAssertEqual(decoded.id, list.id)
        XCTAssertEqual(decoded.ideas.count, 0)
        XCTAssertEqual(decoded.isComplete, false)
    }

    func testIdeaList_partialIdeas_roundTrip() throws {
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: nil, packName: nil)
        let prompt = Prompt(text: "Ideas", flexibleCategory: cat)
        let list = IdeaList(prompt: prompt, ideas: ["First", "", "Third"], isComplete: false)

        let data = try encoder.encode(list)
        let decoded = try decoder.decode(IdeaList.self, from: data)

        XCTAssertEqual(decoded.ideas, ["First", "", "Third"])
        XCTAssertEqual(decoded.isComplete, false)
    }

    func testIdeaList_completeList_roundTrip() throws {
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: nil, packName: nil)
        let prompt = Prompt(text: "Ideas", flexibleCategory: cat, suggestedCount: 3)
        let ideas = ["One", "Two", "Three"]
        let list = IdeaList(prompt: prompt, ideas: ideas, isComplete: true)

        let data = try encoder.encode(list)
        let decoded = try decoder.decode(IdeaList.self, from: data)

        XCTAssertEqual(decoded.ideas, ideas)
        XCTAssertEqual(decoded.isComplete, true)
        XCTAssertEqual(decoded.prompt.text, "Ideas")
    }

    // MARK: - Category Codable

    func testCategory_allCases_roundTrip() throws {
        for category in Category.allCases {
            let data = try encoder.encode(category)
            let decoded = try decoder.decode(Category.self, from: data)
            XCTAssertEqual(decoded, category, "Round-trip failed for \(category.rawValue)")
        }
    }

    // MARK: - FlexibleCategory Codable

    func testFlexibleCategory_withPackInfo_roundTrip() throws {
        let cat = FlexibleCategory(id: "startup.mvp", name: "MVP Ideas", icon: "rocket", color: "orange", packId: "startup", packName: "Tech Startup")

        let data = try encoder.encode(cat)
        let decoded = try decoder.decode(FlexibleCategory.self, from: data)

        XCTAssertEqual(decoded.id, "startup.mvp")
        XCTAssertEqual(decoded.name, "MVP Ideas")
        XCTAssertEqual(decoded.icon, "rocket")
        XCTAssertEqual(decoded.color, "orange")
        XCTAssertEqual(decoded.packId, "startup")
        XCTAssertEqual(decoded.packName, "Tech Startup")
    }

    func testFlexibleCategory_withoutPackInfo_roundTrip() throws {
        let cat = FlexibleCategory(id: "creative", name: "Creative", icon: "paintbrush.fill", color: "orange", packId: nil, packName: nil)

        let data = try encoder.encode(cat)
        let decoded = try decoder.decode(FlexibleCategory.self, from: data)

        XCTAssertEqual(decoded.id, "creative")
        XCTAssertEqual(decoded.name, "Creative")
        XCTAssertNil(decoded.packId)
        XCTAssertNil(decoded.packName)
    }
}
