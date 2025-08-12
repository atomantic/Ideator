import Foundation

struct Prompt: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let category: Category // Keep for backwards compatibility
    let flexibleCategory: FlexibleCategory
    let suggestedCount: Int
    
    init(
        id: UUID? = nil,
        text: String,
        category: Category,
        suggestedCount: Int = 10
    ) {
        // Generate consistent UUID based on text and category to ensure persistence
        if let providedId = id {
            self.id = providedId
        } else {
            // Create deterministic UUID from prompt text and category
            let uniqueString = "\(text)_\(category.rawValue)"
            self.id = UUID(uuidString: uniqueString.uuidFromString()) ?? UUID()
        }
        self.text = text
        self.category = category
        self.flexibleCategory = FlexibleCategory.from(category: category)
        self.suggestedCount = suggestedCount
    }
    
    init(
        id: UUID? = nil,
        text: String,
        flexibleCategory: FlexibleCategory,
        suggestedCount: Int = 10
    ) {
        // Generate consistent UUID based on text and category
        if let providedId = id {
            self.id = providedId
        } else {
            // Create deterministic UUID from prompt text and category
            let uniqueString = "\(text)_\(flexibleCategory.id)"
            self.id = UUID(uuidString: uniqueString.uuidFromString()) ?? UUID()
        }
        self.text = text
        self.category = flexibleCategory.toCategory() ?? .personalDevelopment
        self.flexibleCategory = flexibleCategory
        self.suggestedCount = suggestedCount
    }
    
    var formattedTitle: String {
        text
    }
}

import CryptoKit

// Extension to generate deterministic UUID from string
extension String {
    func uuidFromString() -> String {
        // Use SHA256 to create a deterministic UUID from the string
        let inputData = Data(self.utf8)
        let hashed = SHA256.hash(data: inputData)
        let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
        
        // Convert hash to UUID format (8-4-4-4-12)
        // Using first 32 characters of the hash
        let uuid = String(hashString.prefix(8)) + "-" +
                  String(hashString.dropFirst(8).prefix(4)) + "-" +
                  String(hashString.dropFirst(12).prefix(4)) + "-" +
                  String(hashString.dropFirst(16).prefix(4)) + "-" +
                  String(hashString.dropFirst(20).prefix(12))
        
        return uuid.uppercased()
    }
}