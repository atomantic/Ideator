import SwiftUI
import UserNotifications
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "net.shadowpuppet.ideator", category: "OnboardingView")

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var enableNotifications = true
    @State private var selectedTime = Date()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("enableNotifications") private var notificationsEnabled = false
    @AppStorage("notificationHour") private var notificationHour = 9
    @AppStorage("notificationMinute") private var notificationMinute = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var heroIconSize: CGFloat = 80
    @ScaledMetric(relativeTo: .largeTitle) private var packsIconSize: CGFloat = 50
    @ScaledMetric(relativeTo: .largeTitle) private var notificationIconSize: CGFloat = 60

    private let packManager = PackManager.shared

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
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
    }

    private var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "lightbulb.fill")
                .font(.system(size: heroIconSize))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, isActive: !reduceMotion)

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
                .font(.system(size: packsIconSize))
                .foregroundColor(.purple)
                .symbolEffect(.pulse, isActive: !reduceMotion)

            VStack(spacing: 12) {
                Text("Expand Your Horizons")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                let corePack = packManager.allPacks.first { $0.id == "core" }
                let corePromptCount = corePack?.totalPrompts ?? 200
                let coreCategoryCount = corePack?.categories.count ?? 14

                Text("Start with our Core pack of \(corePromptCount)+ prompts across \(coreCategoryCount) categories")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Text("Plus \(packManager.allPacks.count - 1) premium packs available:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(packManager.allPacks.filter { $0.id != "core" }) { pack in
                        PackPreviewRow(pack: pack)
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: 400)

            Text("You can purchase packs anytime in Settings")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
                .italic()

            Spacer(minLength: 10)
        }
    }

    private var notificationPage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: notificationIconSize))
                .foregroundColor(.blue)
                .symbolEffect(.bounce, isActive: !reduceMotion)

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
        if enableNotifications {
            let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
            notificationHour = components.hour ?? 9
            notificationMinute = components.minute ?? 0
            notificationsEnabled = true
            requestNotificationPermission()
        }

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
                .font(.subheadline.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.primary)

            Text(description)
                .font(.caption)
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

struct PackPreviewRow: View {
    let pack: PromptPack

    var body: some View {
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
                    Label("\(pack.totalPrompts) prompts", systemImage: "doc.text")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Label("\(pack.categories.count) categories", systemImage: "folder")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text("$0.99")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
