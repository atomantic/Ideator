import SwiftUI

struct PromptSelectionView: View {
    let promptViewModel: PromptViewModel
    let ideaListViewModel: IdeaListViewModel
    @Binding var showingIdeaInput: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: Category?
    @State private var searchText = ""
    
    init(promptViewModel: PromptViewModel, ideaListViewModel: IdeaListViewModel, showingIdeaInput: Binding<Bool>) {
        self.promptViewModel = promptViewModel
        self.ideaListViewModel = ideaListViewModel
        self._showingIdeaInput = showingIdeaInput
        // Initialize selectedCategory from promptViewModel
        self._selectedCategory = State(initialValue: promptViewModel.selectedCategory)
    }
    
    var filteredPrompts: [Prompt] {
        let prompts = selectedCategory != nil 
            ? promptViewModel.getPromptsForCategory(selectedCategory!)
            : promptViewModel.prompts
        
        if searchText.isEmpty {
            return prompts
        } else {
            return prompts.filter { 
                $0.text.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryPicker
                
                List(filteredPrompts) { prompt in
                    PromptRow(prompt: prompt) {
                        selectPrompt(prompt)
                    }
                }
                .searchable(text: $searchText, prompt: "Search prompts...")
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Choose a Prompt")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Random") {
                        selectRandomPrompt()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil,
                    color: .blue
                ) {
                    selectedCategory = nil
                    promptViewModel.selectCategory(nil)
                }
                
                ForEach(Category.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category,
                        color: category.colorValue
                    ) {
                        selectedCategory = category
                        promptViewModel.selectCategory(category)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func selectPrompt(_ prompt: Prompt) {
        ideaListViewModel.startNewList(with: prompt)
        PromptService.shared.markPromptAsUsed(prompt)
        dismiss()
        showingIdeaInput = true
    }
    
    private func selectRandomPrompt() {
        if let randomPrompt = promptViewModel.getRandomPrompt() {
            selectPrompt(randomPrompt)
        }
    }
}

struct PromptRow: View {
    let prompt: Prompt
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: prompt.flexibleCategory.icon)
                        .foregroundColor(prompt.flexibleCategory.colorValue)
                        .font(.title3)
                    
                    Text(prompt.formattedTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                
                Label(prompt.flexibleCategory.name, systemImage: "tag.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color(UIColor.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}