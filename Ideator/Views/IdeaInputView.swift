import SwiftUI

struct IdeaInputView: View {
    @Bindable var viewModel: IdeaListViewModel
    let promptViewModel: PromptViewModel?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isInputFocused: Bool
    @State private var currentInput = ""
    @State private var showingExportSheet = false
    @State private var showingSkipAlert = false
    @State private var currentHelpTip = "Enter an idea..."
    @State private var helpTimerActive = false
    
    let helpTips = [
        "Get silly with it!",
        "Think outside the box",
        "Just say whatever pops into your head!",
        "No idea is too wild",
        "What would a kid suggest?",
        "Combine two unrelated things",
        "What's the opposite approach?",
        "Make it ridiculous!",
        "What if money was no object?",
        "Channel your inner genius",
        "Start with 'What if...'",
        "Be bold and brave",
        "Imagine the impossible",
        "Mix and match ideas",
        "Think big, then bigger!"
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressHeader
                
                VStack(spacing: 16) {
                    promptCard
                        .padding(.horizontal)
                    
                    // Single input field at the top
                    HStack(spacing: 12) {
                        TextField(currentHelpTip, text: $currentInput)
                            .font(.body)
                            .focused($isInputFocused)
                            .onSubmit {
                                addIdea()
                            }
                            .onChange(of: currentInput) { _, _ in
                                resetHelpTimer()
                            }
                            .onChange(of: isInputFocused) { _, focused in
                                if focused {
                                    helpTimerActive = true
                                } else {
                                    helpTimerActive = false
                                }
                            }
                            .submitLabel(.done)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(12)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        isInputFocused ? Color.blue : Color(UIColor.separator),
                                        lineWidth: isInputFocused ? 2 : 1
                                    )
                            )
                        
                        Button(action: addIdea) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal)
                    
                    // List of added ideas below
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(viewModel.ideas.enumerated().reversed()), id: \.offset) { index, idea in
                                if !idea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    IdeaRow(
                                        index: index,
                                        text: idea,
                                        onDelete: {
                                            viewModel.removeIdea(at: index)
                                        }
                                    )
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                                }
                            }
                            
                            if viewModel.ideas.filter({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }).isEmpty {
                                Text("Your ideas will appear here...")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Add Your Ideas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            viewModel.saveDraft()
                            dismiss()
                        } label: {
                            Label("Save Draft", systemImage: "doc.badge.plus")
                        }
                        
                        Button(role: .destructive) {
                            showingSkipAlert = true
                        } label: {
                            Label("Skip Prompt", systemImage: "forward.fill")
                        }
                    } label: {
                        Text("Options")
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
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Add") {
                        addIdea()
                    }
                    .fontWeight(.bold)
                    .disabled(currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            if let ideaList = viewModel.currentIdeaList {
                ExportView(ideaList: ideaList, promptViewModel: promptViewModel) {
                    dismiss()
                }
            }
        }
        .onAppear {
            isInputFocused = true
            helpTimerActive = true
        }
        .onDisappear {
            helpTimerActive = false
        }
        .task(id: helpTimerActive) {
            guard helpTimerActive else { return }
            currentHelpTip = "Enter an idea..."
            do {
                try await Task.sleep(for: .seconds(3))
                withAnimation {
                    currentHelpTip = helpTips.randomElement() ?? "Enter an idea..."
                }
                while !Task.isCancelled {
                    try await Task.sleep(for: .seconds(5))
                    withAnimation {
                        let newTip = helpTips.filter { $0 != currentHelpTip }.randomElement() ?? helpTips.randomElement() ?? "Enter an idea..."
                        currentHelpTip = newTip
                    }
                }
            } catch {
                // Task cancelled — expected on disappear or timer reset
            }
        }
        .alert("Skip This Prompt?", isPresented: $showingSkipAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Skip", role: .destructive) {
                skipPrompt()
            }
        } message: {
            Text("This prompt will be marked as used and won't appear again unless you reset your prompts.")
        }
    }
    
    private func addIdea() {
        let trimmedInput = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        withAnimation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.8)) {
            viewModel.addIdea(trimmedInput)
        }
        
        currentInput = ""
        isInputFocused = true
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
                // Category on top with icon
                HStack(spacing: 6) {
                    Image(systemName: prompt.flexibleCategory.icon)
                        .foregroundColor(prompt.flexibleCategory.colorValue)
                        .font(.caption)
                    
                    Text(prompt.flexibleCategory.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                // Prompt text below
                Text(prompt.formattedTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                // Optional help/exemplar guidance
                if let help = prompt.help, !help.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(help)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    
    private func completeList() {
        viewModel.markAsComplete()
        showingExportSheet = true
    }
    
    private func skipPrompt() {
        if let prompt = viewModel.currentIdeaList?.prompt,
           let promptViewModel = promptViewModel {
            promptViewModel.markPromptAsUsed(prompt)
        }
        dismiss()
    }
    
    private func resetHelpTimer() {
        helpTimerActive = false
        currentHelpTip = "Enter an idea..."

        // Only restart if input is still empty and focused
        if currentInput.isEmpty && isInputFocused {
            helpTimerActive = true
        }
    }
}

struct IdeaRow: View {
    let index: Int
    let text: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index + 1).")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
                .padding(.top, 8)
            
            Text(text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            .padding(.top, 8)
        }
    }
}

struct ExportView: View {
    let ideaList: IdeaList
    let promptViewModel: PromptViewModel?
    let onComplete: () -> Void
    @State private var exportFormat = "text"
    @State private var showingShareSheet = false
    @State private var markPromptAsUsed = true
    
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
                
                // Prompt usage toggle
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $markPromptAsUsed) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mark prompt as used")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(markPromptAsUsed ? 
                                "We won't use this prompt again" :
                                "Keep this prompt active for future use")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Button(action: {
                    showingShareSheet = true
                }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Button("Done") {
                    // Handle prompt usage based on toggle
                    if markPromptAsUsed, let promptViewModel = promptViewModel {
                        promptViewModel.markPromptAsUsed(ideaList.prompt)
                    }
                    onComplete()
                }
                .font(.headline)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Success!")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [
                exportFormat == "markdown" 
                    ? ExportManager.shared.exportAsMarkdown(ideaList)
                    : ideaList.formattedForExport
            ])
        }
    }
}
