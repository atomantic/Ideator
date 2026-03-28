import Foundation

final class ExportManager {
    static let shared = ExportManager()

    private init() {}

    func exportAsText(_ ideaList: IdeaList) -> String {
        ideaList.formattedForExport
    }
    
    func exportAsMarkdown(_ ideaList: IdeaList) -> String {
        var output = "# \(ideaList.prompt.formattedTitle)\n\n"
        output += "**Category:** \(ideaList.prompt.flexibleCategory.name)\n"
        output += "**Created:** \(ideaList.createdDate.formatted(date: .long, time: .shortened))\n\n"

        output += "## Ideas\n\n"
        for (index, idea) in ideaList.ideas.enumerated() {
            if !idea.isEmpty {
                output += "\(index + 1). \(idea)\n"
            }
        }
        return output
    }

    func exportBestIdeas(
        _ items: [(ideaText: String, promptText: String, categoryName: String)]
    ) -> String {
        guard !items.isEmpty else { return "" }

        var output = "My Best Ideas\n"
        output += String(repeating: "=", count: 14) + "\n\n"

        // Group by category
        var grouped: [(category: String, ideas: [(idea: String, prompt: String)])] = []
        var seen: [String: Int] = [:]
        for item in items {
            if let idx = seen[item.categoryName] {
                grouped[idx].ideas.append((idea: item.ideaText, prompt: item.promptText))
            } else {
                seen[item.categoryName] = grouped.count
                grouped.append((category: item.categoryName, ideas: [(idea: item.ideaText, prompt: item.promptText)]))
            }
        }

        for group in grouped {
            output += "\(group.category)\n"
            output += String(repeating: "-", count: group.category.count) + "\n"
            for entry in group.ideas {
                output += "• \(entry.idea)\n  → from: \(entry.prompt)\n"
            }
            output += "\n"
        }

        output += "\(items.count) best ideas total"
        return output
    }
}
