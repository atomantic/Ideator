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
}

