import Foundation
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "net.shadowpuppet.ideator", category: "PersistenceManager")

final class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let draftsKey = "ideator_drafts"
    private let completedKey = "ideator_completed"
    private let customPromptsKey = "custom_prompts"
    private let favoritePromptIdsKey = "favorite_prompt_ids"

    private init() {}
    
    func saveDraft(_ ideaList: IdeaList) {
        var drafts = loadDrafts()
        
        if let index = drafts.firstIndex(where: { $0.id == ideaList.id }) {
            drafts[index] = ideaList
        } else {
            drafts.append(ideaList)
        }
        
        save(drafts, forKey: draftsKey)
    }
    
    func loadDrafts() -> [IdeaList] {
        load(forKey: draftsKey) ?? []
    }
    
    func deleteDraft(withId id: UUID) {
        var drafts = loadDrafts()
        drafts.removeAll { $0.id == id }
        save(drafts, forKey: draftsKey)
    }
    
    func saveCompleted(_ ideaList: IdeaList) {
        var completed = loadCompleted()
        
        if let index = completed.firstIndex(where: { $0.id == ideaList.id }) {
            completed[index] = ideaList
        } else {
            completed.append(ideaList)
        }
        
        save(completed, forKey: completedKey)
        deleteDraft(withId: ideaList.id)
    }
    
    func loadCompleted() -> [IdeaList] {
        load(forKey: completedKey) ?? []
    }
    
    func deleteCompleted(withId id: UUID) {
        var completed = loadCompleted()
        completed.removeAll { $0.id == id }
        save(completed, forKey: completedKey)
    }
    
    func getDraft(for prompt: Prompt) -> IdeaList? {
        loadDrafts().first { $0.prompt.id == prompt.id }
    }
    
    private func save<T: Codable>(_ object: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(object)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            logger.error("Failed to save \(key): \(error.localizedDescription)")
        }
    }
    
    private func load<T: Codable>(forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            logger.error("Failed to load \(key): \(error.localizedDescription)")
            return nil
        }
    }
    
    func clearAll() {
        UserDefaults.standard.removeObject(forKey: draftsKey)
        UserDefaults.standard.removeObject(forKey: completedKey)
        UserDefaults.standard.removeObject(forKey: customPromptsKey)
        UserDefaults.standard.removeObject(forKey: favoritePromptIdsKey)
    }

    // MARK: - Favorite Prompts

    func loadFavoritePromptIds() -> Set<UUID> {
        load(forKey: favoritePromptIdsKey) ?? []
    }

    func saveFavoritePromptIds(_ ids: Set<UUID>) {
        save(ids, forKey: favoritePromptIdsKey)
    }
    
    // Custom Prompts Management
    func saveCustomPrompt(_ prompt: Prompt) {
        var prompts = loadCustomPrompts()
        
        // Check if prompt already exists by text
        if !prompts.contains(where: { $0.text == prompt.text }) {
            prompts.append(prompt)
            save(prompts, forKey: customPromptsKey)
        }
    }
    
    func loadCustomPrompts() -> [Prompt] {
        load(forKey: customPromptsKey) ?? []
    }
    
    func deleteCustomPrompt(withId id: UUID) {
        var prompts = loadCustomPrompts()
        prompts.removeAll { $0.id == id }
        save(prompts, forKey: customPromptsKey)
    }
}