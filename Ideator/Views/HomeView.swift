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
    }
    
    
    private var recentCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            let groupedCategories = promptViewModel.getCategoriesGroupedByPack()
            
            ForEach(Array(groupedCategories.enumerated()), id: \.offset) { index, group in
                VStack(alignment: .leading, spacing: 12) {
                    if let packName = group.packName {
                        // Show pack name for non-core packs
                        Text(packName)
                            .font(.headline)
                            .padding(.top, index > 0 ? 8 : 0)
                    } else if index == 0 && groupedCategories.count > 1 {
                        // Only show "Core" label if there are other packs
                        Text("Core")
                            .font(.headline)
                    }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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

struct FlexibleCategoryCard: View {
    let category: FlexibleCategory
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(category.colorValue)
                
                Text(category.name)
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
