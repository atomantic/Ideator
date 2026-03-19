import SwiftUI
import UserNotifications

struct SettingsView: View {
    let promptViewModel: PromptViewModel
    var onShowOnboarding: (() -> Void)?
    @AppStorage("defaultListSize") private var defaultListSize = 10
    @AppStorage("enableNotifications") private var enableNotifications = false
    @AppStorage("notificationHour") private var notificationHour = 9
    @AppStorage("notificationMinute") private var notificationMinute = 0
    @State private var showingResetAlert = false
    @State private var showingClearDataAlert = false
    @State private var notificationTime = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                preferencesSection
                
                promptManagementSection
                
                dataSection
                
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Reset Used Prompts", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                promptViewModel.resetUsedPrompts()
            }
        } message: {
            Text("This will mark all prompts as unused. You'll start seeing prompts you've already completed.")
        }
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will delete all drafts, completed lists, and downloaded prompt packs. The Core pack will be reinstalled fresh. The app will show the introduction again on next launch. This action cannot be undone.")
        }
        .onAppear {
            // Initialize notification time from stored values
            var components = DateComponents()
            components.hour = notificationHour
            components.minute = notificationMinute
            notificationTime = Calendar.current.date(from: components) ?? Date()
        }
    }
    
    private var preferencesSection: some View {
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
                        // Cancel notifications when disabled
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-prompt"])
                    }
                }
            
            if enableNotifications {
                DatePicker("Notification Time", selection: $notificationTime, displayedComponents: .hourAndMinute)
                    .onChange(of: notificationTime) { _, newValue in
                        let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                        notificationHour = components.hour ?? 9
                        notificationMinute = components.minute ?? 0
                        // Reschedule notification with new time
                        scheduleDailyNotification()
                    }
            }
        }
    }
    
    private var promptManagementSection: some View {
        Section("Prompt Management") {
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
            
            // Group categories by pack
            let groupedCategories = promptViewModel.getCategoriesGroupedByPack()
            ForEach(Array(groupedCategories.enumerated()), id: \.offset) { _, group in
                if groupedCategories.count > 1 {
                    Section(header: Text(group.packName ?? "Core")
                        .font(.caption)
                        .foregroundColor(.secondary)) {
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
                } else {
                    // If only one pack, don't show section headers
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
    }
    
    private var dataSection: some View {
        Section("Data & Stats") {
            // Streak Statistics
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
            
            Button("Clear All Data", role: .destructive) {
                showingClearDataAlert = true
            }
        }
    }
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersionString)
                    .foregroundColor(.secondary)
            }
            
            Link(destination: URL(string: "https://github.com/atomantic/IdeatorPromptPacks/issues")!) {
                HStack {
                    Text("Contact Support")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
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
    
    private func resetAllData() {
        PersistenceManager.shared.clearAll()
        promptViewModel.resetUsedPrompts()
        UserDefaults.standard.removeObject(forKey: "enabledPacks")
        PromptService.shared.reloadPrompts()
        StreakManager.shared.resetAllStats()

        // Reset onboarding state
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")

        // Reset notification preferences
        UserDefaults.standard.set(false, forKey: "enableNotifications")
        UserDefaults.standard.removeObject(forKey: "notificationHour")
        UserDefaults.standard.removeObject(forKey: "notificationMinute")

        // Cancel any pending notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-prompt"])

        // Show onboarding immediately
        onShowOnboarding?()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                scheduleDailyNotification()
            } else {
                DispatchQueue.main.async {
                    enableNotifications = false
                }
            }
        }
    }
    
    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
    
    private func scheduleDailyNotification() {
        // Cancel any existing notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-prompt"])
        
        let content = UNMutableNotificationContent()
        content.title = "Time for Ideas!"
        content.body = "Ready to brainstorm? Open Idea Loom for today's creative prompt."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = notificationHour
        dateComponents.minute = notificationMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily-prompt",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}