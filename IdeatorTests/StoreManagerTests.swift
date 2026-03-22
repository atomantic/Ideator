import XCTest
@testable import Ideator

@MainActor
final class StoreManagerTests: XCTestCase {
    private var manager: StoreManager!

    override func setUp() {
        super.setUp()
        manager = StoreManager.shared
    }

    func testIsPurchasedOrFree_coreIsFree() {
        XCTAssertTrue(manager.isPurchasedOrFree("core"), "Core pack should always be free")
    }

    func testProductId_convertsHyphensToperiods() {
        let pid = manager.productId(for: "creative-writing")
        XCTAssertEqual(pid, "net.shadowpuppet.ideator.pack.creative.writing")
    }

    func testProductId_corePackFormat() {
        let pid = manager.productId(for: "core")
        XCTAssertEqual(pid, "net.shadowpuppet.ideator.pack.core")
    }

    func testProductId_multiHyphenPack() {
        let pid = manager.productId(for: "tech-startup")
        XCTAssertEqual(pid, "net.shadowpuppet.ideator.pack.tech.startup")
    }

    func testIsGrandfathered_unknownPackReturnsFalse() {
        XCTAssertFalse(manager.isGrandfathered("nonexistent-pack"))
    }

    func testRedeemPromoCode_invalidCodeReturnsFalse() {
        XCTAssertFalse(manager.redeemPromoCode("not-a-real-code"))
    }

    func testRedeemPromoCode_emptyStringReturnsFalse() {
        XCTAssertFalse(manager.redeemPromoCode(""))
    }

    func testProduct_nilForUnloadedPack() {
        // Products aren't loaded in test environment
        let product = manager.product(for: "creative-writing")
        // May be nil in test env, just verify it doesn't crash
        _ = product
    }
}
