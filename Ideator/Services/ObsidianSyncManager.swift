import Foundation
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "net.shadowpuppet.ideator", category: "ObsidianSyncManager")

/// Mirrors idea lists to a user-selected Obsidian vault as Markdown files.
///
/// Every filesystem touch — and the Markdown rendering that feeds it — runs on
/// `queue`. Vaults typically live in iCloud Drive, where resolving a
/// security-scoped bookmark, enumerating the folder or writing a file can each
/// stall for seconds while the file provider does its work, so none of it may
/// happen on the main thread. Writes are coalesced per file, so a burst of
/// edits produces one render and one file write instead of one per keystroke.
final class ObsidianSyncManager {
    static let shared = ObsidianSyncManager()

    private let bookmarkKey = "obsidian_folder_bookmark"
    private let enabledKey = "obsidian_sync_enabled"
    private let writeTimestampsKey = "obsidian_write_timestamps"
    private let subfolderName = "Idea Loom"

    /// Serial so bookmark resolution, writes and imports never overlap.
    private let queue = DispatchQueue(label: "net.shadowpuppet.ideator.obsidian-sync", qos: .utility)

    /// How long to wait for further edits before writing to the vault.
    private let writeDebounce: DispatchTimeInterval = .milliseconds(750)
    private let importThrottle: TimeInterval = 30

    /// Formatters are expensive to build and thread-safe to format with.
    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    private static let isoFormatter = ISO8601DateFormatter()

    // All queue-confined.
    private var pendingWrites: [String: String] = [:]
    private var flushScheduled = false
    private var lastImportCheck: Date = .distantPast

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

    /// Runs `action` with security-scoped access to the vault folder.
    /// `requireEnabled: false` lets cleanup run after the user has already
    /// toggled sync off but still wants the mirror removed.
    private func withFolder(requireEnabled: Bool = true, _ action: (URL) -> Void) {
        guard !requireEnabled || isEnabled, let folderURL = resolveBookmark() else { return }
        guard folderURL.startAccessingSecurityScopedResource() else {
            logger.error("📁 Security-scoped access denied")
            return
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }
        action(folderURL)
    }

    /// Queues `ideaList` to be mirrored. Returns immediately — the Markdown is
    /// rendered on the queue, so a burst of edits renders once, not once each.
    func syncIdeaList(_ ideaList: IdeaList) {
        guard isEnabled else { return }

        queue.async { [self] in
            pendingWrites[fileName(for: ideaList)] = formatMarkdown(ideaList)
            scheduleFlush()
        }
    }

    /// Deletes the entire "Idea Loom" subfolder from the vault.
    func deleteAllVaultFiles() {
        queue.async { [self] in
            pendingWrites.removeAll()
            withFolder(requireEnabled: false) { folderURL in
                let subfolder = folderURL.appendingPathComponent(subfolderName)
                try? FileManager.default.removeItem(at: subfolder)
                UserDefaults.standard.removeObject(forKey: writeTimestampsKey)
                logger.info("📁 Deleted all vault files")
            }
        }
    }

    func deleteFile(for ideaList: IdeaList) {
        queue.async { [self] in
            let name = fileName(for: ideaList)
            pendingWrites.removeValue(forKey: name)
            withFolder { folderURL in
                let fileURL = folderURL
                    .appendingPathComponent(subfolderName)
                    .appendingPathComponent(name)
                try? FileManager.default.removeItem(at: fileURL)

                var timestamps = writeTimestamps()
                timestamps.removeValue(forKey: name)
                saveWriteTimestamps(timestamps)
                logger.info("📁 Deleted: \(name)")
            }
        }
    }

    /// Mirrors every stored list, bypassing the write debounce. `completion`
    /// reports the count on the main queue once the vault writes have finished.
    func syncAll(completion: ((Int) -> Void)? = nil) {
        let persistence = PersistenceManager.shared
        let allLists = persistence.loadDrafts() + persistence.loadCompleted()
        let count = allLists.count
        allLists.forEach(syncIdeaList)

        queue.async { [self] in
            flushPendingWrites()
            logger.info("📁 Full sync complete: \(count) lists")
            if let completion {
                DispatchQueue.main.async { completion(count) }
            }
        }
    }

    // MARK: - Debounced Writes (queue-confined)

    private func scheduleFlush() {
        guard !flushScheduled else { return }
        flushScheduled = true
        queue.asyncAfter(deadline: .now() + writeDebounce) { [self] in
            flushScheduled = false
            flushPendingWrites()
        }
    }

    private func flushPendingWrites() {
        guard !pendingWrites.isEmpty else { return }
        let batch = pendingWrites
        pendingWrites.removeAll()

        withFolder { folderURL in
            let subfolder = folderURL.appendingPathComponent(subfolderName)
            do {
                try FileManager.default.createDirectory(at: subfolder, withIntermediateDirectories: true)
            } catch {
                logger.error("📁 Sync failed: \(error.localizedDescription)")
                return
            }

            var timestamps = writeTimestamps()
            for (name, markdown) in batch {
                let fileURL = subfolder.appendingPathComponent(name)
                do {
                    try markdown.write(to: fileURL, atomically: true, encoding: .utf8)
                    timestamps[name] = (modificationDate(of: fileURL) ?? Date()).timeIntervalSince1970
                    logger.info("📁 Synced: \(name)")
                } catch {
                    logger.error("📁 Sync failed: \(error.localizedDescription)")
                }
            }
            saveWriteTimestamps(timestamps)
        }
    }

    // MARK: - Import External Changes

    /// Scans the vault for edits made outside the app, at most once every
    /// `importThrottle` seconds. Returns immediately; imported ideas are merged
    /// on the main queue and announced via `.externalIdeasImported`.
    func importExternalChangesIfNeeded() {
        guard isEnabled else { return }

        queue.async { [self] in
            guard Date().timeIntervalSince(lastImportCheck) > importThrottle else { return }
            lastImportCheck = Date()

            let imported = readExternalChanges()
            guard !imported.isEmpty else { return }

            DispatchQueue.main.async {
                PersistenceManager.shared.applyImportedIdeas(imported)
            }
        }
    }

    /// Reads vault files modified since the app last wrote them. Queue-confined;
    /// touches no shared storage beyond its own write-timestamp bookkeeping, so
    /// the merge can happen on the main queue without racing a draft save.
    private func readExternalChanges() -> [UUID: [String]] {
        var imported: [UUID: [String]] = [:]

        withFolder { folderURL in
            let subfolder = folderURL.appendingPathComponent(subfolderName)
            guard let files = try? FileManager.default.contentsOfDirectory(
                at: subfolder,
                includingPropertiesForKeys: [.contentModificationDateKey]
            ) else { return }

            var timestamps = writeTimestamps()
            var timestampsChanged = false

            for file in files where file.pathExtension == "md" {
                let name = file.lastPathComponent
                guard let modDate = modificationDate(of: file) else { continue }

                // Anything newer than our own last write (past a second of
                // filesystem timestamp slop) was edited outside the app.
                if let lastWrite = timestamps[name],
                   modDate.timeIntervalSince1970 <= lastWrite + 1.0 { continue }

                guard let content = try? String(contentsOf: file, encoding: .utf8),
                      let parsed = parseMarkdown(content) else { continue }

                imported[parsed.id] = parsed.ideas
                timestamps[name] = modDate.timeIntervalSince1970
                timestampsChanged = true
                logger.info("📁 Imported changes from: \(name)")
            }

            if timestampsChanged {
                saveWriteTimestamps(timestamps)
            }
        }

        return imported
    }

    // MARK: - Write Timestamp Tracking

    private func writeTimestamps() -> [String: Double] {
        UserDefaults.standard.dictionary(forKey: writeTimestampsKey) as? [String: Double] ?? [:]
    }

    private func saveWriteTimestamps(_ timestamps: [String: Double]) {
        UserDefaults.standard.set(timestamps, forKey: writeTimestampsKey)
    }

    private func modificationDate(of fileURL: URL) -> Date? {
        (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
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

    // MARK: - Markdown Formatting

    private func fileName(for ideaList: IdeaList) -> String {
        let dateStr = Self.fileDateFormatter.string(from: ideaList.createdDate)
        let title = sanitize(ideaList.prompt.formattedTitle)
        return "\(dateStr) \(title).md"
    }

    private func sanitize(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:*?\"<>|#[]")
        return name.components(separatedBy: invalid).joined(separator: "-")
    }

    private func formatMarkdown(_ ideaList: IdeaList) -> String {
        let iso = Self.isoFormatter
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
