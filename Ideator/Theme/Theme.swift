import SwiftUI

/// Centralized design tokens for Idea Loom.
///
/// Use these values instead of inline literals for `cornerRadius`, padding,
/// spacing, and surface colors. Token names follow a t-shirt scale where it
/// helps (`xs`, `sm`, `md`, `lg`, `xl`) and a semantic role where it does not
/// (`Surface.card`, `Surface.grouped`).
enum Theme {

    /// Corner radii for rounded shapes.
    enum Radius {
        /// Tiny accents (e.g. confetti rectangles, heatmap cells).
        static let xs: CGFloat = 2
        /// Small chips and inline pills (e.g. progress bars, category tags).
        static let chip: CGFloat = 4
        /// Inset / nested surfaces (text fields, secondary tiles inside a card).
        static let inset: CGFloat = 8
        /// Inline action buttons.
        static let button: CGFloat = 10
        /// Default card / surface radius — the primary token used across the app.
        static let card: CGFloat = 12
        /// Hero callouts and prominent cards.
        static let large: CGFloat = 16
        /// Full-bleed banners and welcome cards.
        static let xl: CGFloat = 20
        /// Decorative pills (rare).
        static let pill: CGFloat = 24
    }

    /// Spacing values for `padding`, `spacing`, and inter-element gaps.
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    /// Semantic surface colors. Prefer these to ad-hoc `Color(UIColor.*)` calls
    /// so future theming work has a single place to land.
    enum Surface {
        /// Card / inset content background — `Color(UIColor.secondarySystemBackground)`.
        static let card: Color = Color(UIColor.secondarySystemBackground)
        /// Default screen background for grouped lists / settings — `Color(UIColor.systemGroupedBackground)`.
        static let grouped: Color = Color(UIColor.systemGroupedBackground)
        /// Subtle tertiary surface (used by raised tiles inside grouped backgrounds).
        static let tertiary: Color = Color(UIColor.tertiarySystemBackground)
    }

    /// Minimum hit-target size for interactive controls. Mirrors Apple's HIG
    /// guidance and the user's mobile-accessibility preference.
    enum Hit {
        static let min: CGFloat = 44
    }
}
