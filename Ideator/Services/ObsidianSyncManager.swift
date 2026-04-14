import Foundation
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "net.shadowpuppet.ideator", category: "ObsidianSyncManager")

final class ObsidianSyncManager {
    static let shared = ObsidianSyncManager()

    private let bookmarkKey = "obsidian_folder_bookmark"
    private let enabledKey = "obsidian_sync_enabled"
    private let writeTimestampsKey = "obsidian_write_timestamps"
    private let subfolderName = "Idea Loom"
    private var lastImportCheck: Date = .distantPast
    private var isImporting = false

    private init() {}

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    var hasFolder: Bool {
        UserDefaults.standard.data(forKey: bookmarkKey) != nil
    }

    var folderDisplayName: String? {
        resolveBookmark()?.lastPathComponent
    }

    // MARK: - Bookmark Management

    func saveBookmark(for url: URL) -> Bool {
        guard url.startAccessingSecurityScopedResource() else {
            logger.error("📁 Cannot access selected folder")
            return false
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try url.bookmarkData(
                options: .minimalBookmark,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(data, forKey: bookmarkKey)
            logger.info("📁 Saved folder bookmark: \(url.lastPathComponent)")
            return true
        } catch {
            logger.error("📁 Bookmark save failed: \(error.localizedDescription)")
            return false
        }
    }

    func clearFolder() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        isEnabled = false
    }

    private func resolveBookmark() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return nil }

        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            logger.error("📁 Bookmark resolution failed")
            return nil
        }

        if isStale {
            if url.startAccessingSecurityScopedResource() {
                if let refreshed = try? url.bookmarkData(
                    options: .minimalBookmark,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                ) {
                    UserDefaults.standard.set(refreshed, forKey: bookmarkKey)
                }
                url.stopAccessingSecurityScopedResource()
            }
        }

        return url
    }

    // MARK: - File Operations

    private func withFolder(_ action: (URL) -> Void) {
        guard isEnabled, let folderURL = resolveBookmark() else { return }
        guard folderURL.startAccessingSecurityScopedResource() else {
            logger.error("📁 Security-scoped access denied")
            return
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }
        action(folderURL)
    }

    func syncIdeaList(_ ideaList: IdeaList) {
        guard !isImporting else { return }
        withFolder { folderURL in
            let subfolder = folderURL.appendingPathComponent(subfolderName)

            do {
                try FileManager.default.createDirectory(at: subfolder, withIntermediateDirectories: true)
                let name = fileName(for: ideaList)
                let fileURL = subfolder.appendingPathComponent(name)
                try formatMarkdown(ideaList).write(to: fileURL, atomically: true, encoding: .utf8)
                recordWriteTimestamp(for: name, at: fileURL)
                logger.info("📁 Synced: \(name)")
            } catch {
                logger.error("📁 Sync failed: \(error.localizedDescription)")
            }
        }
    }

    func deleteFile(for ideaList: IdeaList) {
        withFolder { folderURL in
            let name = fileName(for: ideaList)
            let fileURL = folderURL
                .appendingPathComponent(subfolderName)
                .appendingPathComponent(name)
            try? FileManager.default.removeItem(at: fileURL)
            removeWriteTimestamp(for: name)
            logger.info("📁 Deleted: \(name)")
        }
    }

    @discardableResult
    func syncAll() -> Int {
        let persistence = PersistenceManager.shared
        let allLists = persistence.loadDrafts() + persistence.loadCompleted()
        for list in allLists {
            syncIdeaList(list)
        }
        logger.info("📁 Full sync complete: \(allLists.count) lists")
        return allLists.count
    }

    // MARK: - Import External Changes

    func importExternalChangesIfNeeded() {
        guard isEnabled,
              !isImporting,
              Date().timeIntervalSince(lastImportCheck) > 30 else { return }
        lastImportCheck = Date()
        isImporting = true
        defer { isImporting = false }
        importExternalChanges()
    }

    private func importExternalChanges() {
        guard let folderURL = resolveBookmark() else { return }
        guard folderURL.startAccessingSecurityScopedResource() else { return }
        defer { folderURL.stopAccessingSecurityScopedResource() }

        let subfolder = folderURL.appendingPathComponent(subfolderName)
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: subfolder,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return }

        var drafts: [IdeaList] = loadDirectly(forKey: "ideator_drafts") ?? []
        var completed: [IdeaList] = loadDirectly(forKey: "ideator_completed") ?? []
        var changed = false

        for file in files where file.pathExtension == "md" {
            let name = file.lastPathComponent
            guard wasExternallyModified(fileName: name, at: file) else { continue }

            guard let content = try? String(contentsOf: file, encoding: .utf8),
                  let imported = parseMarkdown(content) else { continue }

            if let idx = drafts.firstIndex(where: { $0.id == imported.id }) {
                drafts[idx].ideas = imported.ideas
                drafts[idx].modifiedDate = Date()
                changed = true
                logger.info("📁 Imported changes to draft: \(name)")
            } else if let idx = completed.firstIndex(where: { $0.id == imported.id }) {
                completed[idx].ideas = imported.ideas
                completed[idx].modifiedDate = Date()
                changed = true
                logger.info("📁 Imported changes to completed: \(name)")
            }

            recordWriteTimestamp(for: name, at: file)
        }

        if changed {
            saveDirectly(drafts, forKey: "ideator_drafts")
            saveDirectly(completed, forKey: "ideator_completed")
            logger.info("📁 External changes imported")
        }
    }

    // MARK: - Write Timestamp Tracking

    private func recordWriteTimestamp(for fileName: String, at fileURL: URL) {
        let modDate = (try? FileManager.default.attributesOfItem(atPath: fileURL.path))?[.modificationDate] as? Date
        var timestamps = UserDefaults.standard.dictionary(forKey: writeTimestampsKey) as? [String: Double] ?? [:]
        timestamps[fileName] = modDate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
        UserDefaults.standard.set(timestamps, forKey: writeTimestampsKey)
    }

    private func removeWriteTimestamp(for fileName: String) {
        var timestamps = UserDefaults.standard.dictionary(forKey: writeTimestampsKey) as? [String: Double] ?? [:]
        timestamps.removeValue(forKey: fileName)
        UserDefaults.standard.set(timestamps, forKey: writeTimestampsKey)
    }

    private func wasExternallyModified(fileName: String, at fileURL: URL) -> Bool {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let fileModDate = attrs[.modificationDate] as? Date else { return false }

        let timestamps = UserDefaults.standard.dictionary(forKey: writeTimestampsKey) as? [String: Double] ?? [:]
        guard let lastWrite = timestamps[fileName] else { return true }

        return fileModDate.timeIntervalSince1970 > lastWrite + 1.0
    }

    // MARK: - Markdown Parsing

    private struct ImportedIdeaList {
        let id: UUID
        let ideas: [String]
    }

    private func parseMarkdown(_ content: String) -> ImportedIdeaList? {
        let lines = content.components(separatedBy: .newlines)

        // Find frontmatter boundaries
        var fmStart = -1
        var fmEnd = -1
        for (i, line) in lines.enumerated() {
            if line.trimmingCharacters(in: .whitespaces) == "---" {
                if fmStart == -1 { fmStart = i }
                else { fmEnd = i; break }
            }
        }
        guard fmStart >= 0, fmEnd > fmStart else { return nil }

        // Extract ID from frontmatter
        var id: UUID?
        for i in (fmStart + 1)..<fmEnd {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("id: ") {
                id = UUID(uuidString: String(line.dropFirst(4)))
            }
        }
        guard let id else { return nil }

        // Extract numbered ideas from body
        let ideaPattern = /^\d+\.\s+(.+)$/
        var ideas: [String] = []
        for i in (fmEnd + 1)..<lines.count {
            if let match = lines[i].firstMatch(of: ideaPattern) {
                ideas.append(String(match.1))
            }
        }

        return ImportedIdeaList(id: id, ideas: ideas)
    }

    // MARK: - Direct UserDefaults Access (bypasses PersistenceManager to avoid sync loops)

    private func loadDirectly<T: Codable>(forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func saveDirectly<T: Codable>(_ object: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(object) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    // MARK: - Markdown Formatting

    private func fileName(for ideaList: IdeaList) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: ideaList.createdDate)
        let title = sanitize(ideaList.prompt.formattedTitle)
        return "\(dateStr) \(title).md"
    }

    private func sanitize(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:*?\"<>|#[]")
        return name.components(separatedBy: invalid).joined(separator: "-")
    }

    private func formatMarkdown(_ ideaList: IdeaList) -> String {
        let iso = ISO8601DateFormatter()
        let status = ideaList.isComplete ? "completed" : "draft"
        let category = ideaList.prompt.flexibleCategory.name
        let tag = category.lowercased()
            .replacingOccurrences(of: " & ", with: "-")
            .replacingOccurrences(of: " ", with: "-")

        var md = "---\n"
        md += "id: \(ideaList.id.uuidString)\n"
        md += "title: \"\(escapeYAML(ideaList.prompt.formattedTitle))\"\n"
        md += "category: \"\(escapeYAML(category))\"\n"
        md += "status: \(status)\n"
        md += "created: \(iso.string(from: ideaList.createdDate))\n"
        md += "modified: \(iso.string(from: ideaList.modifiedDate))\n"
        md += "tags:\n"
        md += "  - idea-loom\n"
        md += "  - idea-loom/\(tag)\n"
        md += "  - idea-loom/\(status)\n"
        md += "---\n\n"
        md += "# \(ideaList.prompt.formattedTitle)\n\n"

        if let help = ideaList.prompt.help, !help.isEmpty {
            md += "> \(help)\n\n"
        }

        let filled = ideaList.ideas.filter { !$0.isEmpty }
        if filled.isEmpty {
            md += "*No ideas yet*\n"
        } else {
            for (i, idea) in filled.enumerated() {
                md += "\(i + 1). \(idea)\n"
            }
        }

        return md
    }

    private func escapeYAML(_ str: String) -> String {
        str.replacingOccurrences(of: "\"", with: "\\\"")
    }
}
