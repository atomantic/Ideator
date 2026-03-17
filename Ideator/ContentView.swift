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
    @State private var showingOnboarding = false
    @State private var draftCount = 0
    @State private var packsVersion = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                promptViewModel: promptViewModel,
                ideaListViewModel: ideaListViewModel,
                showingPromptSelection: $showingPromptSelection,
                showingIdeaInput: $showingIdeaInput
            )
            .id(packsVersion)
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
            
            HistoryView(promptViewModel: promptViewModel)
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(2)
            
            SettingsView(
                promptViewModel: promptViewModel,
                onShowOnboarding: {
                    showingOnboarding = true
                }
            )
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
        .onAppear {
            updateDraftCount()
            // Show onboarding for first-time users
            if !hasCompletedOnboarding {
                showingOnboarding = true
            }
        }
          .onChange(of: selectedTab) { _, _ in
              updateDraftCount()
          }
          .onChange(of: showingIdeaInput) { _, _ in
              updateDraftCount()
          }
          .onReceive(NotificationCenter.default.publisher(for: .dailyPromptTriggered)) { _ in
              if let randomPrompt = promptViewModel.getRandomPrompt() {
                  ideaListViewModel.startNewList(with: randomPrompt)
                  showingIdeaInput = true
                  selectedTab = 0
              }
          }
          .onReceive(NotificationCenter.default.publisher(for: .promptsReloaded)) { _ in
              // Reload prompts and force HomeView rebuild to reflect new categories
              promptViewModel.loadPrompts()
              packsVersion += 1
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
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(isPresented: $showingOnboarding)
        }
    }
    
    private func updateDraftCount() {
        draftCount = PersistenceManager.shared.loadDrafts().count
    }
}

#Preview {
    ContentView()
}
