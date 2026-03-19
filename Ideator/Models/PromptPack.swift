import Foundation

struct PromptPack: Identifiable, Codable {
    let id: String
    let name: String
    let version: String
    let description: String
    let author: String
    var categories: [PackCategory]
    var isEnabled: Bool = true

    var totalPrompts: Int {
        categories.reduce(0) { $0 + ($1.promptCount ?? 0) }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, version, description, author, categories
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        version = try container.decode(String.self, forKey: .version)
        description = try container.decode(String.self, forKey: .description)
        author = try container.decode(String.self, forKey: .author)
        categories = try container.decode([PackCategory].self, forKey: .categories)
        isEnabled = true
    }
}

struct PackCategory: Codable {
    let id: String
    let name: String
    let file: String
    let icon: String
    let color: String
    var promptCount: Int? = nil
}
