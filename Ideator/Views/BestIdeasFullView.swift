import SwiftUI

struct BestIdeasFullView: View {
    @State private var starredKeys = PersistenceManager.shared.loadStarredIdeaKeys()

    var body: some View {
        let completedLists = PersistenceManager.shared.loadCompleted()
        let bestIdeas = collectBestIdeas(from: completedLists)

        Group {
            if bestIdeas.isEmpty {
                ContentUnavailableView(
                    "No Best Ideas Yet",
                    systemImage: "star",
                    description: Text("Star your favorite ideas in History to collect them here.")
                )
            } else {
                List {
                    ForEach(bestIdeas, id: \.key) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.categoryIcon)
                                .font(.body)
                                .foregroundColor(Color.from(name: item.categoryColor))
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.ideaText)
                                    .font(.body)

                                Text(item.promptText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Button {
                                unstar(key: item.key)
                            } label: {
                                Image(systemName: "star.fill")
                                    .font(.body)
                                    .foregroundColor(.yellow)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel("Remove from Best Ideas")
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Best Ideas")
        .navigationBarTitleDisplayMode(.large)
    }

    private func collectBestIdeas(
        from lists: [IdeaList]
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

    private func unstar(key: String) {
        starredKeys.remove(key)
        PersistenceManager.shared.saveStarredIdeaKeys(starredKeys)
    }
}
