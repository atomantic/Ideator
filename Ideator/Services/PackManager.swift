import Foundation

class PackManager: ObservableObject {
    static let shared = PackManager()
    
    @Published var installedPacks: [PromptPack] = []
    @Published var availablePacks: [RemotePackInfo] = []
    @Published var isLoading = false
    @Published var packUpdates: [String: String] = [:] // packId -> newVersion
    
    private let packsDirectory: URL
    private let githubRepo = "https://raw.githubusercontent.com/atomantic/IdeatorPromptPacks/main"
    
    private init() {
        // Get documents directory for downloaded packs
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                     in: .userDomainMask).first!
        self.packsDirectory = documentsPath.appendingPathComponent("PromptPacks")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: packsDirectory, 
                                                withIntermediateDirectories: true)
        
        // Install embedded Core pack if not already present
        installEmbeddedCorePackIfNeeded()
        
        loadInstalledPacks()
    }
    
    private func installEmbeddedCorePackIfNeeded() {
        let corePackDir = packsDirectory.appendingPathComponent("core")
        let manifestPath = corePackDir.appendingPathComponent("manifest.json")
        
        // Check if Core pack already exists
        if FileManager.default.fileExists(atPath: manifestPath.path) {
            return
        }
        
        // Create Core pack directory
        try? FileManager.default.createDirectory(at: corePackDir,
                                                withIntermediateDirectories: true)
        
        // Copy manifest.json from bundle
        guard let manifestBundlePath = Bundle.main.path(forResource: "manifest", ofType: "json") else {
            print("Core pack manifest not found in bundle")
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
                    print("TSV file not found in bundle: \(category.file)")
                    continue
                }
                
                let tsvSourceURL = URL(fileURLWithPath: tsvPath)
                let tsvDestURL = corePackDir.appendingPathComponent(category.file)
                try fileManager.copyItem(at: tsvSourceURL, to: tsvDestURL)
                print("Copied \(category.file) to documents")
            }
            
            print("Successfully installed Core pack from bundle")
        } catch {
            print("Failed to install Core pack from bundle: \(error)")
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
            print("Failed to load downloaded packs: \(error)")
            return nil
        }
    }
    
    func fetchAvailablePacks() async {
        await MainActor.run {
            isLoading = true
        }
        
        let urlString = "\(githubRepo)/packs.json"
        print("Fetching available packs from: \(urlString)")
        
        guard let url = URL(string: urlString) else { 
            print("Invalid URL for packs.json")
            return 
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Packs.json response code: \(httpResponse.statusCode)")
            }
            
            let packs = try JSONDecoder().decode([RemotePackInfo].self, from: data)
            print("Found \(packs.count) total packs")
            
            await MainActor.run {
                // Check for updates to installed packs
                self.packUpdates.removeAll()
                for remotePack in packs {
                    if let localPack = self.installedPacks.first(where: { $0.id == remotePack.id }) {
                        // Compare versions
                        if self.isNewerVersion(remotePack.version, than: localPack.version) {
                            self.packUpdates[remotePack.id] = remotePack.version
                            print("Update available for \(remotePack.id): \(localPack.version) -> \(remotePack.version)")
                        }
                    }
                }
                
                self.availablePacks = packs.filter { remoteInfo in
                    // Only show packs that are NOT installed at all
                    let isInstalled = installedPacks.contains { $0.id == remoteInfo.id }
                    if isInstalled {
                        print("Pack \(remoteInfo.id) is already installed")
                        return false
                    }
                    return true
                }
                print("Available packs after filtering: \(self.availablePacks.count)")
                isLoading = false
            }
        } catch {
            print("Failed to fetch available packs: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    func downloadPack(_ packInfo: RemotePackInfo) async throws {
        print("Starting download for pack: \(packInfo.id)")
        
        guard let baseURL = URL(string: packInfo.downloadUrl) else {
            print("Invalid URL: \(packInfo.downloadUrl)")
            throw PackError.invalidURL
        }
        
        // Create pack directory
        let packDir = packsDirectory.appendingPathComponent(packInfo.id)
        print("Creating directory at: \(packDir.path)")
        try FileManager.default.createDirectory(at: packDir, 
                                               withIntermediateDirectories: true)
        
        // Download manifest.json
        let manifestURL = baseURL.appendingPathComponent("manifest.json")
        print("Downloading manifest from: \(manifestURL)")
        let (manifestData, response) = try await URLSession.shared.data(from: manifestURL)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Manifest download response code: \(httpResponse.statusCode)")
        }
        
        let manifestPath = packDir.appendingPathComponent("manifest.json")
        try manifestData.write(to: manifestPath)
        print("Saved manifest to: \(manifestPath.path)")
        
        // Parse manifest to get categories
        let manifest = try JSONDecoder().decode(PromptPack.self, from: manifestData)
        print("Manifest has \(manifest.categories.count) categories")
        
        // Download each category TSV file
        for category in manifest.categories {
            let tsvURL = baseURL.appendingPathComponent(category.file)
            print("Downloading TSV from: \(tsvURL)")
            let (tsvData, tsvResponse) = try await URLSession.shared.data(from: tsvURL)
            
            if let httpResponse = tsvResponse as? HTTPURLResponse {
                print("TSV download response code: \(httpResponse.statusCode)")
            }
            
            let tsvPath = packDir.appendingPathComponent(category.file)
            try tsvData.write(to: tsvPath)
            print("Saved TSV to: \(tsvPath.path)")
        }
        
        print("Pack download completed successfully")
        
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
        try? FileManager.default.removeItem(at: packDir)
        
        loadInstalledPacks()
    }
    
    func clearAllPackData() {
        // Remove all pack data from documents directory
        if FileManager.default.fileExists(atPath: packsDirectory.path) {
            try? FileManager.default.removeItem(at: packsDirectory)
        }
        
        // Recreate the directory
        try? FileManager.default.createDirectory(at: packsDirectory, 
                                                withIntermediateDirectories: true)
        
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
        print("Updating pack \(packId) from GitHub...")
        
        // Determine the download URL based on pack ID
        let baseURL: String
        if packId == "core" {
            baseURL = "\(githubRepo)/packs/core/"
        } else {
            baseURL = "\(githubRepo)/packs/\(packId)/"
        }
        
        // Download to documents directory
        let packDir = packsDirectory.appendingPathComponent(packId)
        
        do {
            try FileManager.default.createDirectory(at: packDir, 
                                                   withIntermediateDirectories: true)
            print("Created directory: \(packDir.path)")
        } catch {
            print("Failed to create directory: \(error)")
            throw PackError.downloadFailed
        }
        
        // Download manifest
        let manifestURLString = "\(baseURL)manifest.json"
        guard let manifestURL = URL(string: manifestURLString) else {
            print("Invalid manifest URL: \(manifestURLString)")
            throw PackError.invalidURL
        }
        
        do {
            print("Downloading manifest from: \(manifestURL)")
            let (manifestData, response) = try await URLSession.shared.data(from: manifestURL)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Manifest response code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    throw PackError.downloadFailed
                }
            }
            
            let manifestPath = packDir.appendingPathComponent("manifest.json")
            try manifestData.write(to: manifestPath)
            print("Saved manifest to: \(manifestPath.path)")
            
            // Parse manifest to get categories
            let manifest = try JSONDecoder().decode(PromptPack.self, from: manifestData)
            print("Parsed manifest with \(manifest.categories.count) categories")
            
            // Download each category TSV file
            for category in manifest.categories {
                let tsvURLString = "\(baseURL)\(category.file)"
                guard let tsvURL = URL(string: tsvURLString) else {
                    print("Invalid TSV URL: \(tsvURLString)")
                    continue
                }
                
                print("Downloading TSV: \(category.file)")
                let (tsvData, tsvResponse) = try await URLSession.shared.data(from: tsvURL)
                
                if let httpResponse = tsvResponse as? HTTPURLResponse {
                    print("TSV response code: \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 200 {
                        print("Failed to download \(category.file)")
                        continue
                    }
                }
                
                let tsvPath = packDir.appendingPathComponent(category.file)
                try tsvData.write(to: tsvPath)
                print("Saved TSV: \(category.file)")
            }
            
            print("Pack \(packId) updated successfully")
            
            // Reload packs
            await MainActor.run {
                loadInstalledPacks()
                PromptService.shared.reloadPrompts()
            }
        } catch {
            print("Error updating pack \(packId): \(error)")
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
}

enum PackError: Error {
    case invalidURL
    case downloadFailed
    case extractionFailed
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