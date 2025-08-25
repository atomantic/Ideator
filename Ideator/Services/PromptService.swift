import Foundation

class PromptService {
    static let shared = PromptService()
    
    private var allPrompts: [Prompt] = []
    private var usedPromptIds: Set<UUID> = []
    private let packManager = PackManager.shared
    
    private init() {
        loadPromptsFromPacks()
        loadUsedPromptIds()
        migrateCompletedListsToUsedPrompts()
    }
    
    private func loadPromptsFromPacks() {
        var prompts: [Prompt] = []
        
        for pack in packManager.installedPacks where pack.isEnabled {
            for category in pack.categories {
                if let categoryPrompts = loadPromptsFromCategory(pack: pack, category: category) {
                    prompts.append(contentsOf: categoryPrompts)
                }
            }
        }
        
        if prompts.isEmpty {
            print("No prompts loaded from packs")
            loadDefaultPrompts()
        } else {
            self.allPrompts = prompts
        }
    }
    
    private func loadPromptsFromCategory(pack: PromptPack, category: PackCategory) -> [Prompt]? {
        // Load from documents directory (all packs are now stored there)
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                    in: .userDomainMask).first!
        let packDir = documentsPath.appendingPathComponent("PromptPacks/\(pack.id)")
        let fileURL = packDir.appendingPathComponent(category.file)
        
        guard let data = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return nil
        }
        
        // Create flexible category for this pack category
        let flexibleCategory = FlexibleCategory.from(
            packCategory: category,
            packId: pack.id,
            packName: pack.name
        )
        return TSVParser.parse(tsv: data, flexibleCategory: flexibleCategory)
    }
    
    func reloadPrompts() {
        packManager.loadInstalledPacks()
        loadPromptsFromPacks()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .promptsReloaded, object: nil)
        }
    }
    
    private func loadDefaultPrompts() {
        allPrompts = [
            // Personal Development
            Prompt(text: "things I want to accomplish this year", category: .personalDevelopment),
            Prompt(text: "habits I want to develop", category: .personalDevelopment),
            Prompt(text: "fears I want to overcome", category: .personalDevelopment),
            Prompt(text: "skills I'd like to master", category: .personalDevelopment),
            
            // Creative
            Prompt(text: "app ideas to build", category: .creative),
            Prompt(text: "story ideas I'd love to write", category: .creative),
            Prompt(text: "art projects to try", category: .creative),
            
            // Professional
            Prompt(text: "business ideas to explore", category: .professional),
            Prompt(text: "ways to improve my workspace", category: .professional),
            Prompt(text: "career goals for the next 5 years", category: .professional),
            
            // Lifestyle
            Prompt(text: "bucket list adventures", category: .lifestyle),
            Prompt(text: "recipes to try this month", category: .lifestyle),
            Prompt(text: "ways to simplify my life", category: .lifestyle),
            
            // Learning
            Prompt(text: "books to read", category: .learning),
            Prompt(text: "online courses to take", category: .learning),
            Prompt(text: "topics to research deeply", category: .learning),
            
            // Relationships
            Prompt(text: "ways to show appreciation to loved ones", category: .relationships),
            Prompt(text: "qualities I value in friendships", category: .relationships),
            
            // Entertainment
            Prompt(text: "movies to watch this year", category: .entertainment),
            Prompt(text: "games to play with friends", category: .entertainment),
            
            // Travel
            Prompt(text: "places to visit in my city", category: .travel),
            Prompt(text: "countries I want to visit", category: .travel),
            
            // Financial
            Prompt(text: "ways to save money", category: .financial),
            Prompt(text: "financial goals for this year", category: .financial),
            
            // Social Impact
            Prompt(text: "causes I want to support", category: .socialImpact),
            Prompt(text: "ways to help my community", category: .socialImpact)
        ]
    }
    
    private func categoryFromString(_ string: String) -> Category {
        switch string {
        case "personalDevelopment": return .personalDevelopment
        case "professional": return .professional
        case "creative": return .creative
        case "lifestyle": return .lifestyle
        case "relationships": return .relationships
        case "entertainment": return .entertainment
        case "travel": return .travel
        case "learning": return .learning
        case "financial": return .financial
        case "socialImpact": return .socialImpact
        case "health": return .health
        case "mindfulness": return .mindfulness
        case "selfcare", "selfCare": return .selfCare
        case "gratitude": return .gratitude
        default: return .personalDevelopment
        }
    }
    
    private func loadUsedPromptIds() {
        if let data = UserDefaults.standard.data(forKey: "usedPromptIds"),
           let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            usedPromptIds = ids
        }
    }
    
    private func saveUsedPromptIds() {
        if let data = try? JSONEncoder().encode(usedPromptIds) {
            UserDefaults.standard.set(data, forKey: "usedPromptIds")
        }
    }
    
    func getRandomPrompt(from category: Category? = nil, avoiding usedIds: Set<UUID>? = nil) -> Prompt? {
        let idsToAvoid = usedIds ?? usedPromptIds
        
        var availablePrompts = allPrompts.filter { !idsToAvoid.contains($0.id) }
        
        if let category = category {
            availablePrompts = availablePrompts.filter { $0.category == category }
        }
        
        if availablePrompts.isEmpty {
            if category != nil {
                return getRandomPrompt(from: nil, avoiding: usedIds)
            } else {
                resetUsedPrompts()
                availablePrompts = allPrompts
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
    
    func getUnusedPromptsCount(for category: Category? = nil) -> Int {
        var prompts = allPrompts.filter { !usedPromptIds.contains($0.id) }
        if let category = category {
            prompts = prompts.filter { $0.category == category }
        }
        return prompts.count
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
