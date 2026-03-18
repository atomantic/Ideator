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
}
