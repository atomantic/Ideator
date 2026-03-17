import XCTest
@testable import Ideator

final class UUIDDeterministicTests: XCTestCase {
    func testUUIDDeterminism() {
        let s1 = "hello_world"
        let s2 = "hello_world"
        let uuid1 = s1.uuidFromString()
        let uuid2 = s2.uuidFromString()
        XCTAssertEqual(uuid1, uuid2)
        // Different input should yield different UUIDs
        let uuid3 = "hello_world2".uuidFromString()
        XCTAssertNotEqual(uuid1, uuid3)
    }

    func testUUIDFormat_matches8_4_4_4_12() {
        let result = "test_input".uuidFromString()
        let pattern = "^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(result.startIndex..., in: result)
        let matchCount = regex?.numberOfMatches(in: result, range: range) ?? 0
        XCTAssertEqual(matchCount, 1, "UUID '\(result)' does not match expected format 8-4-4-4-12")
    }

    func testEmptyString_producesValidUUID() {
        let result = "".uuidFromString()
        XCTAssertNotNil(UUID(uuidString: result), "Empty string should still produce a valid UUID, got '\(result)'")
    }
}

