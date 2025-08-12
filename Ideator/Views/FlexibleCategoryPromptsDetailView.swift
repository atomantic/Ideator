import SwiftUI

struct FlexibleCategoryPromptsDetailView: View {
    let category: FlexibleCategory
    let promptViewModel: PromptViewModel
    @State private var showOnlyUnused = false
    
    var body: some View {
        List {
            Section {
                Toggle("Show only unused", isOn: $showOnlyUnused)
                    .tint(category.colorValue)
                
                HStack {
                    Text("Status")
                    Spacer()
                    let unused = promptViewModel.getUnusedPromptsCount(for: category)
                    let total = promptViewModel.getPrompts(for: category).count
                    let used = total - unused
                    Text("\(used) used • \(unused) remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Prompts") {
                ForEach(filteredPrompts) { prompt in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prompt.formattedTitle)
                                .font(.subheadline)
                                .foregroundColor(isPromptUsed(prompt) ? .secondary : .primary)
                            
                            if isPromptUsed(prompt) {
                                Label("Used", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                        
                        if !isPromptUsed(prompt) {
                            Image(systemName: "circle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Image(systemName: category.icon)
                    .foregroundColor(category.colorValue)
            }
        }
    }
    
    private var filteredPrompts: [Prompt] {
        let allPrompts = promptViewModel.getPrompts(for: category)
        
        if showOnlyUnused {
            return allPrompts.filter { !isPromptUsed($0) }
        } else {
            // Sort to show unused first, then used
            return allPrompts.sorted { !isPromptUsed($0) && isPromptUsed($1) }
        }
    }
    
    private func isPromptUsed(_ prompt: Prompt) -> Bool {
        promptViewModel.isPromptUsed(prompt)
    }
}