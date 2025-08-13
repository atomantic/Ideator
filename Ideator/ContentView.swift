//
//  ContentView.swift
//  Ideator
//
//  Created by Adam Eivy on 8/11/25.
//

import SwiftUI

struct ContentView: View {
    @State private var promptViewModel = PromptViewModel()
    @State private var ideaListViewModel = IdeaListViewModel()
    @State private var selectedTab = 0
    @State private var showingPromptSelection = false
    @State private var showingIdeaInput = false
    @State private var draftCount = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                promptViewModel: promptViewModel,
                ideaListViewModel: ideaListViewModel,
                showingPromptSelection: $showingPromptSelection,
                showingIdeaInput: $showingIdeaInput
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            DraftsView(ideaListViewModel: ideaListViewModel)
                .tabItem {
                    Label("Drafts", systemImage: "doc.text.fill")
                }
                .badge(draftCount > 0 ? "\(draftCount)" : nil)
                .tag(1)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(2)
            
            SettingsView(promptViewModel: promptViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .onAppear {
            updateDraftCount()
        }
        .onChange(of: selectedTab) { _, _ in
            updateDraftCount()
        }
        .onChange(of: showingIdeaInput) { _, _ in
            updateDraftCount()
        }
        .sheet(isPresented: $showingPromptSelection) {
            PromptSelectionView(
                promptViewModel: promptViewModel,
                ideaListViewModel: ideaListViewModel,
                showingIdeaInput: $showingIdeaInput
            )
        }
        .sheet(isPresented: $showingIdeaInput) {
            if let _ = ideaListViewModel.currentIdeaList {
                IdeaInputView(viewModel: ideaListViewModel, promptViewModel: promptViewModel)
            }
        }
    }
    
    private func updateDraftCount() {
        draftCount = PersistenceManager.shared.loadDrafts().count
    }
}

#Preview {
    ContentView()
}
