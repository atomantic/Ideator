import Foundation
import SwiftUI

@Observable
class IdeaListViewModel {
    var currentIdeaList: IdeaList?
    var ideas: [String] = []
    var isComplete = false
    var showExportSheet = false
    
    private let persistenceManager = PersistenceManager.shared
    
    init() {}
    
    func startNewList(with prompt: Prompt) {
        let existingDraft = persistenceManager.getDraft(for: prompt)
        
        if let draft = existingDraft {
            currentIdeaList = draft
            ideas = draft.ideas
        } else {
            ideas = []  // Start with empty array instead of pre-filled
            currentIdeaList = IdeaList(
                prompt: prompt,
                ideas: ideas
            )
        }
        
        isComplete = false
    }
    
    func addIdea(_ text: String) {
        ideas.append(text)
        saveDraft()
    }
    
    func removeIdea(at index: Int) {
        guard index < ideas.count else { return }
        ideas.remove(at: index)
        saveDraft()
    }
    
    func updateIdea(at index: Int, with text: String) {
        guard index < ideas.count else { return }
        ideas[index] = text
        saveDraft()
    }
    
    func saveDraft() {
        guard var ideaList = currentIdeaList else { return }
        ideaList.ideas = ideas
        ideaList.modifiedDate = Date()
        ideaList.isComplete = checkIfComplete()
        currentIdeaList = ideaList
        persistenceManager.saveDraft(ideaList)
    }
    
    func checkIfComplete() -> Bool {
        // All ideas in the array are now filled (no empty placeholders)
        return ideas.count >= (currentIdeaList?.prompt.suggestedCount ?? 10)
    }
    
    func markAsComplete() {
        guard var ideaList = currentIdeaList else { return }
        ideaList.isComplete = true
        ideaList.ideas = ideas
        currentIdeaList = ideaList
        persistenceManager.saveCompleted(ideaList)
        // Mark the prompt as used when completing the list
        PromptService.shared.markPromptAsUsed(ideaList.prompt)
        isComplete = true
        
        // Post notification for streak tracking
        NotificationCenter.default.post(name: .ideaListCompleted, object: nil)
    }
    
    func exportList() {
        guard currentIdeaList != nil else { return }
        showExportSheet = true
    }
    
    func resetList() {
        currentIdeaList = nil
        ideas = []
        isComplete = false
        showExportSheet = false
    }
    
    func getProgress() -> Double {
        // Since we're now using a dynamic list, count all ideas (they're all filled)
        return Double(ideas.count) / Double(currentIdeaList?.prompt.suggestedCount ?? 10)
    }
}