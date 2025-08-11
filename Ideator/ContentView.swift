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
        .sheet(isPresented: $showingPromptSelection) {
            PromptSelectionView(
                promptViewModel: promptViewModel,
                ideaListViewModel: ideaListViewModel,
                showingIdeaInput: $showingIdeaInput
            )
        }
        .sheet(isPresented: $showingIdeaInput) {
            if let _ = ideaListViewModel.currentIdeaList {
                IdeaInputView(viewModel: ideaListViewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
