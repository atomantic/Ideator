import XCTest
@testable import Ideator

final class TSVParserTests: XCTestCase {
    func testParseOneColumnTSV() {
        let tsv = """
        text
        Test prompt one
        Another idea
        """
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: "test", packName: "Test Pack")
        let prompts = TSVParser.parse(tsv: tsv, flexibleCategory: cat)
        XCTAssertEqual(prompts.count, 2)
        XCTAssertEqual(prompts[0].text, "Test prompt one")
        XCTAssertEqual(prompts[1].text, "Another idea")
        XCTAssertNil(prompts[0].help)
    }

    func testParseTwoColumnTSV() {
        let tsv = """
        text\thelp
        Make tea\t(e.g., with lemon)
        Read book\t(e.g., 10 minutes)
        """
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: "test", packName: "Test Pack")
        let prompts = TSVParser.parse(tsv: tsv, flexibleCategory: cat)
        XCTAssertEqual(prompts.count, 2)
        XCTAssertEqual(prompts[0].text, "Make tea")
        XCTAssertEqual(prompts[0].help, "(e.g., with lemon)")
        XCTAssertNil(prompts[0].slug)
    }

    func testParseThreeColumnTSVWithSlug() {
        let tsv = """
        text\thelp\tslug
        Make tea\t(e.g., with lemon)\tmake-tea
        Read book\t(e.g., 10 minutes)\tread-book
        """
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: "test", packName: "Test Pack")
        let prompts = TSVParser.parse(tsv: tsv, flexibleCategory: cat)
        XCTAssertEqual(prompts.count, 2)
        XCTAssertEqual(prompts[0].slug, "make-tea")
        XCTAssertEqual(prompts[1].slug, "read-book")
        XCTAssertEqual(prompts[0].text, "Make tea")
        XCTAssertEqual(prompts[0].help, "(e.g., with lemon)")
    }

    func testSlugBasedUUIDDiffersFromTextBasedUUID() {
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: "test", packName: "Test Pack")
        let withoutSlug = Prompt(text: "Make tea", flexibleCategory: cat)
        let withSlug = Prompt(text: "Make tea", flexibleCategory: cat, slug: "make-tea")
        XCTAssertNotEqual(withoutSlug.id, withSlug.id)
    }

    func testParseEmptyTSV_headerOnly_returnsNoPrompts() {
        let tsv = """
        text\thelp\tslug
        """
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: "test", packName: "Test Pack")
        let prompts = TSVParser.parse(tsv: tsv, flexibleCategory: cat)
        XCTAssertEqual(prompts.count, 0)
    }

    func testParseExtraColumns_ignoresExtra() {
        let tsv = """
        text\thelp\tslug\textra
        Make tea\t(e.g., lemon)\tmake-tea\tignored
        """
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: "test", packName: "Test Pack")
        let prompts = TSVParser.parse(tsv: tsv, flexibleCategory: cat)
        XCTAssertEqual(prompts.count, 1)
        XCTAssertEqual(prompts[0].text, "Make tea")
        XCTAssertEqual(prompts[0].slug, "make-tea")
    }

    func testParseEmptySlug_treatedAsNil() {
        let tsv = """
        text\thelp\tslug
        Make tea\t(e.g., lemon)\t
        """
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: "test", packName: "Test Pack")
        let prompts = TSVParser.parse(tsv: tsv, flexibleCategory: cat)
        XCTAssertEqual(prompts.count, 1)
        XCTAssertNil(prompts[0].slug)
    }

    func testSlugBasedUUIDisDeterministic() {
        let cat = FlexibleCategory(id: "test.cat", name: "Test", icon: "star", color: "blue", packId: "test", packName: "Test Pack")
        let prompt1 = Prompt(text: "Make tea", flexibleCategory: cat, slug: "make-tea")
        let prompt2 = Prompt(text: "Brew a cup of tea", flexibleCategory: cat, slug: "make-tea")
        XCTAssertEqual(prompt1.id, prompt2.id, "Same slug should produce same UUID regardless of text")
    }
}

