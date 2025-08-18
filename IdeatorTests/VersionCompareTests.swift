import XCTest
@testable import Ideator

final class VersionCompareTests: XCTestCase {
    func testIsNewerVersion() {
        let pm = PackManager.shared
        XCTAssertTrue(pm.isNewerVersion("1.0.1", than: "1.0.0"))
        XCTAssertFalse(pm.isNewerVersion("1.0.0", than: "1.0.1"))
        XCTAssertTrue(pm.isNewerVersion("1.2.0", than: "1.1.9"))
        XCTAssertFalse(pm.isNewerVersion("1.0", than: "1.0.0"))
        XCTAssertTrue(pm.isNewerVersion("2.0", than: "1.9.9"))
    }
}

