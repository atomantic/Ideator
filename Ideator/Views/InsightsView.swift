import SwiftUI

struct InsightsView: View {
    @State private var completedLists: [IdeaList] = []
    @State private var streakManager = StreakManager.shared

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                if completedLists.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 24) {
                        summaryCardsSection
                        activityHeatmapSection
                        weeklyTrendSection
                        topCategoriesSection
                        bestDaySection
                    }
                    .padding()
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { loadData() }
        }
    }

    private func loadData() {
        completedLists = PersistenceManager.shared.loadCompleted()
            .filter { $0.isComplete }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.3))
                .accessibilityHidden(true)

            Text("No insights yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Complete some idea lists to see your creative patterns here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 120)
    }

    // MARK: - Summary Cards

    private var summaryCardsSection: some View {
        let totalIdeas = completedLists.reduce(0) { $0 + $1.ideas.filter { !$0.isEmpty }.count }
        let avgPerList = completedLists.isEmpty ? 0.0 : Double(totalIdeas) / Double(completedLists.count)
        let starredCount = PersistenceManager.shared.loadStarredIdeaKeys().count
        let draftCount = PersistenceManager.shared.loadDrafts().count
        let completionRate = (completedLists.count + draftCount) > 0
            ? Double(completedLists.count) / Double(completedLists.count + draftCount) * 100
            : 0.0

        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            StatCard(
                icon: "lightbulb.fill",
                iconColor: .yellow,
                value: "\(totalIdeas)",
                label: "Total Ideas"
            )
            StatCard(
                icon: "list.bullet.rectangle.fill",
                iconColor: .blue,
                value: "\(completedLists.count)",
                label: "Lists Completed"
            )
            StatCard(
                icon: "divide",
                iconColor: .purple,
                value: String(format: "%.1f", avgPerList),
                label: "Avg Ideas / List"
            )
            StatCard(
                icon: "star.fill",
                iconColor: .orange,
                value: starredCount > 0 ? "\(starredCount)" : (completionRate > 0 ? "\(Int(completionRate))%" : "-"),
                label: starredCount > 0 ? "Best Ideas" : "Completion Rate"
            )
        }
    }

    // MARK: - Activity Heatmap

    private var activityHeatmapSection: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        // Sunday = 1, so days since last Sunday (our column start)
        let daysSinceSunday = weekday - 1
        // 12 full weeks + partial current week
        let totalDays = 12 * 7 + daysSinceSunday + 1
        let startDate = calendar.date(byAdding: .day, value: -(totalDays - 1), to: today) ?? today

        // Build counts by day
        var countsByDay: [Date: Int] = [:]
        for list in completedLists {
            let day = calendar.startOfDay(for: list.modifiedDate)
            countsByDay[day, default: 0] += 1
        }

        let maxCount = countsByDay.values.max() ?? 1
        let weekLabels = ["S", "M", "T", "W", "T", "F", "S"]

        return VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.headline)

            HStack(alignment: .top, spacing: 2) {
                // Day-of-week labels
                VStack(spacing: 2) {
                    ForEach(0..<7, id: \.self) { row in
                        Text(weekLabels[row])
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .frame(width: 14, height: 14)
                    }
                }

                // Grid of weeks
                let weeks = (totalDays + 6) / 7
                HStack(spacing: 2) {
                    ForEach(0..<weeks, id: \.self) { week in
                        VStack(spacing: 2) {
                            ForEach(0..<7, id: \.self) { day in
                                let dayOffset = week * 7 + day
                                if dayOffset < totalDays,
                                   let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                                    let count = countsByDay[date] ?? 0
                                    let isFuture = date > today
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(isFuture ? Color.clear : heatmapColor(count: count, max: maxCount))
                                        .frame(width: 14, height: 14)
                                        .overlay(
                                            isFuture ? RoundedRectangle(cornerRadius: 2).stroke(Color.clear) : nil
                                        )
                                        .accessibilityLabel(count > 0 ? "\(date.formatted(.dateTime.month().day())): \(count) lists" : "")
                                } else {
                                    Color.clear.frame(width: 14, height: 14)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                ForEach(0..<5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatmapColorForLevel(level))
                        .frame(width: 12, height: 12)
                }

                Text("More")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    private func heatmapColor(count: Int, max: Int) -> Color {
        guard count > 0 else { return Color(UIColor.tertiarySystemFill) }
        let ratio = Double(count) / Double(max)
        let level: Int
        if ratio <= 0.25 { level = 1 }
        else if ratio <= 0.5 { level = 2 }
        else if ratio <= 0.75 { level = 3 }
        else { level = 4 }
        return heatmapColorForLevel(level)
    }

    private func heatmapColorForLevel(_ level: Int) -> Color {
        switch level {
        case 0: return Color(UIColor.tertiarySystemFill)
        case 1: return .green.opacity(0.3)
        case 2: return .green.opacity(0.5)
        case 3: return .green.opacity(0.7)
        default: return .green.opacity(0.9)
        }
    }

    // MARK: - Weekly Trend

    private var weeklyTrendSection: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weeks = 8
        var weeklyData: [(label: String, count: Int)] = []

        for i in (0..<weeks).reversed() {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: today)
                .flatMap { calendar.dateInterval(of: .weekOfYear, for: $0)?.start } ?? today
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? today

            let count = completedLists.filter { list in
                let day = calendar.startOfDay(for: list.modifiedDate)
                return day >= weekStart && day < weekEnd
            }.count

            let monthDay = calendar.component(.day, from: weekStart)
            let month = calendar.shortMonthSymbols[calendar.component(.month, from: weekStart) - 1]
            weeklyData.append((label: "\(month) \(monthDay)", count: count))
        }

        let maxWeekly = weeklyData.map(\.count).max() ?? 1

        return VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Trend")
                .font(.headline)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { _, week in
                    VStack(spacing: 4) {
                        Text("\(week.count)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.6), .blue],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(
                                height: max(4, CGFloat(week.count) / CGFloat(maxWeekly) * 100)
                            )

                        Text(week.label)
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    // MARK: - Top Categories

    private var topCategoriesSection: some View {
        var categoryCounts: [String: (count: Int, icon: String, color: String)] = [:]
        for list in completedLists {
            let cat = list.prompt.flexibleCategory
            let entry = categoryCounts[cat.name] ?? (count: 0, icon: cat.icon, color: cat.color)
            categoryCounts[cat.name] = (count: entry.count + 1, icon: entry.icon, color: entry.color)
        }

        let sorted = categoryCounts.sorted { $0.value.count > $1.value.count }
        let topCategories = Array(sorted.prefix(6))
        let maxCatCount = topCategories.first?.value.count ?? 1

        return VStack(alignment: .leading, spacing: 12) {
            Text("Top Categories")
                .font(.headline)

            ForEach(topCategories, id: \.key) { name, data in
                HStack(spacing: 10) {
                    Image(systemName: data.icon)
                        .foregroundColor(Color.from(name: data.color))
                        .frame(width: 24)

                    Text(name)
                        .font(.subheadline)
                        .frame(width: 100, alignment: .leading)
                        .lineLimit(1)

                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.from(name: data.color).opacity(0.6))
                            .frame(width: max(4, geo.size.width * CGFloat(data.count) / CGFloat(maxCatCount)))
                    }
                    .frame(height: 16)

                    Text("\(data.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    // MARK: - Best Day

    private var bestDaySection: some View {
        let calendar = Calendar.current
        let dayNames = calendar.shortWeekdaySymbols
        var dayCounts = [Int](repeating: 0, count: 7)

        for list in completedLists {
            let weekday = calendar.component(.weekday, from: list.modifiedDate) - 1
            dayCounts[weekday] += 1
        }

        let maxDay = dayCounts.max() ?? 1
        let bestDayIndex = dayCounts.firstIndex(of: maxDay) ?? 0

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Most Productive Day")
                    .font(.headline)

                Spacer()

                Text(dayNames[bestDayIndex])
                    .font(.headline)
                    .foregroundColor(.orange)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(day == bestDayIndex ? Color.orange : Color.blue.opacity(0.5))
                            .frame(height: max(4, CGFloat(dayCounts[day]) / CGFloat(maxDay) * 60))

                        Text(dayNames[day])
                            .font(.caption2)
                            .foregroundColor(day == bestDayIndex ? .orange : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .accessibilityHidden(true)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
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
