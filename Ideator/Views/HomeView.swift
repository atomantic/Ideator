import SwiftUI

struct HomeView: View {
    let promptViewModel: PromptViewModel
    let ideaListViewModel: IdeaListViewModel
    @Binding var showingPromptSelection: Bool
    @Binding var showingIdeaInput: Bool

    @State private var showingCustomPrompt = false
    @State private var showingMilestone = false
    @State private var milestoneStreak = 0
    @State private var newAchievements: [(id: String, name: String, icon: String)] = []
    @State private var showPurchaseError = false
    @State private var purchaseErrorMessage = ""

    @State private var packManager = PackManager.shared
    @State private var storeManager = StoreManager.shared
    @State private var streakManager = StreakManager.shared

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    heroSection

                    streakSection

                    achievementBadgesSection

                    dailyPromptSection

                    seasonalInspirationSection

                    quickStartSection

                    favoritesSection

                    bestIdeasSection

                    recentCategoriesSection
                        .id("categories")

                    availablePacksSection
                }
                .padding()
            }
            .onReceive(NotificationCenter.default.publisher(for: .streakUpdated)) { _ in
                if let earned = streakManager.checkAndAwardAchievements() {
                    newAchievements = earned
                    milestoneStreak = streakManager.currentStreak
                    withAnimation { showingMilestone = true }
                }
            }
            .sheet(isPresented: $showingCustomPrompt) {
                CustomPromptView(
                    ideaListViewModel: ideaListViewModel,
                    showingIdeaInput: $showingIdeaInput
                )
            }
            .overlay {
                if showingMilestone {
                    MilestoneCelebrationView(
                        achievements: newAchievements,
                        streak: milestoneStreak,
                        onDismiss: { showingMilestone = false }
                    )
                    .transition(.opacity)
                }
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
        let status = streakManager.getStreakStatus()
        return HStack(spacing: 16) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(streakManager.currentStreak > 0 ? .orange : .gray)
                        .accessibilityHidden(true)

                    Text("\(streakManager.currentStreak)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                Text("Day Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(status.emoji + " " + status.message)
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

    @ViewBuilder
    private var dailyPromptSection: some View {
        if let dailyPrompt = promptViewModel.getDailyPrompt() {
            let completedToday = hasDailyPromptBeenCompleted(dailyPrompt)
            Button {
                if !completedToday {
                    ideaListViewModel.startNewList(with: dailyPrompt)
                    promptViewModel.markPromptAsUsed(dailyPrompt)
                    showingIdeaInput = true
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)

                        Image(systemName: completedToday ? "checkmark" : "calendar")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Prompt of the Day")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                            .textCase(.uppercase)

                        Text(dailyPrompt.formattedTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if completedToday {
                            Text("Completed")
                                .font(.caption2)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        } else {
                            Text("Tap to start")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if !completedToday {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [.orange.opacity(0.4), .yellow.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(completedToday)
        }
    }

    private func hasDailyPromptBeenCompleted(_ prompt: Prompt) -> Bool {
        let completedLists = PersistenceManager.shared.loadCompleted()
        let calendar = Calendar.current
        return completedLists.contains { list in
            list.prompt.id == prompt.id &&
            calendar.isDateInToday(list.modifiedDate)
        }
    }

    private var seasonalInspirationSection: some View {
        let seasonal = promptViewModel.getSeasonalPrompts()
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: seasonal.icon)
                    .foregroundColor(Color.from(name: seasonal.color))
                    .font(.headline)

                Text(seasonal.title)
                    .font(.headline)
            }

            ForEach(seasonal.prompts) { prompt in
                Button {
                    ideaListViewModel.startNewList(with: prompt)
                    promptViewModel.markPromptAsUsed(prompt)
                    showingIdeaInput = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: prompt.flexibleCategory.icon)
                            .foregroundColor(Color.from(name: seasonal.color))
                            .font(.body)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(prompt.formattedTitle)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            if let help = prompt.help {
                                Text(help)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Color.from(name: seasonal.color).opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
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

    @ViewBuilder
    private var favoritesSection: some View {
        let favorites = promptViewModel.getFavoritePrompts()
        if !favorites.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("Favorites")
                        .font(.headline)
                }

                ForEach(favorites.prefix(5)) { prompt in
                    Button {
                        ideaListViewModel.startNewList(with: prompt)
                        promptViewModel.markPromptAsUsed(prompt)
                        showingIdeaInput = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: prompt.flexibleCategory.icon)
                                .foregroundColor(prompt.flexibleCategory.colorValue)
                                .font(.body)
                                .frame(width: 24)

                            Text(prompt.formattedTitle)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                if favorites.count > 5 {
                    Button {
                        showingPromptSelection = true
                    } label: {
                        Text("See all \(favorites.count) favorites")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal, 12)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
    }

    @ViewBuilder
    private var bestIdeasSection: some View {
        let starredKeys = PersistenceManager.shared.loadStarredIdeaKeys()
        if !starredKeys.isEmpty {
            let completedLists = PersistenceManager.shared.loadCompleted()
            let bestIdeas = collectBestIdeas(from: completedLists, starredKeys: starredKeys)
            if !bestIdeas.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Best Ideas")
                            .font(.headline)

                        Spacer()

                        Text("\(bestIdeas.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    ForEach(bestIdeas.prefix(5), id: \.key) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.ideaText)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(2)

                            HStack(spacing: 4) {
                                Image(systemName: item.categoryIcon)
                                    .font(.caption2)
                                    .foregroundColor(Color.from(name: item.categoryColor))
                                Text(item.promptText)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                    }

                    if bestIdeas.count > 5 {
                        NavigationLink {
                            BestIdeasFullView()
                        } label: {
                            Text("See all \(bestIdeas.count) best ideas")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                        .padding(.horizontal, 12)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
            }
        }
    }

    private func collectBestIdeas(
        from lists: [IdeaList],
        starredKeys: Set<String>
    ) -> [(key: String, ideaText: String, promptText: String, categoryIcon: String, categoryColor: String)] {
        var results: [(key: String, ideaText: String, promptText: String, categoryIcon: String, categoryColor: String)] = []
        for list in lists {
            for idea in list.ideas {
                let trimmed = idea.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                let key = "\(list.id.uuidString):\(trimmed)"
                if starredKeys.contains(key) {
                    results.append((
                        key: key,
                        ideaText: trimmed,
                        promptText: list.prompt.formattedTitle,
                        categoryIcon: list.prompt.flexibleCategory.icon,
                        categoryColor: list.prompt.flexibleCategory.color
                    ))
                }
            }
        }
        return results
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

    @ViewBuilder
    private var achievementBadgesSection: some View {
        let earned = streakManager.earnedAchievements
        if !earned.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Achievements")
                    .font(.headline)

                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 60), spacing: 8)
                ], spacing: 8) {
                    ForEach(StreakManager.allAchievements, id: \.id) { achievement in
                        let isEarned = earned.contains(achievement.id)
                        VStack(spacing: 4) {
                            Image(systemName: achievement.icon)
                                .font(.title2)
                                .foregroundColor(isEarned ? .orange : .gray.opacity(0.3))

                            Text(achievement.name)
                                .font(.system(size: 9))
                                .foregroundColor(isEarned ? .primary : .secondary.opacity(0.4))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(minWidth: 60, minHeight: 70)
                        .accessibilityLabel(isEarned ? "\(achievement.name) earned" : "\(achievement.name) locked: \(achievement.requirement)")
                    }
                }
            }
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
                        loadState: storeManager.productLoadState,
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
                        },
                        onRetry: {
                            Task {
                                await storeManager.loadProducts()
                            }
                        }
                    )
                }

                RestorePurchasesButton()
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
    let loadState: ProductLoadState
    let onPurchase: () -> Void
    let onRetry: () -> Void

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
                        PurchaseButton(price: price, loadState: loadState, action: onPurchase, onRetry: onRetry)
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
