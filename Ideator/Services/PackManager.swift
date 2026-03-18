import Foundation
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "net.shadowpuppet.ideator", category: "PackManager")

final class PackManager: ObservableObject {
    static let shared = PackManager()

    @Published var installedPacks: [PromptPack] = []
    @Published var availablePacks: [RemotePackInfo] = []
    @Published var isLoading = false
    @Published var packUpdates: [String: String] = [:] // packId -> newVersion

    private let packsDirectory: URL
    // Base root of the prompt packs repo (without ref); we'll append a ref like "main" or a version tag
    private let githubRepoRoot = "https://raw.githubusercontent.com/atomantic/IdeatorPromptPacks"
    private let supportedSchemaMajor = 1
    private var selectedRef: String = "main" // either "main" or a version tag like "v1.2.3"

    private init() {
        // Get documents directory for downloaded packs
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                            in: .userDomainMask).first else {
            fatalError("Unable to locate documents directory")
        }
        self.packsDirectory = documentsPath.appendingPathComponent("PromptPacks")

        // Create directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: packsDirectory,
                                                    withIntermediateDirectories: true)
        } catch {
            logger.error("Failed to create packs directory: \(error.localizedDescription)")
        }

        // Install embedded Core pack if not already present
        installEmbeddedCorePackIfNeeded()

        loadInstalledPacks()

        // Grandfather any packs installed before IAP was added
        Task { @MainActor in
            let installedIds = installedPacks.map(\.id)
            StoreManager.shared.grandfatherInstalledPacks(installedIds)
        }
    }

    // Determine which ref to use (main or a version tag) based on schema compatibility.
    // If main declares a schemaMajor greater than we support, use a tag matching the current app version.
    private func updateSelectedRefIfNeeded() async {
        // If we've already chosen a ref, keep it
        if selectedRef != "main" { return }

        guard let url = URL(string: "\(githubRepoRoot)/main/schema.json") else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                if let schema = try? JSONDecoder().decode(SchemaInfo.self, from: data) {
                    if schema.schemaMajor > supportedSchemaMajor {
                        // fallback to the tag that matches the running app version
                        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                        selectedRef = "v\(appVersion)"
                        logger.info("Using tagged packs ref: \(self.selectedRef) due to schemaMajor=\(schema.schemaMajor)")
                    }
                }
            }
        } catch {
            // If schema.json isn't reachable, keep using main
            logger.warning("Schema check failed: \(error.localizedDescription). Defaulting to main.")
        }
    }

    private func packsURL(_ path: String) -> URL? {
        URL(string: "\(githubRepoRoot)/\(selectedRef)/\(path)")
    }

    private func installEmbeddedCorePackIfNeeded() {
        let corePackDir = packsDirectory.appendingPathComponent("core")
        let manifestPath = corePackDir.appendingPathComponent("manifest.json")

        // Check if Core pack already exists
        if FileManager.default.fileExists(atPath: manifestPath.path) {
            return
        }

        // Create Core pack directory
        do {
            try FileManager.default.createDirectory(at: corePackDir,
                                                    withIntermediateDirectories: true)
        } catch {
            logger.error("Failed to create core pack directory: \(error.localizedDescription)")
            return
        }

        // Copy manifest.json from bundle
        guard let manifestBundlePath = Bundle.main.path(forResource: "manifest", ofType: "json") else {
            logger.warning("Core pack manifest not found in bundle")
            return
        }

        do {
            let fileManager = FileManager.default

            // Copy manifest
            let manifestSourceURL = URL(fileURLWithPath: manifestBundlePath)
            let manifestDestURL = corePackDir.appendingPathComponent("manifest.json")
            try fileManager.copyItem(at: manifestSourceURL, to: manifestDestURL)

            // Parse manifest to get list of TSV files
            let manifestData = try Data(contentsOf: manifestSourceURL)
            let manifest = try JSONDecoder().decode(PromptPack.self, from: manifestData)

            // Copy each TSV file
            for category in manifest.categories {
                let tsvName = category.file.replacingOccurrences(of: ".tsv", with: "")
                guard let tsvPath = Bundle.main.path(forResource: tsvName, ofType: "tsv") else {
                    logger.warning("TSV file not found in bundle: \(category.file)")
                    continue
                }

                let tsvSourceURL = URL(fileURLWithPath: tsvPath)
                let tsvDestURL = corePackDir.appendingPathComponent(category.file)
                try fileManager.copyItem(at: tsvSourceURL, to: tsvDestURL)
                logger.debug("Copied \(category.file) to documents")
            }

            logger.info("Successfully installed Core pack from bundle")
        } catch {
            logger.error("Failed to install Core pack from bundle: \(error.localizedDescription)")
        }
    }

    func loadInstalledPacks() {
        var packs: [PromptPack] = []

        // Load all packs from documents directory (including Core pack)
        if let downloadedPacks = loadDownloadedPacks() {
            packs.append(contentsOf: downloadedPacks)
        }

        // Load enabled state from UserDefaults
        let enabledPacks = UserDefaults.standard.dictionary(forKey: "enabledPacks") as? [String: Bool] ?? [:]
        for i in packs.indices {
            packs[i].isEnabled = enabledPacks[packs[i].id] ?? true
        }

        installedPacks = packs
    }

    private func loadDownloadedPacks() -> [PromptPack]? {
        do {
            let packDirs = try FileManager.default.contentsOfDirectory(at: packsDirectory,
                                                                      includingPropertiesForKeys: nil)

            return packDirs.compactMap { packDir in
                let manifestURL = packDir.appendingPathComponent("manifest.json")
                guard let data = try? Data(contentsOf: manifestURL),
                      var pack = try? JSONDecoder().decode(PromptPack.self, from: data) else {
                    return nil
                }

                // Count prompts in each category
                for i in pack.categories.indices {
                    let category = pack.categories[i]
                    let tsvURL = packDir.appendingPathComponent(category.file)
                    if let content = try? String(contentsOf: tsvURL, encoding: .utf8) {
                        let lines = content.components(separatedBy: .newlines)
                        pack.categories[i].promptCount = lines.dropFirst().filter { !$0.isEmpty }.count
                    }
                }

                return pack
            }
        } catch {
            logger.error("Failed to load downloaded packs: \(error.localizedDescription)")
            return nil
        }
    }

    func fetchAvailablePacks() async {
        await MainActor.run {
            isLoading = true
        }

        await updateSelectedRefIfNeeded()
        guard let url = packsURL("packs.json") else {
            logger.error("Invalid URL for packs.json")
            return
        }
        logger.debug("Fetching available packs from: \(url)")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse {
                logger.debug("Packs.json response code: \(httpResponse.statusCode)")
            }

            let packs = try JSONDecoder().decode([RemotePackInfo].self, from: data)
            logger.debug("Found \(packs.count) total packs")

            await MainActor.run {
                // Check for updates to installed packs
                self.packUpdates.removeAll()
                for remotePack in packs {
                    if let localPack = self.installedPacks.first(where: { $0.id == remotePack.id }) {
                        // Compare versions
                        if self.isNewerVersion(remotePack.version, than: localPack.version) {
                            self.packUpdates[remotePack.id] = remotePack.version
                            logger.info("Update available for \(remotePack.id): \(localPack.version) -> \(remotePack.version)")
                        }
                    }
                }

                self.availablePacks = packs.filter { remoteInfo in
                    // Only show packs that are NOT installed at all
                    let isInstalled = installedPacks.contains { $0.id == remoteInfo.id }
                    if isInstalled {
                        logger.debug("Pack \(remoteInfo.id) is already installed")
                        return false
                    }
                    return true
                }
                logger.debug("Available packs after filtering: \(self.availablePacks.count)")
                isLoading = false
            }
        } catch {
            logger.error("Failed to fetch available packs from \(url): \(error.localizedDescription)")
            // Fallback: retry using main if we were targeting a tag
            if selectedRef != "main" {
                logger.info("Retrying packs.json from main as fallback...")
                selectedRef = "main"
                await fetchAvailablePacks()
                return
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }

    func downloadPack(_ packInfo: RemotePackInfo) async throws {
        try validatePackId(packInfo.id)
        try await requirePurchase(for: packInfo.id)

        logger.info("Starting download for pack: \(packInfo.id)")

        await updateSelectedRefIfNeeded()
        // Replace '/main/' in downloadUrl with the selected ref for schema compatibility
        let adjustedURLString = packInfo.downloadUrl.replacingOccurrences(of: "/main/", with: "/\(selectedRef)/")
        guard let baseURL = URL(string: adjustedURLString) else {
            logger.error("Invalid URL: \(packInfo.downloadUrl)")
            throw PackError.invalidURL
        }

        // Create pack directory
        let packDir = packsDirectory.appendingPathComponent(packInfo.id)
        logger.debug("Creating directory at: \(packDir.path)")
        try FileManager.default.createDirectory(at: packDir,
                                               withIntermediateDirectories: true)

        // Download manifest.json
        let manifestURL = baseURL.appendingPathComponent("manifest.json")
        logger.debug("Downloading manifest from: \(manifestURL)")
        let (manifestData, response) = try await URLSession.shared.data(from: manifestURL)

        if let httpResponse = response as? HTTPURLResponse {
            logger.debug("Manifest download response code: \(httpResponse.statusCode)")
        }

        let manifestPath = packDir.appendingPathComponent("manifest.json")
        try manifestData.write(to: manifestPath)
        logger.debug("Saved manifest to: \(manifestPath.path)")

        // Parse manifest to get categories
        let manifest = try JSONDecoder().decode(PromptPack.self, from: manifestData)
        logger.debug("Manifest has \(manifest.categories.count) categories")

        // Download each category TSV file
        for category in manifest.categories {
            let tsvURL = baseURL.appendingPathComponent(category.file)
            logger.debug("Downloading TSV from: \(tsvURL)")
            let (tsvData, tsvResponse) = try await URLSession.shared.data(from: tsvURL)

            if let httpResponse = tsvResponse as? HTTPURLResponse {
                logger.debug("TSV download response code: \(httpResponse.statusCode)")
            }

            let tsvPath = packDir.appendingPathComponent(category.file)
            try tsvData.write(to: tsvPath)
            logger.debug("Saved TSV to: \(tsvPath.path)")
        }

        logger.info("Pack download completed successfully")

        // Reload packs
        await MainActor.run {
            loadInstalledPacks()
        }
    }

    func togglePack(_ packId: String, enabled: Bool) {
        if let index = installedPacks.firstIndex(where: { $0.id == packId }) {
            installedPacks[index].isEnabled = enabled

            // Save to UserDefaults
            var enabledPacks = UserDefaults.standard.dictionary(forKey: "enabledPacks") as? [String: Bool] ?? [:]
            enabledPacks[packId] = enabled
            UserDefaults.standard.set(enabledPacks, forKey: "enabledPacks")
        }
    }

    func deletePack(_ packId: String) {
        // Can't delete core pack
        if packId == "core" { return }

        let packDir = packsDirectory.appendingPathComponent(packId)
        do {
            try FileManager.default.removeItem(at: packDir)
        } catch {
            logger.error("Failed to delete pack \(packId): \(error.localizedDescription)")
        }

        loadInstalledPacks()
    }

    func clearAllPackData() {
        // Remove all pack data from documents directory
        if FileManager.default.fileExists(atPath: packsDirectory.path) {
            do {
                try FileManager.default.removeItem(at: packsDirectory)
            } catch {
                logger.error("Failed to remove packs directory: \(error.localizedDescription)")
            }
        }

        // Recreate the directory
        do {
            try FileManager.default.createDirectory(at: packsDirectory,
                                                    withIntermediateDirectories: true)
        } catch {
            logger.error("Failed to recreate packs directory: \(error.localizedDescription)")
        }

        // Clear pack-related UserDefaults
        UserDefaults.standard.removeObject(forKey: "enabledPacks")
        UserDefaults.standard.removeObject(forKey: "installedPackVersions")

        // Reinstall the embedded Core pack
        installEmbeddedCorePackIfNeeded()

        // Reload packs
        loadInstalledPacks()

        // Clear the pack updates tracking
        packUpdates.removeAll()
    }

    func updatePack(_ packId: String) async throws {
        try validatePackId(packId)
        try await requirePurchase(for: packId)

        logger.info("Updating pack \(packId) from GitHub...")
        await updateSelectedRefIfNeeded()

        // Determine the download URL based on pack ID
        let baseURL: String
        if packId == "core" {
            baseURL = "\(githubRepoRoot)/\(selectedRef)/packs/core/"
        } else {
            baseURL = "\(githubRepoRoot)/\(selectedRef)/packs/\(packId)/"
        }

        // Download to documents directory
        let packDir = packsDirectory.appendingPathComponent(packId)

        do {
            try FileManager.default.createDirectory(at: packDir,
                                                   withIntermediateDirectories: true)
            logger.debug("Created directory: \(packDir.path)")
        } catch {
            logger.error("Failed to create directory: \(error.localizedDescription)")
            throw PackError.downloadFailed
        }

        // Download manifest
        let manifestURLString = "\(baseURL)manifest.json"
        guard let manifestURL = URL(string: manifestURLString) else {
            logger.error("Invalid manifest URL: \(manifestURLString)")
            throw PackError.invalidURL
        }

        do {
            logger.debug("Downloading manifest from: \(manifestURL)")
            let (manifestData, response) = try await URLSession.shared.data(from: manifestURL)

            if let httpResponse = response as? HTTPURLResponse {
                logger.debug("Manifest response code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    throw PackError.downloadFailed
                }
            }

            let manifestPath = packDir.appendingPathComponent("manifest.json")
            try manifestData.write(to: manifestPath)
            logger.debug("Saved manifest to: \(manifestPath.path)")

            // Parse manifest to get categories
            let manifest = try JSONDecoder().decode(PromptPack.self, from: manifestData)
            logger.debug("Parsed manifest with \(manifest.categories.count) categories")

            // Download each category TSV file
            for category in manifest.categories {
                let tsvURLString = "\(baseURL)\(category.file)"
                guard let tsvURL = URL(string: tsvURLString) else {
                    logger.warning("Invalid TSV URL: \(tsvURLString)")
                    continue
                }

                logger.debug("Downloading TSV: \(category.file)")
                let (tsvData, tsvResponse) = try await URLSession.shared.data(from: tsvURL)

                if let httpResponse = tsvResponse as? HTTPURLResponse {
                    logger.debug("TSV response code: \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 200 {
                        logger.warning("Failed to download \(category.file)")
                        continue
                    }
                }

                let tsvPath = packDir.appendingPathComponent(category.file)
                try tsvData.write(to: tsvPath)
                logger.debug("Saved TSV: \(category.file)")
            }

            logger.info("Pack \(packId) updated successfully")

            // Reload packs
            await MainActor.run {
                loadInstalledPacks()
                PromptService.shared.reloadPrompts()
            }
        } catch {
            logger.error("Error updating pack \(packId): \(error.localizedDescription)")
            throw error
        }
    }

    func getEnabledCategories() -> [Category] {
        var categories: [Category] = []

        for pack in installedPacks where pack.isEnabled {
            for category in pack.categories {
                // Map to existing Category enum if possible
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

    /// Validates that a pack ID is safe for use in file paths and URLs (no path traversal)
    private func validatePackId(_ packId: String) throws {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        guard !packId.isEmpty,
              packId.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }),
              !packId.contains("..") else {
            logger.error("Invalid pack ID rejected: \(packId)")
            throw PackError.invalidPackId
        }
    }

    @MainActor
    private func requirePurchase(for packId: String) throws {
        guard StoreManager.shared.isPurchasedOrFree(packId) else {
            logger.warning("🛒 pack \(packId) not purchased")
            throw PackError.purchaseRequired
        }
    }
}

enum PackError: Error {
    case invalidURL
    case invalidPackId
    case downloadFailed
    case extractionFailed
    case purchaseRequired
}

// Lightweight schema descriptor fetched from the packs repo
private struct SchemaInfo: Codable {
    let schemaMajor: Int
}

extension PackManager {
    // Compare semantic versions (e.g., "1.0.1" > "1.0.0")
    func isNewerVersion(_ new: String, than old: String) -> Bool {
        let newComponents = new.split(separator: ".").compactMap { Int($0) }
        let oldComponents = old.split(separator: ".").compactMap { Int($0) }

        let maxLength = max(newComponents.count, oldComponents.count)

        for i in 0..<maxLength {
            let newValue = i < newComponents.count ? newComponents[i] : 0
            let oldValue = i < oldComponents.count ? oldComponents[i] : 0

            if newValue > oldValue {
                return true
            } else if newValue < oldValue {
                return false
            }
        }

        return false
    }
}
