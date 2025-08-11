import SwiftUI

struct IdeaInputView: View {
    @Bindable var viewModel: IdeaListViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Int?
    @State private var showingExportSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressHeader
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            promptCard
                            
                            ForEach(0..<viewModel.ideas.count, id: \.self) { index in
                                IdeaField(
                                    index: index,
                                    text: $viewModel.ideas[index],
                                    focusedField: $focusedField,
                                    onSubmit: {
                                        if index < viewModel.ideas.count - 1 {
                                            focusedField = index + 1
                                        }
                                        viewModel.saveDraft()
                                    }
                                )
                                .id(index)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: focusedField) { _, newValue in
                        if let newValue = newValue {
                            withAnimation {
                                proxy.scrollTo(newValue, anchor: .center)
                            }
                        }
                    }
                }
                
                bottomToolbar
            }
            .navigationTitle("Add Your Ideas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Save Draft") {
                        viewModel.saveDraft()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        completeList()
                    }
                    .fontWeight(.bold)
                    .disabled(viewModel.getProgress() < 1.0)
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            if let ideaList = viewModel.currentIdeaList {
                ExportView(ideaList: ideaList) {
                    dismiss()
                }
            }
        }
        .onAppear {
            focusedField = viewModel.ideas.firstIndex(where: { $0.isEmpty }) ?? 0
        }
    }
    
    private var progressHeader: some View {
        VStack(spacing: 8) {
            ProgressView(value: viewModel.getProgress())
                .progressViewStyle(LinearProgressViewStyle())
                .tint(viewModel.getProgress() >= 1.0 ? .green : .blue)
            
            Text("\(Int(viewModel.getProgress() * 100))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let prompt = viewModel.currentIdeaList?.prompt {
                HStack {
                    Image(systemName: prompt.category.icon)
                        .foregroundColor(prompt.category.colorValue)
                        .font(.title2)
                    
                    Text(prompt.formattedTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Label(prompt.category.rawValue, systemImage: "tag.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var bottomToolbar: some View {
        HStack(spacing: 16) {
            Button(action: {
                if let current = focusedField, current > 0 {
                    focusedField = current - 1
                }
            }) {
                Image(systemName: "chevron.up")
                    .font(.title3)
            }
            .disabled(focusedField == nil || focusedField == 0)
            
            Button(action: {
                if let current = focusedField, current < viewModel.ideas.count - 1 {
                    focusedField = current + 1
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.title3)
            }
            .disabled(focusedField == nil || focusedField == viewModel.ideas.count - 1)
            
            Spacer()
            
            Button(action: {
                focusedField = nil
            }) {
                Text("Done")
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func completeList() {
        viewModel.markAsComplete()
        showingExportSheet = true
    }
}

struct IdeaField: View {
    let index: Int
    @Binding var text: String
    @FocusState.Binding var focusedField: Int?
    let onSubmit: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index + 1).")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
                .padding(.top, 8)
            
            TextField("Enter your idea...", text: $text, axis: .vertical)
                .font(.body)
                .focused($focusedField, equals: index)
                .onSubmit(onSubmit)
                .submitLabel(.next)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(12)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            focusedField == index ? Color.blue : Color(UIColor.separator),
                            lineWidth: focusedField == index ? 2 : 1
                        )
                )
        }
    }
}

struct ExportView: View {
    let ideaList: IdeaList
    let onComplete: () -> Void
    @State private var exportFormat = "text"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .symbolEffect(.bounce)
                
                Text("List Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Great job! You've completed your idea list.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Picker("Export Format", selection: $exportFormat) {
                    Text("Plain Text").tag("text")
                    Text("Markdown").tag("markdown")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                Button(action: {
                    exportToNotes()
                }) {
                    Label("Export to Notes", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Button("Done") {
                    onComplete()
                }
                .font(.headline)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Success!")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func exportToNotes() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        ExportManager.shared.exportToNotes(ideaList, from: rootViewController)
    }
}