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
            ideas = Array(repeating: "", count: prompt.suggestedCount)
            currentIdeaList = IdeaList(
                prompt: prompt,
                ideas: ideas
            )
        }
        
        isComplete = false
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
        let filledIdeas = ideas.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return filledIdeas.count >= (currentIdeaList?.prompt.suggestedCount ?? 10)
    }
    
    func markAsComplete() {
        guard var ideaList = currentIdeaList else { return }
        ideaList.isComplete = true
        ideaList.ideas = ideas
        currentIdeaList = ideaList
        persistenceManager.saveCompleted(ideaList)
        isComplete = true
    }
    
    func exportList() {
        guard let ideaList = currentIdeaList else { return }
        showExportSheet = true
    }
    
    func resetList() {
        currentIdeaList = nil
        ideas = []
        isComplete = false
        showExportSheet = false
    }
    
    func getProgress() -> Double {
        let filledIdeas = ideas.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return Double(filledIdeas.count) / Double(currentIdeaList?.prompt.suggestedCount ?? 10)
    }
}