# PLAN.md

## Better Swift Audit - 2026-03-17

Summary: 74 findings across 20 files. 39 fixed, 35 LOW deferred.
Platform: iOS | Deployment target: 18.5+

### Security & Secrets
- [x] **[MEDIUM]** `.env.example:1` - Real Team ID in template — replaced with placeholder

### Code Quality & Style
- [x] **[CRITICAL]** `StreakManager.swift:6` - Missing ObservableObject conformance — added
- [x] **[HIGH]** `PackManager.swift:20` - Force unwrap on FileManager .first! — guard let
- [x] **[HIGH]** `PromptService.swift:39` - Force unwrap on FileManager .first! — guard let
- [x] **[HIGH]** `HistoryView.swift:250,256,263` - Force unwraps on Calendar operations — guard let
- [x] **[HIGH]** Services throughout - print() instead of Logger — replaced with os.log
- [x] **[MEDIUM]** `FlexibleCategory.swift:58` - Force unwrap on packId! — safe optional binding
- [x] **[MEDIUM]** `IdeaInputView.swift:261` - Timer reference not nil'd after invalidate — fixed with .task pattern
- [ ] **[LOW]** `PersistenceManager.swift` - Classes not marked `final`
- [ ] **[LOW]** `TSVParser.swift` - Struct with only static methods could be enum
- [ ] **[LOW]** `SettingsView.swift:275` - Force unwrap on hardcoded URL (safe but style)
- [ ] **[LOW]** `IdeaInputView.swift:12` - helpTips as @State could be private let

### DRY & YAGNI
- [x] **[HIGH]** `CustomPromptView.swift + CustomPromptsListView.swift` - Duplicate getAllCategories() — consolidated into FlexibleCategory.allCategories()
- [x] **[MEDIUM]** `Category.swift:41-79` - Duplicate color mapping — derived colorValue from color string via Color.from(name:)
- [x] **[MEDIUM]** `HomeView.swift:269-316` - Duplicate update button — extracted to packUpdateButton() helper
- [ ] **[MEDIUM]** `DraftsView.swift + HistoryView.swift` - Similar row components — create IdeaListRowBase
- [ ] **[MEDIUM]** Throughout - No shared design tokens (cornerRadius, colors, padding)
- [ ] **[LOW]** Multiple views - Duplicate empty state pattern
- [ ] **[LOW]** `IdeaInputView.swift` - Duplicate TextField focus border pattern

### Architecture & SOLID
- [x] **[HIGH]** `IdeaListViewModel.swift:72` - markPromptAsUsed coupled to markAsComplete — removed, caller decides
- [x] **[HIGH]** `PromptSelectionView.swift:43-46` - N+1 persistence query per row — cached in @State Set
- [x] **[MEDIUM]** `SettingsView.swift:40-59` - Scattered teardown logic — extracted resetAllData()
- [x] **[MEDIUM]** `ExportManager.swift:51` - Wrong category name for pack prompts — use flexibleCategory.name
- [ ] **[HIGH]** `ContentView.swift:59-83` - Business logic in view onAppear — extract to coordinator
- [ ] **[MEDIUM]** `HomeView.swift:354-371` - Async business logic in view — extract to PackManager
- [ ] **[MEDIUM]** `HomeView.swift:249-347` - Heavy computed property — cache groupedCategories
- [ ] **[MEDIUM]** `HistoryView.swift` - 700+ line view — extract calendar and list subviews
- [ ] **[LOW]** `PromptViewModel.swift` - 50% of methods are thin forwarding wrappers

### Bugs, Performance & Error Handling
- [x] **[CRITICAL]** `IdeaInputView.swift:261` - Timer memory leak — replaced with .task pattern
- [x] **[HIGH]** `HomeView.swift:43` - .onAppear { Task } instead of .task — fixed
- [x] **[HIGH]** `HomeView.swift:250` - ForEach with unstable offset IDs — stable packId
- [x] **[MEDIUM]** `PackManager.swift` - try? swallowing errors — added Logger error logging
- [ ] **[HIGH]** `PackManager.swift` - @StateObject with singleton — use @Environment or direct access
- [ ] **[MEDIUM]** `PackManager.swift:222-277` - Concurrent Task without cancellation — add task gate
- [ ] **[MEDIUM]** `PromptService.swift:150-165` - Double filter on allPrompts — single pass
- [ ] **[MEDIUM]** `PromptSelectionView.swift:64-66` - Dictionary(grouping:) in body — memoize
- [ ] **[LOW]** `ContentView.swift:82` - Wrapping increment — replaced with standard increment

### Platform Coverage & SwiftUI Patterns
- [x] **[HIGH]** `HomeView.swift` - .onAppear async → .task modifier
- [x] **[MEDIUM]** `OnboardingView.swift` - Hardcoded font sizes → @ScaledMetric
- [x] **[MEDIUM]** `DraftsView.swift + HistoryView.swift` - Missing accessibility on decorative images
- [ ] **[HIGH]** Mixed ObservableObject/@Observable — standardize to @Observable (target supports iOS 18.5)
- [ ] **[MEDIUM]** `HomeView.swift:23` - @StateObject with singleton PackManager
- [ ] **[MEDIUM]** `IdeaInputView.swift` - Button with no accessibility label
- [ ] **[LOW]** `OnboardingView.swift` - Gradient opacity may need dark mode testing
- [ ] **[LOW]** Throughout - Missing @Environment(\.accessibilityReduceMotion) checks

### Test Quality & Coverage — 51 tests passing
- [x] Delete empty placeholder IdeatorTests.swift
- [x] Codable round-trip tests (Prompt, IdeaList, Category, FlexibleCategory) — 8 tests
- [x] Model tests (Prompt, IdeaList, Category, FlexibleCategory) — 12 tests
- [x] PersistenceManager tests (CRUD, dedup, clearAll) — 10 tests
- [x] StreakManager tests (streaks, milestones, reset) — 11 tests
- [x] Strengthen TSVParser edge cases (empty, extra cols, empty slug) — 3 tests added
- [x] Strengthen VersionCompare edge cases (equal, empty) — 2 tests added
- [x] Strengthen UUID determinism tests (format, empty string) — 2 tests added
- [ ] IdeaListViewModel state transition tests
- [ ] PromptViewModel tests
- [ ] XCUITests for navigation flows

## Slug-Based Prompt ID System — 2026-03-17
- [x] Add slug column to all TSV files (IdeatorPromptPacks)
- [x] Add slug field to Prompt model
- [x] Update TSVParser for 3rd column
- [x] Add migration for usedPromptIds (text-based → slug-based UUIDs)
- [x] Extract Prompt.deterministicId helper
- [x] Sync core pack to v1.3.0
- [x] Add "Things I wonder about" creative prompt

## Local Build & Deploy — 2026-03-17
- [x] Verify local xcodebuild works
- [x] Add deploy.sh for local TestFlight uploads
- [x] Add /release command
- [x] Add .env.example
- [x] Update CLAUDE.md with build commands and workflow
