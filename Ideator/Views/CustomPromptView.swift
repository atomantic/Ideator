import SwiftUI

struct CustomPromptView: View {
    @Environment(\.dismiss) private var dismiss
    let ideaListViewModel: IdeaListViewModel
    @Binding var showingIdeaInput: Bool
    
    @State private var promptText = ""
    @State private var selectedCategory = FlexibleCategory.from(category: .custom)
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section {
                        TextField("Enter your custom prompt...", text: $promptText, axis: .vertical)
                            .lineLimit(3...6)
                            .focused($isTextFieldFocused)
                    } header: {
                        Text("Your Prompt")
                    } footer: {
                        Text("Create your own prompt to generate ideas. Be creative!")
                    }
                    
                    Section("Category") {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(getAllCategories(), id: \.id) { category in
                                Label(category.name, systemImage: category.icon)
                                    .tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                VStack(spacing: 12) {
                    Button(action: startCustomPrompt) {
                        Text("Start This Prompt")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationTitle("Custom Prompt")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func getAllCategories() -> [FlexibleCategory] {
        var categories: [FlexibleCategory] = []
        var addedIds = Set<String>()
        
        // Add Custom category first
        let customCategory = FlexibleCategory.from(category: .custom)
        categories.append(customCategory)
        addedIds.insert(customCategory.id)
        
        // Get all categories from installed packs (including Core)
        let packManager = PackManager.shared
        for pack in packManager.installedPacks where pack.isEnabled {
            for category in pack.categories {
                if !addedIds.contains(category.id) {
                    categories.append(FlexibleCategory(
                        id: category.id,
                        name: category.name,
                        icon: category.icon,
                        color: category.color,
                        packId: pack.id,
                        packName: pack.id == "core" ? nil : pack.name
                    ))
                    addedIds.insert(category.id)
                }
            }
        }
        
        // Sort all except Custom (which stays first)
        let customFirst = categories.first!
        let rest = Array(categories.dropFirst()).sorted { $0.name < $1.name }
        return [customFirst] + rest
    }
    
    private func startCustomPrompt() {
        let trimmedText = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Get the default list size from user settings
        let defaultListSize = UserDefaults.standard.integer(forKey: "defaultListSize")
        let suggestedCount = defaultListSize > 0 ? defaultListSize : 10
        
        // Create a custom prompt
        let customPrompt = Prompt(
            text: trimmedText,
            flexibleCategory: selectedCategory,
            suggestedCount: suggestedCount
        )
        
        // Save to custom prompts
        saveCustomPrompt(customPrompt)
        
        // Start the idea list with this prompt
        ideaListViewModel.startNewList(with: customPrompt)
        
        // Dismiss this view and show idea input
        dismiss()
        showingIdeaInput = true
    }
    
    private func saveCustomPrompt(_ prompt: Prompt) {
        PersistenceManager.shared.saveCustomPrompt(prompt)
    }
    
    private func loadCustomPrompts() -> [Prompt] {
        PersistenceManager.shared.loadCustomPrompts()
    }
}