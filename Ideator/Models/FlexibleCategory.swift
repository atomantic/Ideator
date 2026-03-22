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
    
    /// Returns all available categories: Custom first, then pack categories, then remaining enum categories, sorted by name.
    @MainActor static func allCategories() -> [FlexibleCategory] {
        var categories: [FlexibleCategory] = []
        var addedNames = Set<String>()

        // Add Custom category first
        let customCategory = FlexibleCategory.from(category: .custom)
        categories.append(customCategory)
        addedNames.insert(customCategory.name)

        // Add pack categories first (source of truth)
        let packManager = PackManager.shared
        for pack in packManager.purchasedPacks where pack.isEnabled {
            for category in pack.categories {
                if !addedNames.contains(category.name) {
                    categories.append(FlexibleCategory(
                        id: category.id,
                        name: category.name,
                        icon: category.icon,
                        color: category.color,
                        packId: pack.id,
                        packName: pack.id == "core" ? nil : pack.name
                    ))
                    addedNames.insert(category.name)
                }
            }
        }

        // Add remaining enum categories not covered by packs
        for category in Category.allCases where category != .custom {
            if !addedNames.contains(category.rawValue) {
                categories.append(FlexibleCategory.from(category: category))
                addedNames.insert(category.rawValue)
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
        let categoryId: String
        if let packId = packId, id.hasPrefix("\(packId).") {
            categoryId = String(id.dropFirst(packId.count + 1))
        } else {
            categoryId = id
        }
        
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