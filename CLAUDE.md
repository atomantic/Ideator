# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Idea Loom (formerly Ideator) is an iOS SwiftUI app for daily creative brainstorming through guided prompts. Users generate lists of 10 ideas based on creative prompts and can export them to Apple Notes. Built with Xcode for iOS 18.2+.

## Build Commands

```bash
# Build
xcodebuild build -project Ideator.xcodeproj -scheme Ideator \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' CODE_SIGNING_ALLOWED=NO

# Run tests
xcodebuild test -project Ideator.xcodeproj -scheme Ideator \
  -only-testing:IdeatorTests \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' CODE_SIGNING_ALLOWED=NO
```

## Git Workflow

After every feature or bug fix:

1. **Build and test** — verify `xcodebuild build` and `xcodebuild test` pass
2. **`/simplify`** — run code review for reuse, quality, and efficiency; fix issues found
3. **`/do:review`** — deep code review against best practices
4. **`/do:push`** — commit and push to GitHub
5. **`/release`** — when ready for TestFlight, run the local deploy (see below)

## TestFlight Deployment

Local deploy via `./deploy.sh` (used when CI build credits are exhausted):

```bash
./deploy.sh              # full: tests + archive + upload
./deploy.sh --skip-tests # skip tests for faster iteration
```

Requires `.env` file with App Store Connect API credentials (see `.env.example`).

CI/CD via GitHub Actions (`.github/workflows/ci.yml`) deploys automatically on push to `main`, `testflight`, or `release/*` branches.

### Core Pack Sync
- **Sync script**: `./sync-core-pack.sh` - Syncs core pack from IdeatorPromptPacks repo
- **Usage**: Run before releases to update bundled core pack to latest version
- **Prerequisites**: IdeatorPromptPacks must be cloned in parent directory

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
- Located in `Ideator/Resources/PromptPacks/Core/`
- Contains 14 categories including wellness topics
- TSV format: `text\ttags` (no suggestedCount)
- Version: Synced from IdeatorPromptPacks using `sync-core-pack.sh`

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
2. help: Helper hint shown in parentheses
3. slug: Stable identifier for the prompt (used for deterministic UUID generation — allows text to be revised without breaking user data)

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

1. **Follow Swift conventions** - Standard Swift style
2. **Preserve existing patterns** - Match code style when editing
3. **GitHub Actions validation** - PRs verified on macOS runners
4. **Asset updates** - Use Xcode on macOS for `Assets.xcassets` changes

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