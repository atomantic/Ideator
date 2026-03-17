import Foundation
import SwiftUI

enum Category: String, CaseIterable, Codable {
    case personalDevelopment = "Personal Development"
    case professional = "Professional"
    case creative = "Creative"
    case lifestyle = "Lifestyle"
    case relationships = "Relationships"
    case entertainment = "Entertainment"
    case travel = "Travel & Adventure"
    case learning = "Learning & Skills"
    case financial = "Financial"
    case socialImpact = "Social Impact"
    case health = "Health & Fitness"
    case mindfulness = "Mindfulness"
    case selfCare = "Self Care"
    case gratitude = "Gratitude"
    case custom = "Custom"
    
    var icon: String {
        switch self {
        case .personalDevelopment: return "person.crop.circle.badge.checkmark"
        case .professional: return "briefcase.fill"
        case .creative: return "paintbrush.fill"
        case .lifestyle: return "heart.fill"
        case .relationships: return "person.2.fill"
        case .entertainment: return "tv.fill"
        case .travel: return "airplane"
        case .learning: return "book.fill"
        case .financial: return "dollarsign.circle.fill"
        case .socialImpact: return "globe.americas.fill"
        case .health: return "heart.circle.fill"
        case .mindfulness: return "leaf.fill"
        case .selfCare: return "sparkles"
        case .gratitude: return "hands.sparkles"
        case .custom: return "sparkles.rectangle.stack"
        }
    }
    
    var color: String {
        switch self {
        case .personalDevelopment: return "blue"
        case .professional: return "purple"
        case .creative: return "orange"
        case .lifestyle: return "pink"
        case .relationships: return "red"
        case .entertainment: return "yellow"
        case .travel: return "green"
        case .learning: return "indigo"
        case .financial: return "mint"
        case .socialImpact: return "teal"
        case .health: return "red"
        case .mindfulness: return "green"
        case .selfCare: return "purple"
        case .gratitude: return "orange"
        case .custom: return "purple"
        }
    }
    
    var colorValue: Color {
        Color.from(name: color)
    }
}