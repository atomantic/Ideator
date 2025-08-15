import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var enableNotifications = true
    @State private var selectedTime = Date()
    @State private var selectedPacks: Set<String> = []
    @State private var availablePacks: [RemotePackInfo] = []
    @State private var isLoadingPacks = false
    @State private var isDownloadingPacks = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("enableNotifications") private var notificationsEnabled = false
    @AppStorage("notificationHour") private var notificationHour = 9
    @AppStorage("notificationMinute") private var notificationMinute = 0
    
    private let packManager = PackManager.shared
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        // Set default time to 9 AM
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        _selectedTime = State(initialValue: Calendar.current.date(from: components) ?? Date())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                welcomePage
                    .tag(0)
                
                benefitsPage
                    .tag(1)
                
                packsPage
                    .tag(2)
                
                notificationPage
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            bottomControls
                .padding(.horizontal)
                .padding(.bottom, 20)
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            loadAvailablePacks()
        }
    }
    
    private var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse)
            
            VStack(spacing: 16) {
                Text("Welcome to Idea Loom")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Weave your thoughts into brilliance")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Text("Transform your creative potential through daily ideation exercises")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
    
    private var benefitsPage: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 30)
            
            Text("Why Daily Ideas?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
            
            // Feature cards in a 2x2 grid
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    BenefitCard(
                        icon: "brain.fill",
                        title: "Creative\nMuscle",
                        color: .purple,
                        description: "Daily ideation strengthens creative thinking"
                    )
                    
                    BenefitCard(
                        icon: "sparkles",
                        title: "Hidden\nGems",
                        color: .orange,
                        description: "Brainstorm plans and possible futures"
                    )
                }
                
                HStack(spacing: 16) {
                    BenefitCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Compound\nGrowth",
                        color: .green,
                        description: "10 ideas daily = 3,650 per year"
                    )
                    
                    BenefitCard(
                        icon: "heart.fill",
                        title: "Mental\nClarity",
                        color: .pink,
                        description: "From to-do to gratitude"
                    )
                }
            }
            .padding(.horizontal, 20)
            
            // Inspiring quote
            VStack(spacing: 8) {
                Text("\"Become an idea machine\"")
                    .font(.headline)
                    .italic()
                    .foregroundColor(.primary)
                
                Text("— James Altucher")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            Spacer(minLength: 20)
        }
    }
    
    private var packsPage: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 20)
            
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 50))
                .foregroundColor(.purple)
                .symbolEffect(.pulse)
            
            VStack(spacing: 12) {
                Text("Expand Your Horizons")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Start with our Core pack of 200+ prompts across 14 categories")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Text("Want more? Choose additional packs:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                Text("You can always add or remove packs later in Settings")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.8))
                    .italic()
            }
            
            if isLoadingPacks {
                ProgressView("Loading available packs...")
                    .padding()
            } else if availablePacks.isEmpty {
                Text("Additional packs will be available soon!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(availablePacks, id: \.id) { pack in
                            PackSelectionRow(
                                pack: pack,
                                isSelected: selectedPacks.contains(pack.id),
                                onToggle: {
                                    if selectedPacks.contains(pack.id) {
                                        selectedPacks.remove(pack.id)
                                    } else {
                                        selectedPacks.insert(pack.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 400)
            }
            
            Spacer(minLength: 10)
        }
    }
    
    private var notificationPage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .symbolEffect(.bounce)
            
            VStack(spacing: 16) {
                Text("Build Your Daily Habit")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Get a gentle reminder to brainstorm each day")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 20) {
                Toggle("Enable Daily Reminders", isOn: $enableNotifications)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .padding(.horizontal, 40)
                
                if enableNotifications {
                    VStack(spacing: 8) {
                        Text("Remind me at:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 120)
                            .clipped()
                    }
                    .transition(.opacity)
                }
            }
            
            Spacer()
        }
    }
    
    
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if currentPage < 3 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .fontWeight(.semibold)
                } else {
                    Button(isDownloadingPacks ? "Setting up..." : "Get Started") {
                        completeOnboarding()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(isDownloadingPacks ? Color.gray : Color.blue)
                    .cornerRadius(25)
                    .disabled(isDownloadingPacks)
                }
            }
        }
    }
    
    private func completeOnboarding() {
        isDownloadingPacks = true
        
        Task {
            // Download selected packs
            for packId in selectedPacks {
                if let pack = availablePacks.first(where: { $0.id == packId }) {
                    do {
                        try await packManager.downloadPack(pack)
                    } catch {
                        print("Failed to download pack \(packId): \(error)")
                    }
                }
            }
            
            await MainActor.run {
                // Save notification preferences
                if enableNotifications {
                    let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                    notificationHour = components.hour ?? 9
                    notificationMinute = components.minute ?? 0
                    notificationsEnabled = true
                    
                    // Request notification permission and schedule
                    requestNotificationPermission()
                }
                
                // Mark onboarding as completed
                hasCompletedOnboarding = true
                isDownloadingPacks = false
                isPresented = false
                
                // Reload prompts to include new packs
                PromptService.shared.reloadPrompts()
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                scheduleDailyNotification()
            }
        }
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
    
    private func loadAvailablePacks() {
        isLoadingPacks = true
        Task {
            await packManager.fetchAvailablePacks()
            await MainActor.run {
                // Filter out already installed packs and Core pack
                let installedIds = Set(packManager.installedPacks.map { $0.id })
                availablePacks = packManager.availablePacks.filter { pack in
                    !installedIds.contains(pack.id) && pack.id != "core"
                }
                isLoadingPacks = false
            }
        }
    }
}

struct BenefitCard: View {
    let icon: String
    let title: String
    let color: Color
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 40)
            
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary.opacity(0.7))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct PackSelectionRow: View {
    let pack: RemotePackInfo
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(pack.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        Label("\(pack.promptCount) prompts", systemImage: "doc.text")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Label("\(pack.categories.count) categories", systemImage: "folder")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
