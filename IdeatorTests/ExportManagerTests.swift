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
}
