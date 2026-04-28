import SwiftUI
import UserNotifications
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "net.shadowpuppet.ideator", category: "OnboardingView")

/// The user's stated primary motivation captured during onboarding. Persisted via
/// `@AppStorage("primaryIdeationGoal")` so later screens (and the first-prompt
/// reveal at the end of onboarding) can bias their content toward what the user
/// actually came here for.
enum IdeationGoal: String, CaseIterable, Codable {
    case creative
    case business
    case journaling
    case learning
    case surpriseMe

    var emoji: String {
        switch self {
        case .creative:    return "🎨"
        case .business:    return "💡"
        case .journaling:  return "🧠"
        case .learning:    return "📚"
        case .surpriseMe:  return "🎲"
        }
    }

    var label: String {
        switch self {
        case .creative:    return "Creative projects (art, writing, music)"
        case .business:    return "Business and product ideas"
        case .journaling:  return "Personal reflection and journaling"
        case .learning:    return "Learning new things"
        case .surpriseMe:  return "Surprise me daily"
        }
    }

    /// Maps the goal to a starter Category for the first-prompt reveal at the end
    /// of onboarding. Returns nil for `surpriseMe` so the reveal pulls a random
    /// prompt from the user's full enabled-pack pool.
    var seedCategory: Category? {
        switch self {
        case .creative:    return .creative
        case .business:    return .professional
        case .journaling:  return .gratitude
        case .learning:    return .learning
        case .surpriseMe:  return nil
        }
    }
}

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var enableNotifications = false
    @State private var selectedTime = Date()
    @State private var selectedGoal: IdeationGoal?
    @State private var firstPrompt: Prompt?
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("enableNotifications") private var notificationsEnabled = false
    @AppStorage("notificationHour") private var notificationHour = 9
    @AppStorage("notificationMinute") private var notificationMinute = 0
    @AppStorage("primaryIdeationGoal") private var primaryIdeationGoalRaw = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var heroIconSize: CGFloat = 80
    @ScaledMetric(relativeTo: .largeTitle) private var notificationIconSize: CGFloat = 60
    @ScaledMetric(relativeTo: .largeTitle) private var firstPromptIconSize: CGFloat = 60

    private let totalPages = 5

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

                goalPage
                    .tag(1)

                benefitsPage
                    .tag(2)

                notificationPage
                    .tag(3)

                firstPromptPage
                    .tag(4)
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

    // MARK: - Page 0: Welcome with privacy bullets

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)

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

            VStack(spacing: 12) {
                Text("Welcome to Idea Loom")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Weave your thoughts into brilliance")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("10 prompts a day. Yours alone. Export wherever you keep notes.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 14) {
                privacyBullet(
                    icon: "lock.shield.fill",
                    title: "Private by design",
                    detail: "No accounts, no servers, no telemetry. Your ideas stay on your device."
                )
                privacyBullet(
                    icon: "icloud.fill",
                    title: "Synced through your iCloud",
                    detail: "Your prompts and history sync across your iPhone, iPad, and Mac via your own iCloud."
                )
                privacyBullet(
                    icon: "square.and.arrow.up",
                    title: "Export anytime",
                    detail: "Send any session straight to Apple Notes — or export the lot whenever you like."
                )
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 20)
        }
    }

    @ViewBuilder
    private func privacyBullet(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, alignment: .center)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Page 1: Goal question

    private var goalPage: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 30)

            Text("What kind of ideas do you most want to grow?")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text("Pick one. We'll lean your prompts in that direction. You can change it later.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(spacing: 10) {
                ForEach(IdeationGoal.allCases, id: \.self) { goal in
                    goalCard(goal)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Spacer(minLength: 20)
        }
    }

    @ViewBuilder
    private func goalCard(_ goal: IdeationGoal) -> some View {
        Button {
            selectedGoal = goal
            primaryIdeationGoalRaw = goal.rawValue
        } label: {
            HStack(spacing: 14) {
                Text(goal.emoji)
                    .font(.title)
                    .frame(width: 36)
                Text(goal.label)
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundColor(selectedGoal == goal ? .white : .primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if selectedGoal == goal {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selectedGoal == goal
                          ? LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                          : LinearGradient(colors: [Color.gray.opacity(0.08), Color.gray.opacity(0.08)], startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selectedGoal == goal ? Color.clear : Color.gray.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(goal.label)
        .accessibilityAddTraits(selectedGoal == goal ? .isSelected : [])
    }

    // MARK: - Page 2: Benefits

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

    // MARK: - Page 3: Notification priming

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

                Text("Get a gentle reminder to brainstorm each day. Off by default — turn it on if you want one.")
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

    // MARK: - Page 4: First-prompt reveal (value delivery)

    private var firstPromptPage: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)

            Image(systemName: "sparkles")
                .font(.system(size: firstPromptIconSize))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, isActive: !reduceMotion)

            Text("Your first prompt")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            if let prompt = firstPrompt {
                VStack(spacing: 12) {
                    Text(prompt.text)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.xl)
                                .fill(Color.white.opacity(0.85))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.xl)
                                .stroke(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.4), .purple.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .padding(.horizontal, 24)

                    if let suggestion = goalSuggestionLine {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
            } else {
                ProgressView()
                    .padding(.vertical, 40)
            }

            Spacer()
        }
        .onAppear { loadFirstPromptIfNeeded() }
    }

    private var goalSuggestionLine: String? {
        guard let goal = selectedGoal, goal != .surpriseMe else { return nil }
        return "Tuned to your goal: \(goal.label.lowercased())"
    }

    private func loadFirstPromptIfNeeded() {
        guard firstPrompt == nil else { return }
        let category = selectedGoal?.seedCategory
        firstPrompt = PromptService.shared.getRandomPrompt(from: category)
            ?? PromptService.shared.getRandomPrompt(from: nil)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
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

                if currentPage < totalPages - 1 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(currentPage == 1 && selectedGoal == nil)
                } else {
                    Button("Start brainstorming") {
                        completeOnboarding()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
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
            RoundedRectangle(cornerRadius: Theme.Radius.large)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.large)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
