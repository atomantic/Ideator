import Foundation
import UIKit

class ExportManager {
    static let shared = ExportManager()
    
    private init() {}
    
    func exportToNotes(_ ideaList: IdeaList, from viewController: UIViewController) {
        let content = ideaList.formattedForExport
        
        let activityViewController = UIActivityViewController(
            activityItems: [content],
            applicationActivities: nil
        )
        
        activityViewController.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks,
            .postToVimeo,
            .postToWeibo,
            .postToFlickr,
            .postToTwitter,
            .postToFacebook,
            .postToTencentWeibo
        ]
        
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }
        
        viewController.present(activityViewController, animated: true) {
            PersistenceManager.shared.saveCompleted(ideaList)
        }
    }
    
    func exportAsText(_ ideaList: IdeaList) -> String {
        ideaList.formattedForExport
    }
    
    func exportAsMarkdown(_ ideaList: IdeaList) -> String {
        var output = "# \(ideaList.prompt.formattedTitle)\n\n"
        output += "**Category:** \(ideaList.prompt.category.rawValue)\n"
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
