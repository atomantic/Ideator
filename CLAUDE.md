# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Idea Loom (formerly Ideator) is an iOS SwiftUI app for daily creative brainstorming through guided prompts. Users generate lists of 10 ideas based on creative prompts and can export them to Apple Notes. Built with Xcode for iOS 18.2+.

## Build Commands

Do not pin a simulator name or OS version — installed runtimes drift, and a
stale pin fails with "Unable to find a device matching the provided destination
specifier". Resolve a device that is actually installed instead. (CI solves the
same problem differently: `ci.yml` probes a hardcoded iPhone 16 → 15 → 14
preference list.)

```bash
# Build — no simulator needed
xcodebuild build -project Ideator.xcodeproj -scheme Ideator \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO

# Run tests — resolve whatever iPhone simulator is actually installed
DEST="platform=iOS Simulator,name=$(xcrun simctl list devices available \
  | grep -o 'iPhone [^(]*' | tail -1 | sed 's/ *$//')"
xcodebuild test -project Ideator.xcodeproj -scheme Ideator \
  -only-testing:IdeatorTests \
  -destination "$DEST" CODE_SIGNING_ALLOWED=NO
```

Check what is installed with `xcrun simctl list devices available`.

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

CI/CD via GitHub Actions (`.github/workflows/ci.yml`) builds and tests every pull request, plus
every push to `main`, `testflight`, or `release/**`. It uploads to TestFlight only when such a push
also changes `MARKETING_VERSION` or `CURRENT_PROJECT_VERSION` in `project.pbxproj` — App Store
Connect rejects a version+build pair it has already accepted. A new build under an unchanged
marketing version is fine (that is what `./deploy.sh` does); re-sending the same pair is not.

### Pack Sync
- **Sync script**: `./sync-packs.sh` - Syncs all packs from IdeatorPromptPacks repo
- **Usage**: Run before releases to update bundled packs to latest version
- **Prerequisites**: IdeatorPromptPacks must be cloned in parent directory
- **Note**: Manifests are renamed to `{packId}-manifest.json` to avoid Xcode flat-bundle collisions

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
  - `PromptPacksView.swift`: Manage and purchase prompt packs
  - `DraftsView.swift`: Saved drafts management
  - `HistoryView.swift`: Completed lists history
  - `SettingsView.swift`: App preferences

- **Services** (`Ideator/Services/`): Core services
  - `PromptService.swift`: Loads and manages prompts
  - `PackManager.swift`: Loads bundled prompt packs, manages enabled state
  - `PersistenceManager.swift`: UserDefaults persistence
  - `ExportManager.swift`: Export to Apple Notes

- **ViewModels** (`Ideator/ViewModels/`): View logic
  - `PromptViewModel.swift`: Prompt selection and filtering
  - `IdeaListViewModel.swift`: Idea list management

## Prompt Pack System

### Bundled Packs
- All packs are bundled in `Ideator/Resources/PromptPacks/`
- Core pack is free; other packs require IAP ($0.99 each)
- Manifests named `{packId}-manifest.json` to avoid Xcode flat-bundle collisions
- Packs: core, creative-writing, disaster-prep, family, impact-finance, silly, surreal, tech-startup, wellness

### Source Repository
- GitHub: https://github.com/atomantic/IdeatorPromptPacks
- Structure: `packs/{pack-id}/manifest.json` + category TSV files
- Sync to app bundle using `./sync-packs.sh`

### Pack Management
- Purchase unlocks pack instantly (no download needed)
- StoreKit 2 handles IAP; StoreManager tracks purchased state
- PackManager loads all packs from app bundle, filters by purchase state

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
- **Version**: 1.3.3
- **Target iOS**: 18.2+

## Development Notes

1. **Follow Swift conventions** - Standard Swift style
2. **Preserve existing patterns** - Match code style when editing
3. **GitHub Actions validation** - PRs verified on macOS runners
4. **Asset updates** - Use Xcode on macOS for `Assets.xcassets` changes

## CI/CD Pipeline

- **Branches**: main, testflight, release/**
- **iOS target**: 18.2
- **Xcode version**: latest-stable (both CI and CD)
- **TestFlight**: Deploys on a main/testflight/release push that bumps the version (see above)
- **Required Secrets**:
  - TEAM_ID
  - APPSTORE_API_KEY_ID
  - APPSTORE_ISSUER_ID
  - APPSTORE_API_PRIVATE_KEY

## Key Features

1. **Daily Prompts**: 200+ creative prompts across categories (Core pack)
2. **Premium Packs**: 8 additional packs purchasable via IAP ($0.99 each)
3. **Draft Management**: Save and continue idea lists
4. **Export**: Share to Apple Notes
5. **Progress Tracking**: Track unused prompts

## Testing

Unit tests are in `IdeatorTests/`:
- Test prompt loading
- Test pack management
- Test persistence

UI tests are in `IdeatorUITests/`:
- Test navigation flows
- Test idea input