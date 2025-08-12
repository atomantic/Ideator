import Foundation
import SwiftUI

@Observable
class PromptViewModel {
    var prompts: [Prompt] = []
    var categories: [Category] = Category.allCases
    var selectedCategory: Category?
    var currentPrompt: Prompt?
    var isLoading = false
    
    private let promptService = PromptService.shared
    
    init() {
        loadPrompts()
    }
    
    func loadPrompts() {
        isLoading = true
        prompts = promptService.getPrompts(for: selectedCategory)
        isLoading = false
    }
    
    func selectCategory(_ category: Category?) {
        selectedCategory = category
        loadPrompts()
    }
    
    func getRandomPrompt() -> Prompt? {
        currentPrompt = promptService.getRandomPrompt(from: selectedCategory)
        if let prompt = currentPrompt {
            promptService.markPromptAsUsed(prompt)
        }
        return currentPrompt
    }
    
    func getPromptsForCategory(_ category: Category) -> [Prompt] {
        promptService.getPrompts(for: category)
    }
    
    func getUnusedPromptsCount(for category: Category?) -> Int {
        promptService.getUnusedPromptsCount(for: category)
    }
    
    func resetUsedPrompts() {
        promptService.resetUsedPrompts()
        loadPrompts()
    }
    
    func isPromptUsed(_ prompt: Prompt) -> Bool {
        promptService.isPromptUsed(prompt)
    }
    
    func getCategoriesGroupedByPack() -> [(packName: String?, categories: [FlexibleCategory])] {
        promptService.getCategoriesGroupedByPack()
    }
    
    func getUnusedPromptsCount(for flexibleCategory: FlexibleCategory) -> Int {
        promptService.getUnusedPromptsCount(for: flexibleCategory)
    }
    
    func getPrompts(for flexibleCategory: FlexibleCategory) -> [Prompt] {
        promptService.getPrompts(for: flexibleCategory)
    }
    
    func selectFlexibleCategory(_ category: FlexibleCategory) {
        // Clear the old category selection
        selectedCategory = category.toCategory()
        // Filter prompts by flexible category
        prompts = promptService.getPrompts(for: category)
    }
}