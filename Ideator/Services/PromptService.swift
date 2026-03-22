import Foundation
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "net.shadowpuppet.ideator", category: "PromptService")

@MainActor
final class PromptService {
    static let shared = PromptService()
    
    private var allPrompts: [Prompt] = []
    private var usedPromptIds: Set<UUID> = []
    private var favoritePromptIds: Set<UUID> = []
    private let packManager = PackManager.shared
    
    private init() {
        loadPromptsFromPacks()
        loadUsedPromptIds()
        loadFavoritePromptIds()
        migrateUsedPromptIdsToSlugBased()
        migrateCompletedListsToUsedPrompts()
    }
    
    private func loadPromptsFromPacks() {
        var prompts: [Prompt] = []

        for pack in packManager.purchasedPacks where pack.isEnabled {
            for category in pack.categories {
                if let categoryPrompts = loadPromptsFromCategory(pack: pack, category: category) {
                    prompts.append(contentsOf: categoryPrompts)
                }
            }
        }

        if prompts.isEmpty {
            logger.warning("No prompts loaded from packs")
            loadDefaultPrompts()
        } else {
            self.allPrompts = prompts
        }
    }

    private func loadPromptsFromCategory(pack: PromptPack, category: PackCategory) -> [Prompt]? {
        let tsvName = category.file.replacingOccurrences(of: ".tsv", with: "")
        guard let fileURL = Bundle.main.url(forResource: tsvName, withExtension: "tsv") else {
            logger.error("TSV file not found in bundle: \(category.file)")
            return nil
        }

        let data: String
        do {
            data = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            logger.error("Failed to read TSV file \(fileURL.path): \(error.localizedDescription)")
            return nil
        }

        let flexibleCategory = FlexibleCategory.from(
            packCategory: category,
            packId: pack.id,
            packName: pack.name
        )
        return TSVParser.parse(tsv: data, flexibleCategory: flexibleCategory)
    }

    func reloadPrompts() {
        packManager.loadAllPacks()
        loadPromptsFromPacks()
        NotificationCenter.default.post(name: .promptsReloaded, object: nil)
    }
    
    private func loadDefaultPrompts() {
        allPrompts = [
            // Personal Development
            Prompt(text: "things I want to accomplish this year", category: .personalDevelopment, slug: "things-i-want-to-accomplish-this-year"),
            Prompt(text: "habits I want to develop", category: .personalDevelopment, slug: "habits-i-want-to-develop"),
            Prompt(text: "fears I want to overcome", category: .personalDevelopment, slug: "fears-i-want-to-overcome"),
            Prompt(text: "skills I'd like to master", category: .personalDevelopment, slug: "skills-id-like-to-master"),

            // Creative
            Prompt(text: "app ideas to build", category: .creative, slug: "app-ideas-to-build"),
            Prompt(text: "story ideas I'd love to write", category: .creative, slug: "story-ideas-id-love-to-write"),
            Prompt(text: "art projects to try", category: .creative, slug: "art-projects-to-try"),

            // Professional
            Prompt(text: "business ideas to explore", category: .professional, slug: "business-ideas-to-explore"),
            Prompt(text: "ways to improve my workspace", category: .professional, slug: "ways-to-improve-my-workspace"),
            Prompt(text: "career goals for the next 5 years", category: .professional, slug: "career-goals-for-the-next-5-years"),

            // Lifestyle
            Prompt(text: "bucket list adventures", category: .lifestyle, slug: "bucket-list-adventures"),
            Prompt(text: "recipes to try this month", category: .lifestyle, slug: "recipes-to-try-this-month"),
            Prompt(text: "ways to simplify my life", category: .lifestyle, slug: "ways-to-simplify-my-life"),

            // Learning
            Prompt(text: "books to read", category: .learning, slug: "books-to-read"),
            Prompt(text: "online courses to take", category: .learning, slug: "online-courses-to-take"),
            Prompt(text: "topics to research deeply", category: .learning, slug: "topics-to-research-deeply"),

            // Relationships
            Prompt(text: "ways to show appreciation to loved ones", category: .relationships, slug: "ways-to-show-appreciation-to-loved-ones"),
            Prompt(text: "qualities I value in friendships", category: .relationships, slug: "qualities-i-value-in-friendships"),

            // Entertainment
            Prompt(text: "movies to watch this year", category: .entertainment, slug: "movies-to-watch-this-year"),
            Prompt(text: "games to play with friends", category: .entertainment, slug: "games-to-play-with-friends"),

            // Travel
            Prompt(text: "places to visit in my city", category: .travel, slug: "places-to-visit-in-my-city"),
            Prompt(text: "countries I want to visit", category: .travel, slug: "countries-i-want-to-visit"),

            // Financial
            Prompt(text: "ways to save money", category: .financial, slug: "ways-to-save-money"),
            Prompt(text: "financial goals for this year", category: .financial, slug: "financial-goals-for-this-year"),

            // Social Impact
            Prompt(text: "causes I want to support", category: .socialImpact, slug: "causes-i-want-to-support"),
            Prompt(text: "ways to help my community", category: .socialImpact, slug: "ways-to-help-my-community")
        ]
    }
    
    private func loadUsedPromptIds() {
        guard let data = UserDefaults.standard.data(forKey: "usedPromptIds") else { return }
        do {
            usedPromptIds = try JSONDecoder().decode(Set<UUID>.self, from: data)
        } catch {
            logger.error("Failed to decode usedPromptIds: \(error.localizedDescription)")
        }
    }
    
    private func saveUsedPromptIds() {
        do {
            let data = try JSONEncoder().encode(usedPromptIds)
            UserDefaults.standard.set(data, forKey: "usedPromptIds")
        } catch {
            logger.error("Failed to encode usedPromptIds: \(error.localizedDescription)")
        }
    }
    
    func getRandomPrompt(from category: Category? = nil, avoiding usedIds: Set<UUID>? = nil) -> Prompt? {
        let idsToAvoid = usedIds ?? usedPromptIds

        let availablePrompts = allPrompts.filter { prompt in
            !idsToAvoid.contains(prompt.id) && (category == nil || prompt.category == category)
        }

        if availablePrompts.isEmpty {
            if category != nil {
                return getRandomPrompt(from: nil, avoiding: usedIds)
            } else {
                resetUsedPrompts()
                return allPrompts.randomElement()
            }
        }

        return availablePrompts.randomElement()
    }
    
    func getPrompts(for category: Category? = nil) -> [Prompt] {
        if let category = category {
            return allPrompts.filter { $0.category == category }
        }
        return allPrompts
    }
    
    func markPromptAsUsed(_ prompt: Prompt) {
        usedPromptIds.insert(prompt.id)
        saveUsedPromptIds()
    }
    
    func unmarkPromptAsUsed(_ prompt: Prompt) {
        usedPromptIds.remove(prompt.id)
        saveUsedPromptIds()
    }
    
    func resetUsedPrompts() {
        usedPromptIds.removeAll()
        saveUsedPromptIds()
    }
    
    func isPromptUsed(_ prompt: Prompt) -> Bool {
        usedPromptIds.contains(prompt.id)
    }

    // MARK: - Favorites

    private func loadFavoritePromptIds() {
        favoritePromptIds = PersistenceManager.shared.loadFavoritePromptIds()
    }

    private func saveFavoritePromptIds() {
        PersistenceManager.shared.saveFavoritePromptIds(favoritePromptIds)
    }

    func toggleFavorite(_ prompt: Prompt) {
        if favoritePromptIds.contains(prompt.id) {
            favoritePromptIds.remove(prompt.id)
        } else {
            favoritePromptIds.insert(prompt.id)
        }
        saveFavoritePromptIds()
    }

    func isPromptFavorited(_ prompt: Prompt) -> Bool {
        favoritePromptIds.contains(prompt.id)
    }

    func getFavoritePromptIds() -> Set<UUID> {
        favoritePromptIds
    }

    func getFavoritePrompts() -> [Prompt] {
        allPrompts.filter { favoritePromptIds.contains($0.id) }
    }
    
    func getUnusedPromptsCount(for category: Category? = nil) -> Int {
        allPrompts.filter { prompt in
            !usedPromptIds.contains(prompt.id) && (category == nil || prompt.category == category)
        }.count
    }
    
    func getUnusedPromptsCount(for flexibleCategory: FlexibleCategory) -> Int {
        allPrompts.filter { 
            $0.flexibleCategory.id == flexibleCategory.id && 
            !usedPromptIds.contains($0.id) 
        }.count
    }
    
    func getPrompts(for flexibleCategory: FlexibleCategory) -> [Prompt] {
        allPrompts.filter { $0.flexibleCategory.id == flexibleCategory.id }
    }
    
    func getRandomPrompt(for flexibleCategory: FlexibleCategory) -> Prompt? {
        let available = allPrompts.filter {
            $0.flexibleCategory.id == flexibleCategory.id &&
            !usedPromptIds.contains($0.id)
        }
        return available.randomElement()
    }
    
    func getCategoriesGroupedByPack() -> [(packName: String?, packId: String?, categories: [FlexibleCategory])] {
        var categoryDict: [String?: (packId: String?, categories: Set<FlexibleCategory>)] = [:]
        
        for prompt in allPrompts {
            let packName = prompt.flexibleCategory.packName
            let packId = prompt.flexibleCategory.packId
            if categoryDict[packName] == nil {
                categoryDict[packName] = (packId: packId, categories: [])
            }
            categoryDict[packName]?.categories.insert(prompt.flexibleCategory)
        }
        
        // Sort: Core (nil) first, then alphabetically by pack name
        let sorted = categoryDict.sorted { (first, second) in
            if first.key == nil { return true }
            if second.key == nil { return false }
            return (first.key ?? "") < (second.key ?? "")
        }
        
        return sorted.map { (packName: $0.key, packId: $0.value.packId, categories: Array($0.value.categories).sorted { $0.name < $1.name }) }
    }
    
    private func migrateUsedPromptIdsToSlugBased() {
        let migrationKey = "SlugBasedIdMigrationCompleted"
        if UserDefaults.standard.bool(forKey: migrationKey) {
            return
        }

        var changed = false

        for prompt in allPrompts {
            guard prompt.slug != nil else { continue }

            // Compute the old UUID (text-based) — prompt.id is already slug-based
            let oldId = Prompt.deterministicId(key: prompt.text, categoryId: prompt.flexibleCategory.id)
            guard oldId != prompt.id else { continue }

            if usedPromptIds.contains(oldId) {
                usedPromptIds.remove(oldId)
                usedPromptIds.insert(prompt.id)
                changed = true
            }
        }

        if changed {
            saveUsedPromptIds()
        }

        UserDefaults.standard.set(true, forKey: migrationKey)
    }

    private func migrateCompletedListsToUsedPrompts() {
        // Check if migration has already been done
        let migrationKey = "PromptUsageMigrationCompleted"
        if UserDefaults.standard.bool(forKey: migrationKey) {
            return
        }
        
        // Get all completed lists
        let completed = PersistenceManager.shared.loadCompleted()
        
        // Mark each prompt from completed lists as used
        for ideaList in completed {
            // Find matching prompt by text and flexible category
            if let matchingPrompt = allPrompts.first(where: { 
                $0.text == ideaList.prompt.text && 
                ($0.flexibleCategory.id == ideaList.prompt.flexibleCategory.id ||
                 $0.category == ideaList.prompt.category)
            }) {
                usedPromptIds.insert(matchingPrompt.id)
            }
        }
        
        // Save the updated used prompt IDs
        saveUsedPromptIds()
        
        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
