import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

private enum PromoResult { case success, invalid }

// MARK: - Main Settings Hub

struct SettingsView: View {
    let promptViewModel: PromptViewModel
    var onShowOnboarding: (() -> Void)?
    @State private var storeManager = StoreManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        GeneralSettingsView()
                    } label: {
                        settingsRow(icon: "gearshape.fill", color: .gray, title: "General")
                    }

                    NavigationLink {
                        PromptsSettingsView(promptViewModel: promptViewModel)
                    } label: {
                        settingsRow(icon: "text.bubble.fill", color: .blue, title: "Prompts")
                    }

                    NavigationLink {
                        SyncSettingsView()
                    } label: {
                        settingsRow(icon: "folder.fill.badge.gearshape", color: .purple, title: "Obsidian Sync")
                    }

                    NavigationLink {
                        DataSettingsView(promptViewModel: promptViewModel, onShowOnboarding: onShowOnboarding)
                    } label: {
                        settingsRow(icon: "chart.bar.fill", color: .orange, title: "Data & Stats")
                    }
                }

                Section {
                    NavigationLink {
                        PromoCodeSettingsView()
                    } label: {
                        settingsRow(
                            icon: storeManager.isPromoUnlocked ? "checkmark.seal.fill" : "ticket.fill",
                            color: storeManager.isPromoUnlocked ? .green : .pink,
                            title: "Promo Code"
                        )
                    }

                    NavigationLink {
                        AboutSettingsView()
                    } label: {
                        settingsRow(icon: "info.circle.fill", color: .teal, title: "About")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func settingsRow(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .cornerRadius(6)
            Text(title)
        }
    }
}

// MARK: - General

struct GeneralSettingsView: View {
    @AppStorage("defaultListSize") private var defaultListSize = 10
    @AppStorage("enableNotifications") private var enableNotifications = false
    @AppStorage("notificationHour") private var notificationHour = 9
    @AppStorage("notificationMinute") private var notificationMinute = 0
    @State private var notificationTime = Date()

    var body: some View {
        Form {
            Section("Preferences") {
                Picker("Default List Size", selection: $defaultListSize) {
                    Text("5 ideas").tag(5)
                    Text("10 ideas").tag(10)
                    Text("15 ideas").tag(15)
                    Text("20 ideas").tag(20)
                }

                Toggle("Daily Prompt Notifications", isOn: $enableNotifications)
                    .onChange(of: enableNotifications) { _, newValue in
                        if newValue {
                            requestNotificationPermission()
                        } else {
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-prompt"])
                        }
                    }

                if enableNotifications {
                    DatePicker("Notification Time", selection: $notificationTime, displayedComponents: .hourAndMinute)
                        .onChange(of: notificationTime) { _, newValue in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                            notificationHour = components.hour ?? 9
                            notificationMinute = components.minute ?? 0
                            scheduleDailyNotification()
                        }
                }
            }
        }
        .navigationTitle("General")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            var components = DateComponents()
            components.hour = notificationHour
            components.minute = notificationMinute
            notificationTime = Calendar.current.date(from: components) ?? Date()
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                scheduleDailyNotification()
            } else {
                DispatchQueue.main.async {
                    enableNotifications = false
                }
            }
        }
    }

    private func scheduleDailyNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-prompt"])

        let content = UNMutableNotificationContent()
        content.title = "Time for Ideas!"
        content.body = "Ready to brainstorm? Open Idea Loom for today's creative prompt."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = notificationHour
        dateComponents.minute = notificationMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-prompt", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Prompts

struct PromptsSettingsView: View {
    let promptViewModel: PromptViewModel
    @State private var showingResetAlert = false

    var body: some View {
        Form {
            Section {
                NavigationLink(destination: PromptPacksView()) {
                    HStack {
                        Image(systemName: "square.stack.3d.up.fill")
                            .foregroundColor(.blue)
                        Text("Prompt Packs")
                        Spacer()
                        Text("\(PackManager.shared.purchasedPacks.filter { $0.isEnabled }.count) active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                NavigationLink(destination: CustomPromptsListView()) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("Custom Prompts")
                        Spacer()
                        let customCount = PersistenceManager.shared.loadCustomPrompts().count
                        if customCount > 0 {
                            Text("\(customCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Unused Prompts")
                            .font(.subheadline)
                        Text("\(promptViewModel.getUnusedPromptsCount(for: nil)) remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Reset") {
                        showingResetAlert = true
                    }
                    .buttonStyle(.bordered)
                }
            }

            let groupedCategories = promptViewModel.getCategoriesGroupedByPack()
            ForEach(Array(groupedCategories.enumerated()), id: \.offset) { _, group in
                Section(group.packName ?? "Core") {
                    ForEach(group.categories, id: \.id) { flexCategory in
                        NavigationLink(destination: FlexibleCategoryPromptsDetailView(
                            category: flexCategory,
                            promptViewModel: promptViewModel
                        )) {
                            HStack {
                                Image(systemName: flexCategory.icon)
                                    .foregroundColor(flexCategory.colorValue)
                                    .frame(width: 30)

                                Text(flexCategory.name)
                                    .font(.subheadline)

                                Spacer()

                                let unused = promptViewModel.getUnusedPromptsCount(for: flexCategory)
                                let total = promptViewModel.getPrompts(for: flexCategory).count
                                Text("\(unused)/\(total)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Prompts")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset Used Prompts", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                promptViewModel.resetUsedPrompts()
            }
        } message: {
            Text("This will mark all prompts as unused. You'll start seeing prompts you've already completed.")
        }
    }
}

// MARK: - Obsidian Sync

struct SyncSettingsView: View {
    @AppStorage("obsidian_sync_enabled") private var obsidianSyncEnabled = false
    @State private var showFolderPicker = false
    @State private var obsidianFolderName: String? = ObsidianSyncManager.shared.folderDisplayName
    @State private var syncResultMessage: String?
    @State private var showDisableConfirmation = false
    @State private var isRestoringToggle = false

    // Hint the file picker to open in iCloud Drive, where most Obsidian
    // vaults live. The document picker runs in a separate process and can
    // navigate here even though the app itself is sandboxed.
    private var iCloudDriveHint: URL {
        URL(fileURLWithPath: "/private/var/mobile/Library/Mobile Documents/com~apple~CloudDocs", isDirectory: true)
    }

    var body: some View {
        Form {
            Section {
                Toggle("Sync to Obsidian Vault", isOn: $obsidianSyncEnabled)
                    .onChange(of: obsidianSyncEnabled) { oldValue, newValue in
                        if isRestoringToggle {
                            isRestoringToggle = false
                            return
                        }
                        // Disabling with a folder bookmarked — confirm intent first
                        // so users understand their existing vault files aren't touched.
                        if oldValue && !newValue && ObsidianSyncManager.shared.hasFolder {
                            showDisableConfirmation = true
                            return
                        }
                        ObsidianSyncManager.shared.isEnabled = newValue
                        if newValue && !ObsidianSyncManager.shared.hasFolder {
                            showFolderPicker = true
                        }
                    }

                if obsidianSyncEnabled {
                    if let name = obsidianFolderName {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.purple)
                            Text(name)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Change") {
                                showFolderPicker = true
                            }
                            .font(.caption)
                        }

                        Button {
                            ObsidianSyncManager.shared.syncAll { count in
                                syncResultMessage = count == 0
                                    ? "No idea lists to sync yet. Create some drafts or completed lists first."
                                    : "Synced \(count) idea list\(count == 1 ? "" : "s") to your vault."
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundColor(.blue)
                                Text("Sync All Now")
                            }
                        }
                    } else {
                        Button("Select Vault Folder") {
                            showFolderPicker = true
                        }
                    }
                }
            } footer: {
                if obsidianSyncEnabled {
                    Text("Drafts and completed lists are saved as Markdown files in an \"Idea Loom\" subfolder with YAML frontmatter and tags for Dataview queries. Edits made in Obsidian are imported back when you next open the app.")
                } else if let name = obsidianFolderName {
                    Text("Your idea lists live on this device. Existing files at \(name)/Idea Loom are untouched — turn sync back on to resume mirroring.")
                } else {
                    Text("Your idea lists live on this device. Turn on sync to also save them as Markdown files in your Obsidian vault (great for iCloud Drive vaults that sync across devices).")
                }
            }
        }
        .navigationTitle("Obsidian Sync")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFolderPicker) {
            FolderPicker(startDirectory: iCloudDriveHint) { url in
                if let url, ObsidianSyncManager.shared.saveBookmark(for: url) {
                    obsidianFolderName = url.lastPathComponent
                    obsidianSyncEnabled = true
                    ObsidianSyncManager.shared.isEnabled = true
                    ObsidianSyncManager.shared.syncAll()
                } else if !ObsidianSyncManager.shared.hasFolder {
                    obsidianSyncEnabled = false
                    ObsidianSyncManager.shared.isEnabled = false
                }
            }
            .ignoresSafeArea()
        }
        .alert(
            "Obsidian Sync",
            isPresented: Binding(
                get: { syncResultMessage != nil },
                set: { if !$0 { syncResultMessage = nil } }
            ),
            presenting: syncResultMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .alert("Turn off Obsidian Sync?", isPresented: $showDisableConfirmation) {
            Button("Cancel", role: .cancel) {
                isRestoringToggle = true
                obsidianSyncEnabled = true
            }
            Button("Turn Off") {
                ObsidianSyncManager.shared.isEnabled = false
            }
            Button("Turn Off & Delete Vault Files", role: .destructive) {
                ObsidianSyncManager.shared.deleteAllVaultFiles()
                ObsidianSyncManager.shared.isEnabled = false
            }
        } message: {
            if let name = obsidianFolderName {
                Text("Your idea lists will remain on this device. Existing Markdown files at \(name)/Idea Loom will stay where they are unless you choose to delete them.")
            } else {
                Text("Your idea lists will remain on this device. New lists will stop being mirrored to your vault.")
            }
        }
    }
}

private struct FolderPicker: UIViewControllerRepresentable {
    let startDirectory: URL?
    let onPick: (URL?) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
        picker.allowsMultipleSelection = false
        picker.directoryURL = startDirectory
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL?) -> Void
        init(onPick: @escaping (URL?) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls.first)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPick(nil)
        }
    }
}

// MARK: - Data & Stats

struct DataSettingsView: View {
    let promptViewModel: PromptViewModel
    var onShowOnboarding: (() -> Void)?
    @State private var showingClearDataAlert = false

    var body: some View {
        Form {
            Section("Stats") {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .frame(width: 30)

                    VStack(alignment: .leading) {
                        Text("Current Streak")
                        Text("\(StreakManager.shared.currentStreak) days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Best: \(StreakManager.shared.longestStreak)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Total: \(StreakManager.shared.totalCompletedLists)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Drafts")
                        Text("\(PersistenceManager.shared.loadDrafts().count) saved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Completed Lists")
                        Text("\(PersistenceManager.shared.loadCompleted().count) saved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }

            Section {
                Button("Clear All Data", role: .destructive) {
                    showingClearDataAlert = true
                }
            }
        }
        .navigationTitle("Data & Stats")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will delete all drafts, completed lists, and downloaded prompt packs. The Core pack will be reinstalled fresh. The app will show the introduction again on next launch. This action cannot be undone.")
        }
    }

    private func resetAllData() {
        PersistenceManager.shared.clearAll()
        promptViewModel.resetUsedPrompts()
        UserDefaults.standard.removeObject(forKey: "enabledPacks")
        PromptService.shared.reloadPrompts()
        StreakManager.shared.resetAllStats()

        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")

        UserDefaults.standard.set(false, forKey: "enableNotifications")
        UserDefaults.standard.removeObject(forKey: "notificationHour")
        UserDefaults.standard.removeObject(forKey: "notificationMinute")

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-prompt"])

        onShowOnboarding?()
    }
}

// MARK: - Promo Code

struct PromoCodeSettingsView: View {
    @State private var promoCode = ""
    @State private var promoResult: PromoResult?
    @State private var storeManager = StoreManager.shared

    var body: some View {
        Form {
            if storeManager.isPromoUnlocked {
                Section {
                    Label("All packs unlocked", systemImage: "checkmark.seal.fill")
                        .foregroundColor(.green)
                }
            } else {
                Section {
                    HStack {
                        TextField("Enter code", text: $promoCode)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Button("Redeem") {
                            let success = storeManager.redeemPromoCode(promoCode)
                            promoResult = success ? .success : .invalid
                            if success { promoCode = "" }
                        }
                        .disabled(promoCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if let result = promoResult {
                        Text(result == .success ? "All packs unlocked!" : "Invalid code")
                            .font(.caption)
                            .foregroundColor(result == .success ? .green : .red)
                    }
                } footer: {
                    Text("Have a promo code? Enter it here to unlock all prompt packs.")
                }
            }
        }
        .navigationTitle("Promo Code")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - About

struct AboutSettingsView: View {
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersionString)
                        .foregroundColor(.secondary)
                }

                Link(destination: URL(string: "https://github.com/atomantic/IdeatorPromptPacks/issues") ?? URL(string: "https://github.com")!) {
                    HStack {
                        Text("Contact Support")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Created with passion for creativity")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Idea Loom helps you brainstorm and capture ideas through guided prompts.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
}
