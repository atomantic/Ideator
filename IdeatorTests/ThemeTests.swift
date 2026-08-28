import XCTest
import SwiftUI
@testable import Ideator

final class ThemeTests: XCTestCase {

    // MARK: - Radius scale

    func testRadius_scaleIsMonotonicallyIncreasing() {
        let scale: [CGFloat] = [
            Theme.Radius.xs,
            Theme.Radius.chip,
            Theme.Radius.inset,
            Theme.Radius.button,
            Theme.Radius.card,
            Theme.Radius.large,
            Theme.Radius.xl,
            Theme.Radius.pill
        ]
        for i in 1..<scale.count {
            XCTAssertGreaterThan(
                scale[i],
                scale[i - 1],
                "Theme.Radius scale must be strictly increasing — found \(scale[i - 1]) followed by \(scale[i]) at index \(i)"
            )
        }
    }

    func testRadius_cardIsTwelve() {
        // Primary card token is the most-referenced value across the app —
        // pin it so accidental drift fails loudly in tests.
        XCTAssertEqual(Theme.Radius.card, 12)
    }

    func testRadius_xsIsTwo() {
        XCTAssertEqual(Theme.Radius.xs, 2)
    }

    func testRadius_pillIsTwentyFour() {
        XCTAssertEqual(Theme.Radius.pill, 24)
    }

    // MARK: - Spacing scale

    func testSpacing_scaleIsMonotonicallyIncreasing() {
        let scale: [CGFloat] = [
            Theme.Spacing.xxs,
            Theme.Spacing.xs,
            Theme.Spacing.sm,
            Theme.Spacing.md,
            Theme.Spacing.lg,
            Theme.Spacing.xl,
            Theme.Spacing.xxl
        ]
        for i in 1..<scale.count {
            XCTAssertGreaterThan(
                scale[i],
                scale[i - 1],
                "Theme.Spacing scale must be strictly increasing — found \(scale[i - 1]) followed by \(scale[i]) at index \(i)"
            )
        }
    }

    func testSpacing_smIsEight() {
        XCTAssertEqual(Theme.Spacing.sm, 8)
    }

    func testSpacing_mdIsTwelve() {
        XCTAssertEqual(Theme.Spacing.md, 12)
    }

    // MARK: - Hit-target accessibility

    func testHit_minMeetsAccessibilityFloor() {
        // Apple HIG / WCAG recommend a 44pt minimum hit target.
        XCTAssertGreaterThanOrEqual(
            Theme.Hit.min,
            44,
            "Theme.Hit.min must meet the 44pt accessibility floor"
        )
    }

    // MARK: - Surface colors

    func testSurface_cardIsNotClear() {
        // Sanity: a surface token must not be `.clear`, otherwise cards
        // would silently disappear on refactors.
        XCTAssertNotEqual(Theme.Surface.card, Color.clear)
        XCTAssertNotEqual(Theme.Surface.grouped, Color.clear)
        XCTAssertNotEqual(Theme.Surface.tertiary, Color.clear)
    }
}
