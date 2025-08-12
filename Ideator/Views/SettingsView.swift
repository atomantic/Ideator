import SwiftUI
import UserNotifications

struct SettingsView: View {
    let promptViewModel: PromptViewModel
    @AppStorage("defaultListSize") private var defaultListSize = 10
    @AppStorage("enableNotifications") private var enableNotifications = false
    @State private var showingResetAlert = false
    @State private var showingClearDataAlert = false
    
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
                PersistenceManager.shared.clearAll()
                promptViewModel.resetUsedPrompts()
            }
        } message: {
            Text("This will delete all drafts and completed lists. This action cannot be undone.")
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
                    Text("\(PackManager.shared.installedPacks.filter { $0.isEnabled }.count) active")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
            
            ForEach(Category.allCases, id: \.self) { category in
                NavigationLink(destination: CategoryPromptsDetailView(
                    category: category,
                    promptViewModel: promptViewModel
                )) {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(category.colorValue)
                            .frame(width: 30)
                        
                        Text(category.rawValue)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        let unused = promptViewModel.getUnusedPromptsCount(for: category)
                        let total = promptViewModel.getPromptsForCategory(category).count
                        Text("\(unused)/\(total)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var dataSection: some View {
        Section("Data") {
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
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            
            Link(destination: URL(string: "https://github.com/atomantic/idealoom")!) {
                HStack {
                    Text("Source Code")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
    
    private func scheduleDailyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time for Ideas!"
        content.body = "Ready to brainstorm? Open Idea Loom for today's creative prompt."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily-prompt",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}