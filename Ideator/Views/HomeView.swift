import SwiftUI

struct HomeView: View {
    let promptViewModel: PromptViewModel
    let ideaListViewModel: IdeaListViewModel
    @Binding var showingPromptSelection: Bool
    @Binding var showingIdeaInput: Bool

    @State private var animateGradient = false
    @State private var showingCustomPrompt = false
    @State private var currentStreak = 0
    @State private var streakStatus = StreakManager.StreakStatus.neverStarted
    @State private var showingMilestone = false
    @State private var milestoneStreak = 0
    @State private var showPurchaseError = false
    @State private var purchaseErrorMessage = ""

    @StateObject private var packManager = PackManager.shared
    @StateObject private var storeManager = StoreManager.shared
    private let streakManager = StreakManager.shared

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    heroSection

                    streakSection

                    quickStartSection

                    recentCategoriesSection
                        .id("categories")

                    availablePacksSection
                }
                .padding()
            }
            .onAppear {
                updateStreakDisplay()
            }
            .onReceive(NotificationCenter.default.publisher(for: .streakUpdated)) { _ in
                updateStreakDisplay()
            }
            .onReceive(NotificationCenter.default.publisher(for: .streakMilestone)) { notification in
                if let streak = notification.userInfo?["streak"] as? Int {
                    milestoneStreak = streak
                    showingMilestone = true
                }
            }
            .sheet(isPresented: $showingCustomPrompt) {
                CustomPromptView(
                    ideaListViewModel: ideaListViewModel,
                    showingIdeaInput: $showingIdeaInput
                )
            }
            .alert("Streak Milestone! 🎉", isPresented: $showingMilestone) {
                Button("Awesome!") {}
            } message: {
                Text(getMilestoneMessage(for: milestoneStreak))
            }
            .alert("Purchase Failed", isPresented: $showPurchaseError) {
                Button("OK") {}
            } message: {
                Text(purchaseErrorMessage)
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse)
                .accessibilityHidden(true)

            Text("Become an idea machine")
                .font(.title2)
                .fontWeight(.bold)

            Text("Choose a prompt and start ideating")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }

    private var streakSection: some View {
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(currentStreak > 0 ? .orange : .gray)
                        .accessibilityHidden(true)

                    Text("\(currentStreak)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                Text("Day Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(streakStatus.emoji + " " + streakStatus.message)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )

            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundColor(streakManager.longestStreak > 0 ? .yellow : .gray)
                        .accessibilityHidden(true)

                    Text("\(streakManager.longestStreak)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                Text("Best Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(streakManager.totalCompletedLists) total lists")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
    }

    private var quickStartSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                if let randomPrompt = promptViewModel.getRandomPrompt() {
                    ideaListViewModel.startNewList(with: randomPrompt)
                    showingIdeaInput = true
                }
            }) {
                HStack {
                    Image(systemName: "dice.fill")
                        .font(.title2)

                    VStack(alignment: .leading) {
                        Text("Random Topic")
                            .font(.headline)
                        Text("Let fate decide your next idea list")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                showingCustomPrompt = true
            }) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.purple)

                    VStack(alignment: .leading) {
                        Text("Create Custom Topic")
                            .font(.headline)
                        Text("Write your own creative challenge")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [.purple.opacity(0.1), .pink.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var recentCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            let groupedCategories = promptViewModel.getCategoriesGroupedByPack()

            ForEach(Array(groupedCategories.enumerated()), id: \.element.packId) { index, group in
                VStack(alignment: .leading, spacing: 12) {
                    if let packName = group.packName {
                        Text(packName)
                            .font(.headline)
                            .padding(.top, index > 0 ? 8 : 0)
                    } else if index == 0 && groupedCategories.count > 1 {
                        Text("Core")
                            .font(.headline)
                    }

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ], spacing: 10) {
                        ForEach(group.categories, id: \.id) { flexCategory in
                            FlexibleCategoryCard(
                                category: flexCategory,
                                count: promptViewModel.getUnusedPromptsCount(for: flexCategory)
                            ) {
                                promptViewModel.selectFlexibleCategory(flexCategory)
                                showingPromptSelection = true
                            }
                        }
                    }
                }
            }
        }
    }

    private func updateStreakDisplay() {
        currentStreak = streakManager.currentStreak
        streakStatus = streakManager.getStreakStatus()
    }

    private func getMilestoneMessage(for streak: Int) -> String {
        switch streak {
        case 3:
            return "You've completed 3 days in a row! You're building a great habit. Keep it up!"
        case 7:
            return "One week streak! You're on fire! Your creativity is flowing."
        case 14:
            return "Two weeks of daily ideas! You're unstoppable!"
        case 30:
            return "30 day streak! You've mastered the art of daily ideation. Incredible dedication!"
        case 60:
            return "60 days! Two months of creative brilliance. You're an idea machine!"
        case 100:
            return "100 DAYS! Triple digits! You've reached legendary status!"
        case 365:
            return "ONE FULL YEAR! 365 days of ideas! You are truly extraordinary!"
        default:
            return "Amazing streak of \(streak) days! Keep those creative juices flowing!"
        }
    }

    @ViewBuilder
    private var availablePacksSection: some View {
        let unpurchased = packManager.unpurchasedPacks
        if !unpurchased.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Get More Packs")
                    .font(.headline)

                ForEach(unpurchased) { pack in
                    AvailablePackCard(
                        pack: pack,
                        isPurchasing: storeManager.purchasingPack == pack.id,
                        price: storeManager.product(for: pack.id)?.displayPrice,
                        onPurchase: {
                            Task {
                                let success = await storeManager.purchase(pack.id)
                                if success {
                                    PromptService.shared.reloadPrompts()
                                } else if let error = storeManager.purchaseError {
                                    purchaseErrorMessage = error
                                    showPurchaseError = true
                                }
                            }
                        }
                    )
                }
            }
        }
    }
}


struct CategoryCard: View {
    let category: Category
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(category.colorValue)

                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text("\(count) prompts")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// OPTION 1: Compact 3-column vertical layout
struct FlexibleCategoryCard: View {
    let category: FlexibleCategory
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(category.colorValue)
                    .frame(height: 32)

                Text(category.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(height: 30)

                Text("\(count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AvailablePackCard: View {
    let pack: PromptPack
    let isPurchasing: Bool
    let price: String?
    let onPurchase: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "cube.box.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(pack.name)
                            .font(.headline)

                        Text(pack.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    if isPurchasing {
                        PurchasingIndicator()
                    } else {
                        PurchaseButton(price: price, action: onPurchase)
                    }
                }

                HStack(spacing: 16) {
                    Label("\(pack.categories.count) categories", systemImage: "folder")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Label("\(pack.totalPrompts) prompts", systemImage: "lightbulb")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("by \(pack.author)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}
