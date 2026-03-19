import Foundation
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "net.shadowpuppet.ideator", category: "PackManager")

@MainActor
final class PackManager: ObservableObject {
    static let shared = PackManager()

    @Published var allPacks: [PromptPack] = []

    /// All known bundled pack IDs
    private let bundledPackIds = [
        "core", "creative-writing", "disaster-prep", "family",
        "impact-finance", "silly", "surreal", "tech-startup", "wellness",
    ]

    private init() {
        loadAllPacks()

        // Grandfather any packs the user previously downloaded before IAP
        let enabledPacks = UserDefaults.standard.dictionary(forKey: "enabledPacks") as? [String: Bool] ?? [:]
        let previouslyInstalled = Array(enabledPacks.keys)
        StoreManager.shared.grandfatherInstalledPacks(previouslyInstalled)
    }

    func loadAllPacks() {
        let enabledPacks = UserDefaults.standard.dictionary(forKey: "enabledPacks") as? [String: Bool] ?? [:]
        var packs: [PromptPack] = []

        for packId in bundledPackIds {
            if var pack = loadBundledPack(packId) {
                pack.isEnabled = enabledPacks[pack.id] ?? true
                packs.append(pack)
            }
        }

        allPacks = packs
    }

    private func loadBundledPack(_ packId: String) -> PromptPack? {
        guard let manifestURL = Bundle.main.url(forResource: "\(packId)-manifest", withExtension: "json") else {
            logger.warning("Manifest not found in bundle: \(packId)-manifest.json")
            return nil
        }

        guard let data = try? Data(contentsOf: manifestURL),
              var pack = try? JSONDecoder().decode(PromptPack.self, from: data) else {
            logger.error("Failed to decode manifest for pack: \(packId)")
            return nil
        }

        for i in pack.categories.indices {
            let tsvName = pack.categories[i].file.replacingOccurrences(of: ".tsv", with: "")
            if let tsvURL = Bundle.main.url(forResource: tsvName, withExtension: "tsv"),
               let content = try? String(contentsOf: tsvURL, encoding: .utf8) {
                let lines = content.components(separatedBy: CharacterSet.newlines)
                pack.categories[i].promptCount = lines.dropFirst().filter { !$0.isEmpty }.count
            }
        }

        return pack
    }

    /// Packs the user has purchased or that are free (for prompt loading)
    var purchasedPacks: [PromptPack] {
        allPacks.filter { StoreManager.shared.isPurchasedOrFree($0.id) }
    }

    /// Packs available for purchase (not yet purchased, excluding free)
    var unpurchasedPacks: [PromptPack] {
        allPacks.filter { !StoreManager.shared.isPurchasedOrFree($0.id) }
    }

    func togglePack(_ packId: String, enabled: Bool) {
        if let index = allPacks.firstIndex(where: { $0.id == packId }) {
            allPacks[index].isEnabled = enabled

            var enabledPacks = UserDefaults.standard.dictionary(forKey: "enabledPacks") as? [String: Bool] ?? [:]
            enabledPacks[packId] = enabled
            UserDefaults.standard.set(enabledPacks, forKey: "enabledPacks")
        }
    }

    func getEnabledCategories() -> [Category] {
        var categories: [Category] = []

        for pack in purchasedPacks where pack.isEnabled {
            for category in pack.categories {
                if let cat = categoryFromPackCategory(category) {
                    categories.append(cat)
                }
            }
        }

        return categories
    }

    private func categoryFromPackCategory(_ packCategory: PackCategory) -> Category? {
        switch packCategory.id {
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
        default: return nil
        }
    }
}
