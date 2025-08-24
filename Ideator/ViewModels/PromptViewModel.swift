import Foundation
import SwiftUI

@Observable
class PromptViewModel {
    var prompts: [Prompt] = []
    var categories: [Category] = Category.allCases
    var selectedCategory: Category?
    var selectedFlexibleCategory: FlexibleCategory?
    var currentPrompt: Prompt?
    var isLoading = false
    
    private let promptService = PromptService.shared
    
    init() {
        loadPrompts()
    }
    
    func loadPrompts() {
        isLoading = true
        
        // Get prompts from the service
        var allPrompts: [Prompt] = []
        if let flexCategory = selectedFlexibleCategory {
            allPrompts = promptService.getPrompts(for: flexCategory)
        } else {
            allPrompts = promptService.getPrompts(for: selectedCategory)
        }
        
        // Add custom prompts if showing all categories or no specific category
        if selectedCategory == nil && selectedFlexibleCategory == nil {
            let customPrompts = PersistenceManager.shared.loadCustomPrompts()
            allPrompts.append(contentsOf: customPrompts)
        } else if let category = selectedFlexibleCategory {
            // Include custom prompts that match the selected category
            let customPrompts = PersistenceManager.shared.loadCustomPrompts()
                .filter { $0.flexibleCategory.id == category.id }
            allPrompts.append(contentsOf: customPrompts)
        } else if let category = selectedCategory {
            // Include custom prompts that match the selected category
            let customPrompts = PersistenceManager.shared.loadCustomPrompts()
                .filter { $0.category == category }
            allPrompts.append(contentsOf: customPrompts)
        }
        
        prompts = allPrompts
        isLoading = false
    }
    
    func selectCategory(_ category: Category?) {
        selectedCategory = category
        selectedFlexibleCategory = nil // Clear flexible category when selecting regular category
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
    
    func markPromptAsUsed(_ prompt: Prompt) {
        promptService.markPromptAsUsed(prompt)
    }
    
    func unmarkPromptAsUsed(_ prompt: Prompt) {
        promptService.unmarkPromptAsUsed(prompt)
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
    
    func getRandomPrompt(in flexibleCategory: FlexibleCategory) -> Prompt? {
        let prompt = promptService.getRandomPrompt(for: flexibleCategory)
        if let prompt {
            promptService.markPromptAsUsed(prompt)
        }
        return prompt
    }
    
    func selectFlexibleCategory(_ category: FlexibleCategory) {
        // Set the flexible category
        selectedFlexibleCategory = category
        // Also set the old category for backwards compatibility
        selectedCategory = category.toCategory()
        // Load prompts for this flexible category
        loadPrompts()
    }
}
