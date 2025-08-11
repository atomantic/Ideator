# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Idea Loom (formerly Ideator) is an iOS SwiftUI app for daily creative brainstorming through guided prompts. Users generate lists of 10 ideas based on creative prompts and can export them to Apple Notes. Built with Xcode for iOS 18.2+.

## Important Commands

**Note**: This is an Xcode project that cannot be built locally in Claude Code. All builds and tests run in GitHub Actions.

### Version Control
- **Check status**: `git status` (run after changes to ensure clean state)
- **Commits**: Use concise messages, avoid amending existing commits

### Testing & Building
- Tests run automatically via GitHub Actions on push/PR
- Check `.github/workflows/ci.yml` for CI pipeline details
- No local builds possible - rely on GitHub Actions

## Architecture

### MVVM with @Observable
- **Models** (`Ideator/Models/`): Business logic and data models
  - `Category.swift`: Prompt categories with icons and colors
  - `Prompt.swift`: Individual prompt structure
  - `IdeaList.swift`: User's idea lists with export formatting
  - `PromptPack.swift`: Modular pack management

- **Views** (`Ideator/Views/`): SwiftUI view files
  - `ContentView.swift`: Main TabView navigation
  - `HomeView.swift`: Dashboard with quick actions
  - `IdeaInputView.swift`: Core ideation interface
  - `PromptSelectionView.swift`: Browse and select prompts
  - `PromptPacksView.swift`: Manage downloadable packs
  - `DraftsView.swift`: Saved drafts management
  - `HistoryView.swift`: Completed lists history
  - `SettingsView.swift`: App preferences

- **Services** (`Ideator/Services/`): Core services
  - `PromptService.swift`: Loads and manages prompts
  - `PackManager.swift`: Downloads and updates prompt packs
  - `PersistenceManager.swift`: UserDefaults persistence
  - `ExportManager.swift`: Export to Apple Notes

- **ViewModels** (`Ideator/ViewModels/`): View logic
  - `PromptViewModel.swift`: Prompt selection and filtering
  - `IdeaListViewModel.swift`: Idea list management

## Prompt Pack System

### Local Core Pack
- Located in `Ideator/PromptPacks/Core/`
- Contains 14 categories including wellness topics
- TSV format: `text\ttags` (no suggestedCount)

### Remote Packs Repository
- GitHub: https://github.com/atomantic/IdeatorPromptPacks
- Structure: `packs/{pack-id}/manifest.json` + category TSV files
- Available packs: Tech Startup, Creative Writing, Family

### Pack Management
- Core pack can be updated from GitHub
- Additional packs downloadable in-app
- Packs stored in app's Documents directory

## Working with Prompts

### TSV Format
Prompt files use tab-separated values:
1. text: The prompt text
2. tags: Pipe-separated tags (e.g., `creativity|ideas|brainstorming`)

### Important Guidelines
- Prompts should be completable without external research
- Focus on imagination and ideation, not factual knowledge
- Each prompt typically generates 10 ideas (configurable)

## App Store Information

- **App Store Name**: Idea Loom
- **Bundle ID**: net.shadowpuppet.ideator
- **Version**: 0.1.0
- **Target iOS**: 18.2+

## Development Notes

1. **No local Xcode operations** - Cannot run xcodebuild or simulators locally
2. **Follow Swift conventions** - Standard Swift style
3. **Preserve existing patterns** - Match code style when editing
4. **GitHub Actions validation** - PRs verified on macOS runners
5. **Asset updates** - Use Xcode on macOS for `Assets.xcassets` changes

## CI/CD Pipeline

- **Branches**: main, testflight, release/**
- **iOS target**: 18.2
- **Xcode version**: 16.2 (CI), latest-stable (CD)
- **TestFlight**: Automatic deployment on main/testflight push
- **Required Secrets**:
  - TEAM_ID
  - APPSTORE_API_KEY_ID
  - APPSTORE_ISSUER_ID
  - APPSTORE_API_PRIVATE_KEY

## Key Features

1. **Daily Prompts**: 100+ creative prompts across categories
2. **Modular Packs**: Download additional prompt packs
3. **Draft Management**: Save and continue idea lists
4. **Export**: Share to Apple Notes
5. **Progress Tracking**: Track unused prompts
6. **GitHub Updates**: Update packs directly from GitHub

## Testing

Unit tests are in `IdeatorTests/`:
- Test prompt loading
- Test pack management
- Test persistence

UI tests are in `IdeatorUITests/`:
- Test navigation flows
- Test idea input