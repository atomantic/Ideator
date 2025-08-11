import Foundation

struct IdeaList: Identifiable, Codable {
    let id: UUID
    let prompt: Prompt
    var ideas: [String]
    let createdDate: Date
    var modifiedDate: Date
    var isComplete: Bool
    
    init(
        id: UUID = UUID(),
        prompt: Prompt,
        ideas: [String] = [],
        createdDate: Date = Date(),
        modifiedDate: Date = Date(),
        isComplete: Bool = false
    ) {
        self.id = id
        self.prompt = prompt
        self.ideas = ideas
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.isComplete = isComplete
    }
    
    var progress: Double {
        Double(ideas.filter { !$0.isEmpty }.count) / Double(prompt.suggestedCount)
    }
    
    var formattedForExport: String {
        var output = "Idea Loom List: \(prompt.formattedTitle)\n"
        output += "Category: \(prompt.category.rawValue)\n"
        output += "Created: \(createdDate.formatted(date: .long, time: .shortened))\n\n"
        
        for (index, idea) in ideas.enumerated() {
            if !idea.isEmpty {
                output += "\(index + 1). \(idea)\n"
            }
        }
        
        output += "\n---\nGenerated with Idea Loom"
        return output
    }
}