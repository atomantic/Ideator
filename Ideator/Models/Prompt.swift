import Foundation

struct Prompt: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let category: Category // Keep for backwards compatibility
    let flexibleCategory: FlexibleCategory
    let suggestedCount: Int
    let help: String?
    let slug: String?

    static func deterministicId(key: String, categoryId: String) -> UUID {
        let uniqueString = "\(key)_\(categoryId)"
        return UUID(uuidString: uniqueString.uuidFromString()) ?? UUID()
    }

    init(
        id: UUID? = nil,
        text: String,
        category: Category,
        suggestedCount: Int = 10,
        help: String? = nil,
        slug: String? = nil
    ) {
        self.id = id ?? Self.deterministicId(key: slug ?? text, categoryId: category.rawValue)
        self.text = text
        self.category = category
        self.flexibleCategory = FlexibleCategory.from(category: category)
        self.suggestedCount = suggestedCount
        self.help = help
        self.slug = slug
    }

    init(
        id: UUID? = nil,
        text: String,
        flexibleCategory: FlexibleCategory,
        suggestedCount: Int = 10,
        help: String? = nil,
        slug: String? = nil
    ) {
        self.id = id ?? Self.deterministicId(key: slug ?? text, categoryId: flexibleCategory.id)
        self.text = text
        self.category = flexibleCategory.toCategory() ?? .personalDevelopment
        self.flexibleCategory = flexibleCategory
        self.suggestedCount = suggestedCount
        self.help = help
        self.slug = slug
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
