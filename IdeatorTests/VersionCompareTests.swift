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

    func testEqualVersions_returnsNotNewer() {
        let pm = PackManager.shared
        XCTAssertFalse(pm.isNewerVersion("1.0.0", than: "1.0.0"))
        XCTAssertFalse(pm.isNewerVersion("2.5.3", than: "2.5.3"))
    }

    func testEmptyVersionStrings() {
        let pm = PackManager.shared
        XCTAssertFalse(pm.isNewerVersion("", than: "1.0.0"))
        XCTAssertFalse(pm.isNewerVersion("", than: ""))
    }
}

