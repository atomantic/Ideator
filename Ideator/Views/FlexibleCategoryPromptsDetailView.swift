import SwiftUI

struct FlexibleCategoryPromptsDetailView: View {
    let category: FlexibleCategory
    let promptViewModel: PromptViewModel
    @State private var showOnlyUnused = false
    @State private var refreshID = UUID()
    
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
            .id(refreshID)
            
            Section("Prompts") {
                ForEach(filteredPrompts) { prompt in
                    Button(action: {
                        togglePromptUsedStatus(prompt)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(prompt.formattedTitle)
                                    .font(.subheadline)
                                    .foregroundColor(isPromptUsed(prompt) ? .secondary : .primary)
                                
                                if isPromptUsed(prompt) {
                                    Label("Used", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                } else {
                                    Text("Tap to mark as used")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: isPromptUsed(prompt) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(isPromptUsed(prompt) ? .green : .secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
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
    
    private func togglePromptUsedStatus(_ prompt: Prompt) {
        if isPromptUsed(prompt) {
            promptViewModel.unmarkPromptAsUsed(prompt)
        } else {
            promptViewModel.markPromptAsUsed(prompt)
        }
        // Force view refresh
        refreshID = UUID()
    }
}
