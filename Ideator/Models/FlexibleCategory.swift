import Foundation
import SwiftUI

extension Color {
    /// Convert a color name string to a SwiftUI Color.
    static func from(name: String) -> Color {
        switch name.lowercased() {
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        case "red": return .red
        case "yellow": return .yellow
        case "green": return .green
        case "indigo": return .indigo
        case "mint": return .mint
        case "teal": return .teal
        case "brown": return .brown
        case "gray", "grey": return .gray
        default: return .blue
        }
    }
}

// A flexible category that can represent both built-in and pack categories
struct FlexibleCategory: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let icon: String
    let color: String
    let packId: String? // nil for core categories
    let packName: String? // nil for core categories
    
    var colorValue: Color {
        Color.from(name: color)
    }
    
    // Create from built-in Category enum
    static func from(category: Category) -> FlexibleCategory {
        FlexibleCategory(
            id: category.rawValue.lowercased().replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "&", with: ""),
            name: category.rawValue,
            icon: category.icon,
            color: category.color,
            packId: nil,
            packName: nil
        )
    }
    
    // Create from PackCategory
    static func from(packCategory: PackCategory, packId: String, packName: String) -> FlexibleCategory {
        FlexibleCategory(
            id: "\(packId).\(packCategory.id)",
            name: packCategory.name,
            icon: packCategory.icon,
            color: packCategory.color,
            packId: packId,
            packName: packName
        )
    }
    
    /// Returns all available categories: Custom first, then installed pack categories, sorted by name.
    static func allCategories() -> [FlexibleCategory] {
        var categories: [FlexibleCategory] = []
        var addedIds = Set<String>()

        // Add Custom category first
        let customCategory = FlexibleCategory.from(category: .custom)
        categories.append(customCategory)
        addedIds.insert(customCategory.id)

        // Add all core categories
        for category in Category.allCases where category != .custom {
            let flex = FlexibleCategory.from(category: category)
            if !addedIds.contains(flex.id) {
                categories.append(flex)
                addedIds.insert(flex.id)
            }
        }

        // Add pack categories from installed packs
        let packManager = PackManager.shared
        for pack in packManager.installedPacks where pack.isEnabled {
            for category in pack.categories {
                if !addedIds.contains(category.id) {
                    categories.append(FlexibleCategory(
                        id: category.id,
                        name: category.name,
                        icon: category.icon,
                        color: category.color,
                        packId: pack.id,
                        packName: pack.id == "core" ? nil : pack.name
                    ))
                    addedIds.insert(category.id)
                }
            }
        }

        // Sort all except Custom (which stays first)
        guard let customFirst = categories.first else { return categories }
        let rest = Array(categories.dropFirst()).sorted { $0.name < $1.name }
        return [customFirst] + rest
    }

    // Try to convert to built-in Category enum (for backwards compatibility)
    func toCategory() -> Category? {
        // Remove pack prefix if present
        let categoryId = packId != nil ? String(id.dropFirst(packId!.count + 1)) : id
        
        switch categoryId {
        case "personaldevelopment": return .personalDevelopment
        case "professional": return .professional
        case "creative": return .creative
        case "lifestyle": return .lifestyle
        case "relationships": return .relationships
        case "entertainment": return .entertainment
        case "traveladventure", "travel": return .travel
        case "learningskills", "learning": return .learning
        case "financial": return .financial
        case "socialimpact": return .socialImpact
        case "healthfitness", "health": return .health
        case "mindfulness": return .mindfulness
        case "selfcare": return .selfCare
        case "gratitude": return .gratitude
        default: return nil
        }
    }
}