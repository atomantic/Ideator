import SwiftUI

struct DraftsView: View {
    let ideaListViewModel: IdeaListViewModel
    @State private var drafts: [IdeaList] = []
    @State private var showingIdeaInput = false
    @State private var selectedDraft: IdeaList?
    
    var body: some View {
        NavigationStack {
            Group {
                if drafts.isEmpty {
                    emptyStateView
                } else {
                    draftsList
                }
            }
            .navigationTitle("Drafts")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadDrafts()
            }
            .sheet(item: $selectedDraft) { draft in
                NavigationStack {
                    IdeaInputView(viewModel: ideaListViewModel, promptViewModel: nil)
                        .onAppear {
                            ideaListViewModel.startNewList(with: draft.prompt)
                        }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Drafts Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your unfinished idea lists will appear here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var draftsList: some View {
        List {
            ForEach(drafts) { draft in
                DraftRow(draft: draft) {
                    selectedDraft = draft
                }
            }
            .onDelete(perform: deleteDrafts)
        }
        .listStyle(PlainListStyle())
    }
    
    private func loadDrafts() {
        drafts = PersistenceManager.shared.loadDrafts()
            .sorted { $0.modifiedDate > $1.modifiedDate }
    }
    
    private func deleteDrafts(at offsets: IndexSet) {
        for index in offsets {
            PersistenceManager.shared.deleteDraft(withId: drafts[index].id)
        }
        drafts.remove(atOffsets: offsets)
    }
}

struct DraftRow: View {
    let draft: IdeaList
    let onTap: () -> Void
    
    private var filledIdeasCount: Int {
        draft.ideas.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: draft.prompt.category.icon)
                        .foregroundColor(draft.prompt.category.colorValue)
                        .font(.title3)
                    
                    Text(draft.prompt.formattedTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                HStack {
                    ProgressView(value: draft.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 80)
                    
                    Text("\(filledIdeasCount)/\(draft.prompt.suggestedCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(draft.modifiedDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if filledIdeasCount > 0, let firstIdea = draft.ideas.first(where: { !$0.isEmpty }) {
                    Text(firstIdea)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}