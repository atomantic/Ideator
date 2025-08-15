import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var enableNotifications = true
    @State private var selectedTime = Date()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("enableNotifications") private var notificationsEnabled = false
    @AppStorage("notificationHour") private var notificationHour = 9
    @AppStorage("notificationMinute") private var notificationMinute = 0
    
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
                
                notificationPage
                    .tag(2)
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
        VStack(spacing: 30) {
            Spacer()
            
            Text("Why Daily Ideas?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 24) {
                benefitRow(
                    icon: "brain.fill",
                    title: "Boost Creativity",
                    description: "Train your brain to think differently every day"
                )
                
                benefitRow(
                    icon: "sparkles",
                    title: "Discover Opportunities",
                    description: "Uncover hidden gems in your everyday thoughts"
                )
                
                benefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Build Momentum",
                    description: "Small daily habits lead to extraordinary results"
                )
                
                benefitRow(
                    icon: "heart.fill",
                    title: "Reduce Mental Clutter",
                    description: "Clear your mind by capturing ideas systematically"
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
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
    
    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
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
                
                if currentPage < 2 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .fontWeight(.semibold)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
                }
            }
        }
    }
    
    private func completeOnboarding() {
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
        isPresented = false
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
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}