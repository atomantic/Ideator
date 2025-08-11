import Foundation

struct Prompt: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let category: Category
    let suggestedCount: Int
    
    init(
        id: UUID = UUID(),
        text: String,
        category: Category,
        suggestedCount: Int = 10
    ) {
        self.id = id
        self.text = text
        self.category = category
        self.suggestedCount = suggestedCount
    }
    
    var formattedTitle: String {
        "\(suggestedCount) \(text)"
    }
}