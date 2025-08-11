import SwiftUI

struct HomeView: View {
    let promptViewModel: PromptViewModel
    let ideaListViewModel: IdeaListViewModel
    @Binding var showingPromptSelection: Bool
    @Binding var showingIdeaInput: Bool
    
    @State private var animateGradient = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    
                    quickStartSection
                    
                    statsSection
                    
                    recentCategoriesSection
                }
                .padding()
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
            
            Text("Ready to weave ideas?")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Choose a prompt and start ideating")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
    
    private var quickStartSection: some View {
        VStack(spacing: 16) {
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
                        Text("Random Prompt")
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
                promptViewModel.selectCategory(nil) // Clear category to show All
                showingPromptSelection = true
            }) {
                HStack {
                    Image(systemName: "list.bullet.rectangle.fill")
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("Browse Prompts")
                            .font(.headline)
                        Text("Explore all categories and prompts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Drafts",
                value: "\(PersistenceManager.shared.loadDrafts().count)",
                icon: "doc.text",
                color: .orange
            )
            
            StatCard(
                title: "Completed",
                value: "\(PersistenceManager.shared.loadCompleted().count)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatCard(
                title: "Ideas",
                value: "\(totalIdeasCount)",
                icon: "lightbulb.fill",
                color: .blue
            )
        }
    }
    
    private var recentCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(Category.allCases.prefix(6)), id: \.self) { category in
                    CategoryCard(
                        category: category,
                        count: promptViewModel.getUnusedPromptsCount(for: category)
                    ) {
                        promptViewModel.selectCategory(category)
                        showingPromptSelection = true
                    }
                }
            }
        }
    }
    
    private var totalIdeasCount: Int {
        let drafts = PersistenceManager.shared.loadDrafts()
        let completed = PersistenceManager.shared.loadCompleted()
        
        let draftIdeas = drafts.reduce(0) { $0 + $1.ideas.filter { !$0.isEmpty }.count }
        let completedIdeas = completed.reduce(0) { $0 + $1.ideas.filter { !$0.isEmpty }.count }
        
        return draftIdeas + completedIdeas
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
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
