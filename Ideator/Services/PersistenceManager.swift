import Foundation
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "net.shadowpuppet.ideator", category: "PersistenceManager")

final class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let draftsKey = "ideator_drafts"
    private let completedKey = "ideator_completed"
    private let customPromptsKey = "custom_prompts"
    private let favoritePromptIdsKey = "favorite_prompt_ids"
    private let starredIdeaKeysKey = "starred_idea_keys"

    private init() {}
    
    func saveDraft(_ ideaList: IdeaList) {
        var drafts = loadDrafts()

        if let index = drafts.firstIndex(where: { $0.id == ideaList.id }) {
            drafts[index] = ideaList
        } else {
            drafts.append(ideaList)
        }

        save(drafts, forKey: draftsKey)
        ObsidianSyncManager.shared.syncIdeaList(ideaList)
    }
    
    func loadDrafts() -> [IdeaList] {
        load(forKey: draftsKey) ?? []
    }
    
    func deleteDraft(withId id: UUID) {
        var drafts = loadDrafts()
        let removed = drafts.first { $0.id == id }
        drafts.removeAll { $0.id == id }
        save(drafts, forKey: draftsKey)

        // Only delete from Obsidian if not also saved as completed
        if let removed, !loadCompleted().contains(where: { $0.id == id }) {
            ObsidianSyncManager.shared.deleteFile(for: removed)
        }
    }
    
    func saveCompleted(_ ideaList: IdeaList) {
        var completed = loadCompleted()

        if let index = completed.firstIndex(where: { $0.id == ideaList.id }) {
            completed[index] = ideaList
        } else {
            completed.append(ideaList)
        }

        save(completed, forKey: completedKey)
        ObsidianSyncManager.shared.syncIdeaList(ideaList)
        deleteDraft(withId: ideaList.id)
    }
    
    func loadCompleted() -> [IdeaList] {
        load(forKey: completedKey) ?? []
    }
    
    func deleteCompleted(withId id: UUID) {
        var completed = loadCompleted()
        let removed = completed.first { $0.id == id }
        completed.removeAll { $0.id == id }
        save(completed, forKey: completedKey)

        if let removed {
            ObsidianSyncManager.shared.deleteFile(for: removed)
        }
    }
    
    func getDraft(for prompt: Prompt) -> IdeaList? {
        loadDrafts().first { $0.prompt.id == prompt.id }
    }
    
    /// Merges ideas imported from the Obsidian vault. Writes storage directly
    /// instead of going through `saveDraft`/`saveCompleted` so an import doesn't
    /// bounce straight back out to the vault as a fresh write.
    func applyImportedIdeas(_ imported: [UUID: [String]]) {
        guard !imported.isEmpty else { return }

        var drafts: [IdeaList] = load(forKey: draftsKey) ?? []
        var completed: [IdeaList] = load(forKey: completedKey) ?? []

        func apply(_ ideas: [String], toListWithId id: UUID, in lists: inout [IdeaList]) -> Bool {
            guard let index = lists.firstIndex(where: { $0.id == id }) else { return false }
            lists[index].ideas = ideas
            lists[index].modifiedDate = Date()
            return true
        }

        var draftsChanged = false
        var completedChanged = false

        for (id, ideas) in imported {
            if apply(ideas, toListWithId: id, in: &drafts) {
                draftsChanged = true
            } else if apply(ideas, toListWithId: id, in: &completed) {
                completedChanged = true
            }
        }

        guard draftsChanged || completedChanged else { return }

        if draftsChanged { save(drafts, forKey: draftsKey) }
        if completedChanged { save(completed, forKey: completedKey) }
        logger.info("Imported external vault changes")
        NotificationCenter.default.post(name: .externalIdeasImported, object: nil)
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
        UserDefaults.standard.removeObject(forKey: starredIdeaKeysKey)
    }

    // MARK: - Starred Ideas (Best Ideas Collection)

    func loadStarredIdeaKeys() -> Set<String> {
        load(forKey: starredIdeaKeysKey) ?? []
    }

    func saveStarredIdeaKeys(_ keys: Set<String>) {
        save(keys, forKey: starredIdeaKeysKey)
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

// MARK: - Notification Names

extension Notification.Name {
    /// Posted after edits made outside the app (in the Obsidian vault) have been
    /// merged into local storage, so visible lists can reload.
    static let externalIdeasImported = Notification.Name("externalIdeasImported")
}
