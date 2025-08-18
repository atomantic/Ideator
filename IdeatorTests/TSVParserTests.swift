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
    }
}

