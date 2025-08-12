import Foundation
import SwiftUI

// A flexible category that can represent both built-in and pack categories
struct FlexibleCategory: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let icon: String
    let color: String
    let packId: String? // nil for core categories
    let packName: String? // nil for core categories
    
    var colorValue: Color {
        switch color.lowercased() {
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