import SwiftUI

struct IdeaListDetailView: View {
    let onUpdate: (IdeaList) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var editableList: IdeaList
    @State private var lastSavedList: IdeaList
    @State private var showingShareSheet = false
    @State private var isEditing = false
    @State private var editMode: EditMode = .inactive
    @State private var ideaIdentifiers: [UUID] = []

    init(ideaList: IdeaList, onUpdate: @escaping (IdeaList) -> Void = { _ in }) {
        self.onUpdate = onUpdate
        _editableList = State(initialValue: ideaList)
        _lastSavedList = State(initialValue: ideaList)
        _ideaIdentifiers = State(initialValue: ideaList.ideas.map { _ in UUID() })
    }

    var body: some View {
        NavigationStack {
            Group {
                if isEditing {
                    editingContent
                } else {
                    readOnlyContent
                }
            }
            .navigationTitle("Idea List Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            cancelEditing()
                        }
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                        }
                        .disabled(!hasChanges)
                    } else {
                        Button {
                            showingShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }

                        Button {
                            startEditing()
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let _ = windowScene.windows.first?.rootViewController {
                ShareSheet(activityItems: [editableList.formattedForExport])
            }
        }
        .onChange(of: isEditing) { editing in
            withAnimation {
                editMode = editing ? .active : .inactive
            }
        }
    }

    private var readOnlyContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection

                Divider()

                ideasDisplaySection
            }
            .padding()
        }
    }

    private var editingContent: some View {
        List {
            Section {
                headerSection
            }

            Section(header: Text("Ideas")) {
                ForEach(Array(zip(ideaIdentifiers.indices, ideaIdentifiers)), id: \.1) { index, _ in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(width: 28, alignment: .trailing)

                        TextField("Idea \(index + 1)", text: bindingForIdea(at: index), axis: .vertical)
                            .lineLimit(1...4)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, 4)
                }
                .onMove(perform: moveIdeas)
                .onDelete(perform: deleteIdeas)

                Button(action: addNewIdea) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                        Text("Add Idea")
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, $editMode)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: editableList.prompt.flexibleCategory.icon)
                    .foregroundColor(editableList.prompt.flexibleCategory.colorValue)
                    .font(.title)

                Text(editableList.prompt.formattedTitle)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Label(editableList.prompt.flexibleCategory.name, systemImage: "tag.fill")
                .font(.caption)
                .foregroundColor(.secondary)

            Label(
                editableList.createdDate.formatted(date: .long, time: .shortened),
                systemImage: "calendar"
            )
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private var ideasDisplaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ideas")
                .font(.headline)

            ForEach(Array(editableList.ideas.enumerated()), id: \.offset) { index, idea in
                let trimmed = idea.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .trailing)

                        Text(trimmed)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        ShareLink(item: trimmed) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var hasChanges: Bool {
        editableList.ideas != lastSavedList.ideas
    }

    private func bindingForIdea(at index: Int) -> Binding<String> {
        Binding(
            get: {
                guard editableList.ideas.indices.contains(index) else { return "" }
                return editableList.ideas[index]
            },
            set: { newValue in
                guard editableList.ideas.indices.contains(index) else { return }
                editableList.ideas[index] = newValue
            }
        )
    }

    private func moveIdeas(from offsets: IndexSet, to destination: Int) {
        editableList.ideas.move(fromOffsets: offsets, toOffset: destination)
        ideaIdentifiers.move(fromOffsets: offsets, toOffset: destination)
    }

    private func deleteIdeas(at offsets: IndexSet) {
        editableList.ideas.remove(atOffsets: offsets)
        ideaIdentifiers.remove(atOffsets: offsets)
    }

    private func addNewIdea() {
        editableList.ideas.append("")
        ideaIdentifiers.append(UUID())
    }

    private func startEditing() {
        lastSavedList = editableList
        ideaIdentifiers = editableList.ideas.map { _ in UUID() }
        isEditing = true
    }

    private func cancelEditing() {
        editableList = lastSavedList
        ideaIdentifiers = editableList.ideas.map { _ in UUID() }
        isEditing = false
    }

    private func saveChanges() {
        var updatedList = editableList
        updatedList.ideas = updatedList.ideas.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        updatedList.modifiedDate = Date()
        updatedList.isComplete = true

        editableList = updatedList
        lastSavedList = updatedList

        PersistenceManager.shared.saveCompleted(updatedList)
        onUpdate(updatedList)

        isEditing = false
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
