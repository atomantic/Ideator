import SwiftUI

struct PromptSelectionView: View {
    let promptViewModel: PromptViewModel
    let ideaListViewModel: IdeaListViewModel
    @Binding var showingIdeaInput: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: Category?
    @State private var selectedFlexibleCategory: FlexibleCategory?
    @State private var searchText = ""
    @State private var showingCustomPrompt = false
    
    init(promptViewModel: PromptViewModel, ideaListViewModel: IdeaListViewModel, showingIdeaInput: Binding<Bool>) {
        self.promptViewModel = promptViewModel
        self.ideaListViewModel = ideaListViewModel
        self._showingIdeaInput = showingIdeaInput
        // Initialize selectedCategory from promptViewModel
        self._selectedCategory = State(initialValue: promptViewModel.selectedCategory)
        self._selectedFlexibleCategory = State(initialValue: promptViewModel.selectedFlexibleCategory)
    }
    
    var filteredPrompts: [Prompt] {
        let prompts: [Prompt]
        if let flexCategory = selectedFlexibleCategory {
            prompts = promptViewModel.getPrompts(for: flexCategory)
        } else if let category = selectedCategory {
            prompts = promptViewModel.getPromptsForCategory(category)
        } else {
            prompts = promptViewModel.prompts
        }
        
        if searchText.isEmpty {
            return prompts
        } else {
            return prompts.filter { 
                $0.text.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func isCustomPrompt(_ prompt: Prompt) -> Bool {
        let customPrompts = PersistenceManager.shared.loadCustomPrompts()
        return customPrompts.contains(where: { $0.id == prompt.id })
    }
    
    var body: some View {
        NavigationStack {
            List {
                if selectedFlexibleCategory != nil || searchText.isEmpty == false {
                    // Single category or search results - no sections needed
                    ForEach(filteredPrompts) { prompt in
                        PromptRow(
                            prompt: prompt,
                            isUsed: promptViewModel.isPromptUsed(prompt),
                            isCustom: isCustomPrompt(prompt)
                        ) {
                            selectPrompt(prompt)
                        }
                    }
                } else {
                    // All categories - group by pack/category
                    let groupedPrompts = Dictionary(grouping: filteredPrompts) { prompt in
                        "\(prompt.flexibleCategory.packName ?? "Core")|\(prompt.flexibleCategory.name)"
                    }
                    let sortedGroups = groupedPrompts.keys.sorted()
                    
                    ForEach(sortedGroups, id: \.self) { groupKey in
                        let components = groupKey.split(separator: "|").map(String.init)
                        let packName = components[0]
                        let categoryName = components[1]
                        
                        Section(header: HStack {
                            Text(packName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("›")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.5))
                            Text(categoryName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }) {
                            ForEach(groupedPrompts[groupKey] ?? []) { prompt in
                                PromptRow(
                                    prompt: prompt,
                                    isUsed: promptViewModel.isPromptUsed(prompt),
                                    isCustom: isCustomPrompt(prompt)
                                ) {
                                    selectPrompt(prompt)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search prompts...")
            .listStyle(PlainListStyle())
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingCustomPrompt = true }) {
                            Label("Create Custom Prompt", systemImage: "plus.circle.fill")
                        }
                        
                        Button(action: selectRandomPrompt) {
                            Label("Random from All", systemImage: "dice.fill")
                        }
                        
                        Divider()
                        
                        // All categories option
                        Button(action: {
                            selectedCategory = nil
                            selectedFlexibleCategory = nil
                            promptViewModel.selectCategory(nil)
                        }) {
                            Label("All Categories", systemImage: "square.grid.2x2")
                        }
                        
                        Divider()
                        
                        // Group categories by pack
                        let groupedCategories = promptViewModel.getCategoriesGroupedByPack()
                        ForEach(Array(groupedCategories.enumerated()), id: \.offset) { _, group in
                            Section(group.packName ?? "Core") {
                                ForEach(group.categories, id: \.id) { flexCategory in
                                    Button(action: {
                                        selectedFlexibleCategory = flexCategory
                                        selectedCategory = flexCategory.toCategory()
                                        promptViewModel.selectFlexibleCategory(flexCategory)
                                    }) {
                                        Label(flexCategory.name, systemImage: flexCategory.icon)
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showingCustomPrompt) {
                CustomPromptView(
                    ideaListViewModel: ideaListViewModel,
                    showingIdeaInput: $showingIdeaInput
                )
            }
        }
    }
    
    private var navigationTitle: String {
        if let flexCategory = selectedFlexibleCategory {
            return flexCategory.name
        } else if searchText.isEmpty {
            return "All Prompts"
        } else {
            return "Search Results"
        }
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
    let isUsed: Bool
    let isCustom: Bool
    let onSelect: () -> Void
    
    init(prompt: Prompt, isUsed: Bool, isCustom: Bool = false, onSelect: @escaping () -> Void) {
        self.prompt = prompt
        self.isUsed = isUsed
        self.isCustom = isCustom
        self.onSelect = onSelect
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: prompt.flexibleCategory.icon)
                    .foregroundColor(isUsed ? prompt.flexibleCategory.colorValue.opacity(0.5) : prompt.flexibleCategory.colorValue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(prompt.formattedTitle)
                            .font(.body)
                            .foregroundColor(isUsed ? .secondary : .primary)
                            .multilineTextAlignment(.leading)
                            .strikethrough(isUsed, color: .secondary.opacity(0.5))
                        
                        if isCustom {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        if isUsed {
                            Label("Used", systemImage: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green.opacity(0.7))
                        }
                        
                        if isCustom {
                            Text("Custom")
                                .font(.caption2)
                                .foregroundColor(.purple.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color.secondary.opacity(0.5))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

