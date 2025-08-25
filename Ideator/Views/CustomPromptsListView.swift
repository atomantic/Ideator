import SwiftUI

struct CustomPromptsListView: View {
    @State private var customPrompts: [Prompt] = []
    @State private var showingAddPrompt = false
    @State private var showingDeleteAlert = false
    @State private var promptToDelete: Prompt?
    
    var body: some View {
        List {
            if customPrompts.isEmpty {
                ContentUnavailableView(
                    "No Custom Prompts",
                    systemImage: "sparkles.slash",
                    description: Text("Tap the + button to create your first custom prompt")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(customPrompts) { prompt in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(prompt.text)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Label(prompt.flexibleCategory.name, systemImage: prompt.flexibleCategory.icon)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(prompt.suggestedCount) ideas")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            promptToDelete = prompt
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Custom Prompts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddPrompt = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            loadCustomPrompts()
        }
        .sheet(isPresented: $showingAddPrompt) {
            // We need a simple version for adding from settings
            CustomPromptAddView {
                loadCustomPrompts()
            }
        }
        .alert("Delete Custom Prompt?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let prompt = promptToDelete {
                    deletePrompt(prompt)
                }
            }
        } message: {
            Text("This prompt will be permanently removed.")
        }
    }
    
    private func loadCustomPrompts() {
        customPrompts = PersistenceManager.shared.loadCustomPrompts()
    }
    
    private func deletePrompt(_ prompt: Prompt) {
        PersistenceManager.shared.deleteCustomPrompt(withId: prompt.id)
        loadCustomPrompts()
    }
}

struct CustomPromptAddView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: () -> Void
    
    @State private var promptText = ""
    @State private var selectedCategory = FlexibleCategory.from(category: .custom)
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Enter your custom prompt...", text: $promptText, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($isTextFieldFocused)
                } header: {
                    Text("Prompt")
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
            .navigationTitle("Add Custom Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePrompt()
                    }
                    .fontWeight(.bold)
                    .disabled(promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func getAllCategories() -> [FlexibleCategory] {
        var categories: [FlexibleCategory] = []
        
        // Add Custom category first
        let customCategory = FlexibleCategory.from(category: .custom)
        categories.append(customCategory)
        
        // Add other core categories
        for category in Category.allCases {
            if category != .custom {
                categories.append(FlexibleCategory.from(category: category))
            }
        }
        
        // Add pack categories if available
        let packManager = PackManager.shared
        for pack in packManager.installedPacks {
                for category in pack.categories {
                    if !categories.contains(where: { $0.id == category.id }) {
                        categories.append(FlexibleCategory(
                            id: category.id,
                            name: category.name,
                            icon: category.icon,
                            color: category.color,
                            packId: pack.id,
                            packName: pack.name
                        ))
                    }
                }
            }
        
        // Sort all except Custom (which stays first)
        let customFirst = categories.first!
        let rest = Array(categories.dropFirst()).sorted { $0.name < $1.name }
        return [customFirst] + rest
    }
    
    private func savePrompt() {
        let trimmedText = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Get the default list size from user settings
        let defaultListSize = UserDefaults.standard.integer(forKey: "defaultListSize")
        let suggestedCount = defaultListSize > 0 ? defaultListSize : 10
        
        let customPrompt = Prompt(
            text: trimmedText,
            flexibleCategory: selectedCategory,
            suggestedCount: suggestedCount
        )
        
        PersistenceManager.shared.saveCustomPrompt(customPrompt)
        onSave()
        dismiss()
    }
}