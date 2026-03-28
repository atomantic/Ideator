import SwiftUI
import WidgetKit

// MARK: - Timeline Entry

struct IdeaLoomEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let completedToday: Bool
    let totalCompleted: Int
    let promptText: String?
    let promptCategory: String?
    let promptCategoryIcon: String?
}

// MARK: - Timeline Provider

struct IdeaLoomProvider: TimelineProvider {
    func placeholder(in context: Context) -> IdeaLoomEntry {
        IdeaLoomEntry(
            date: Date(),
            streak: 5,
            completedToday: false,
            totalCompleted: 42,
            promptText: "app ideas to build",
            promptCategory: "Creative",
            promptCategoryIcon: "paintbrush.fill"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (IdeaLoomEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<IdeaLoomEntry>) -> Void) {
        let entry = currentEntry()
        // Refresh at midnight so the prompt and streak status update daily
        let tomorrow = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    private func currentEntry() -> IdeaLoomEntry {
        IdeaLoomEntry(
            date: Date(),
            streak: WidgetDataStore.readStreak(),
            completedToday: WidgetDataStore.readCompletedToday(),
            totalCompleted: WidgetDataStore.readTotalCompleted(),
            promptText: WidgetDataStore.readPromptText(),
            promptCategory: WidgetDataStore.readPromptCategory(),
            promptCategoryIcon: WidgetDataStore.readPromptCategoryIcon()
        )
    }
}

// MARK: - Widget Definition

struct IdeaLoomWidget: Widget {
    let kind = "IdeaLoomWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: IdeaLoomProvider()) { entry in
            IdeaLoomWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Idea Loom")
        .description("Today's creative prompt and your streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Views

struct IdeaLoomWidgetView: View {
    let entry: IdeaLoomEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: IdeaLoomEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
                    .foregroundStyle(.yellow)
                Spacer()
                streakBadge
            }

            Spacer()

            if let prompt = entry.promptText {
                Text(prompt)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(3)
                    .foregroundStyle(.primary)
            }

            Spacer()

            statusRow
        }
        .widgetURL(URL(string: "idealoom://start"))
    }

    private var streakBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: entry.streak > 0 ? "flame.fill" : "flame")
                .font(.caption)
                .foregroundStyle(entry.streak > 0 ? .orange : .secondary)
            Text("\(entry.streak)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(entry.streak > 0 ? .orange : .secondary)
        }
    }

    private var statusRow: some View {
        HStack {
            if entry.completedToday {
                Label("Done today", systemImage: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            } else {
                Label("Tap to start", systemImage: "play.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: IdeaLoomEntry

    var body: some View {
        HStack(spacing: 12) {
            // Left: Streak info
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: entry.streak > 0 ? "flame.fill" : "flame")
                            .foregroundStyle(entry.streak > 0 ? .orange : .secondary)
                        Text("\(entry.streak)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(entry.streak > 0 ? .orange : .secondary)
                    }
                    Text("day streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text("\(entry.totalCompleted) lists")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80)

            // Divider
            Rectangle()
                .fill(.quaternary)
                .frame(width: 1)

            // Right: Prompt
            VStack(alignment: .leading, spacing: 6) {
                if let category = entry.promptCategory {
                    HStack(spacing: 4) {
                        if let icon = entry.promptCategoryIcon {
                            Image(systemName: icon)
                                .font(.caption2)
                        }
                        Text(category)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.secondary)
                }

                if let prompt = entry.promptText {
                    Text("10 \(prompt)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(3)
                        .foregroundStyle(.primary)
                } else {
                    Text("Open Idea Loom to get started")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if entry.completedToday {
                    Label("Done for today!", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Label("Tap to start ideating", systemImage: "play.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
        }
        .widgetURL(URL(string: "idealoom://start"))
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    IdeaLoomWidget()
} timeline: {
    IdeaLoomEntry(date: Date(), streak: 7, completedToday: false, totalCompleted: 42, promptText: "app ideas to build", promptCategory: "Creative", promptCategoryIcon: "paintbrush.fill")
    IdeaLoomEntry(date: Date(), streak: 7, completedToday: true, totalCompleted: 43, promptText: "app ideas to build", promptCategory: "Creative", promptCategoryIcon: "paintbrush.fill")
}

#Preview("Medium", as: .systemMedium) {
    IdeaLoomWidget()
} timeline: {
    IdeaLoomEntry(date: Date(), streak: 14, completedToday: false, totalCompleted: 42, promptText: "ways to improve my morning routine", promptCategory: "Lifestyle", promptCategoryIcon: "heart.fill")
    IdeaLoomEntry(date: Date(), streak: 14, completedToday: true, totalCompleted: 43, promptText: "ways to improve my morning routine", promptCategory: "Lifestyle", promptCategoryIcon: "heart.fill")
}
