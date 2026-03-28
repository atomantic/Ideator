import XCTest
@testable import Ideator

final class ExportManagerTests: XCTestCase {
    private let manager = ExportManager.shared

    private func makeIdeaList(ideas: [String] = ["First idea", "Second idea", ""]) -> IdeaList {
        let prompt = Prompt(text: "things to test", category: .creative, slug: "things-to-test")
        return IdeaList(prompt: prompt, ideas: ideas)
    }

    // MARK: - Text Export

    func testExportAsText_containsTitle() {
        let list = makeIdeaList()
        let text = manager.exportAsText(list)
        XCTAssertTrue(text.contains("things to test"))
    }

    func testExportAsText_containsCategory() {
        let list = makeIdeaList()
        let text = manager.exportAsText(list)
        XCTAssertTrue(text.contains("Category:"))
    }

    func testExportAsText_skipsEmptyIdeas() {
        let list = makeIdeaList(ideas: ["Good idea", "", "Another idea"])
        let text = manager.exportAsText(list)
        XCTAssertTrue(text.contains("1. Good idea"))
        XCTAssertTrue(text.contains("3. Another idea"))
        XCTAssertFalse(text.contains("2. \n"), "Empty ideas should be skipped")
    }

    func testExportAsText_numbersIdeasCorrectly() {
        let list = makeIdeaList(ideas: ["Alpha", "Beta"])
        let text = manager.exportAsText(list)
        XCTAssertTrue(text.contains("1. Alpha"))
        XCTAssertTrue(text.contains("2. Beta"))
    }

    // MARK: - Markdown Export

    func testExportAsMarkdown_hasMarkdownHeader() {
        let list = makeIdeaList()
        let md = manager.exportAsMarkdown(list)
        XCTAssertTrue(md.hasPrefix("# "), "Markdown should start with H1 header")
    }

    func testExportAsMarkdown_containsBoldCategory() {
        let list = makeIdeaList()
        let md = manager.exportAsMarkdown(list)
        XCTAssertTrue(md.contains("**Category:**"))
    }

    func testExportAsMarkdown_containsIdeasSection() {
        let list = makeIdeaList()
        let md = manager.exportAsMarkdown(list)
        XCTAssertTrue(md.contains("## Ideas"))
    }

    func testExportAsMarkdown_skipsEmptyIdeas() {
        let list = makeIdeaList(ideas: ["Idea A", "", "Idea C"])
        let md = manager.exportAsMarkdown(list)
        XCTAssertTrue(md.contains("1. Idea A"))
        XCTAssertTrue(md.contains("3. Idea C"))
        XCTAssertFalse(md.contains("2. \n"))
    }

    func testExportAsMarkdown_emptyList_hasNoNumberedItems() {
        let list = makeIdeaList(ideas: [])
        let md = manager.exportAsMarkdown(list)
        XCTAssertTrue(md.contains("## Ideas"))
        XCTAssertFalse(md.contains("1."))
    }

    // MARK: - Best Ideas Export

    func testExportBestIdeas_emptyReturnsEmpty() {
        let result = manager.exportBestIdeas([])
        XCTAssertEqual(result, "")
    }

    func testExportBestIdeas_containsTitle() {
        let items = [(ideaText: "Great idea", promptText: "Test prompt", categoryName: "Creative")]
        let result = manager.exportBestIdeas(items)
        XCTAssertTrue(result.contains("My Best Ideas"))
    }

    func testExportBestIdeas_groupsByCategory() {
        let items = [
            (ideaText: "Idea A", promptText: "Prompt 1", categoryName: "Creative"),
            (ideaText: "Idea B", promptText: "Prompt 2", categoryName: "Tech"),
            (ideaText: "Idea C", promptText: "Prompt 3", categoryName: "Creative")
        ]
        let result = manager.exportBestIdeas(items)
        XCTAssertTrue(result.contains("Creative"))
        XCTAssertTrue(result.contains("Tech"))
        XCTAssertTrue(result.contains("Idea A"))
        XCTAssertTrue(result.contains("Idea C"))
    }

    func testExportBestIdeas_showsPromptSource() {
        let items = [(ideaText: "My idea", promptText: "Source prompt", categoryName: "Fun")]
        let result = manager.exportBestIdeas(items)
        XCTAssertTrue(result.contains("→ from: Source prompt"))
    }

    func testExportBestIdeas_showsTotalCount() {
        let items = [
            (ideaText: "Idea 1", promptText: "P1", categoryName: "A"),
            (ideaText: "Idea 2", promptText: "P2", categoryName: "B")
        ]
        let result = manager.exportBestIdeas(items)
        XCTAssertTrue(result.contains("2 best ideas total"))
    }
}
