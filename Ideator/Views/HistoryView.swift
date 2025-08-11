import SwiftUI

struct HistoryView: View {
    @State private var completedLists: [IdeaList] = []
    @State private var selectedList: IdeaList?
    @State private var searchText = ""
    @State private var selectedCategory: Category?
    
    var filteredLists: [IdeaList] {
        var lists = completedLists
        
        if let category = selectedCategory {
            lists = lists.filter { $0.prompt.category == category }
        }
        
        if !searchText.isEmpty {
            lists = lists.filter { list in
                list.prompt.text.localizedCaseInsensitiveContains(searchText) ||
                list.ideas.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return lists
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if completedLists.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 0) {
                        if !completedLists.isEmpty {
                            categoryFilter
                        }
                        
                        List {
                            ForEach(filteredLists) { list in
                                HistoryRow(ideaList: list) {
                                    selectedList = list
                                }
                            }
                            .onDelete(perform: deleteLists)
                        }
                        .listStyle(PlainListStyle())
                        .searchable(text: $searchText, prompt: "Search ideas...")
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadHistory()
            }
            .sheet(item: $selectedList) { list in
                IdeaListDetailView(ideaList: list)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Completed Lists")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your completed idea lists will appear here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                ForEach(Category.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func loadHistory() {
        completedLists = PersistenceManager.shared.loadCompleted()
            .sorted { $0.createdDate > $1.createdDate }
    }
    
    private func deleteLists(at offsets: IndexSet) {
        for index in offsets {
            PersistenceManager.shared.deleteCompleted(withId: filteredLists[index].id)
        }
        loadHistory()
    }
}

struct HistoryRow: View {
    let ideaList: IdeaList
    let onTap: () -> Void
    
    private var filledIdeas: [String] {
        ideaList.ideas.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: ideaList.prompt.category.icon)
                        .foregroundColor(ideaList.prompt.category.colorValue)
                        .font(.title3)
                    
                    Text(ideaList.prompt.formattedTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                Text(ideaList.createdDate.formatted(date: .long, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if filledIdeas.count > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(filledIdeas.prefix(3).enumerated()), id: \.offset) { index, idea in
                            HStack(alignment: .top, spacing: 4) {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 20, alignment: .trailing)
                                
                                Text(idea)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        if filledIdeas.count > 3 {
                            Text("+ \(filledIdeas.count - 3) more...")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(UIColor.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct IdeaListDetailView: View {
    let ideaList: IdeaList
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection
                    
                    Divider()
                    
                    ideasSection
                }
                .padding()
            }
            .navigationTitle("Idea List Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                ShareSheet(activityItems: [ideaList.formattedForExport])
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: ideaList.prompt.category.icon)
                    .foregroundColor(ideaList.prompt.category.colorValue)
                    .font(.title)
                
                Text(ideaList.prompt.formattedTitle)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Label(ideaList.prompt.category.rawValue, systemImage: "tag.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Label(
                ideaList.createdDate.formatted(date: .long, time: .shortened),
                systemImage: "calendar"
            )
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private var ideasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ideas")
                .font(.headline)
            
            ForEach(Array(ideaList.ideas.enumerated()), id: \.offset) { index, idea in
                if !idea.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .trailing)
                        
                        Text(idea)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}