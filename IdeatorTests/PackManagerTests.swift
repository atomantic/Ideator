import XCTest
@testable import Ideator

@MainActor
final class PackManagerTests: XCTestCase {
    private var manager: PackManager!

    override func setUp() {
        super.setUp()
        manager = PackManager.shared
    }

    func testLoadAllPacks_populatesPacks() {
        XCTAssertFalse(manager.allPacks.isEmpty, "Should load at least one pack")
    }

    func testCorePack_isAlwaysPresent() {
        let corePack = manager.allPacks.first { $0.id == "core" }
        XCTAssertNotNil(corePack, "Core pack should always be present")
    }

    func testCorePack_hasCategories() {
        let corePack = manager.allPacks.first { $0.id == "core" }!
        XCTAssertFalse(corePack.categories.isEmpty, "Core pack should have categories")
    }

    func testPurchasedPacks_includesCore() {
        let purchased = manager.purchasedPacks
        let hasCoreId = purchased.contains { $0.id == "core" }
        XCTAssertTrue(hasCoreId, "Core should always be in purchased packs")
    }

    func testTogglePack_disablesAndEnables() {
        let packId = "core"
        let originalEnabled = manager.allPacks.first { $0.id == packId }?.isEnabled ?? true

        manager.togglePack(packId, enabled: false)
        XCTAssertFalse(manager.allPacks.first { $0.id == packId }?.isEnabled ?? true)

        manager.togglePack(packId, enabled: true)
        XCTAssertTrue(manager.allPacks.first { $0.id == packId }?.isEnabled ?? false)

        // Restore original state
        manager.togglePack(packId, enabled: originalEnabled)
    }

    func testGetEnabledCategories_returnsCategories() {
        let categories = manager.getEnabledCategories()
        XCTAssertFalse(categories.isEmpty, "Should return enabled categories from purchased packs")
    }

    func testAllPacks_haveValidManifests() {
        for pack in manager.allPacks {
            XCTAssertFalse(pack.id.isEmpty, "Pack ID should not be empty")
            XCTAssertFalse(pack.name.isEmpty, "Pack \(pack.id) should have a name")
            XCTAssertFalse(pack.categories.isEmpty, "Pack \(pack.id) should have categories")
        }
    }

    func testAllPacks_categoriesHavePromptCounts() {
        for pack in manager.allPacks {
            for category in pack.categories {
                XCTAssertGreaterThan(
                    category.promptCount ?? 0, 0,
                    "Pack \(pack.id) category \(category.id) should have prompts"
                )
            }
        }
    }
}
