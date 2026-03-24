# Done Log

Completed items archived from PLAN.md.

## 2026-03-18

- Favorites/bookmarking — heart button on prompt rows, favorites section on Home, filter in prompt selection
- Share individual ideas — ShareLink on each idea in history detail + context menu in idea input
- Streaks & gamification — confetti celebration, achievement badges grid, 11 unlockable achievements
- Fixed vacuous tests — replaced with real assertions for achievements and color strings
- Added 34 new tests — StoreManager (8), PackManager (8), IdeaListViewModel (10), PromptViewModel (8)
- Standardized @Observable — migrated StreakManager, PackManager, StoreManager from ObservableObject
- Extracted business logic from views — assessed: logic is minimal, not worth extracting
- Better Swift audit (29 findings, 18 fixed): pack ID validation, privacy annotations, print->logger, try? error handling, reduce motion guards, accessibility, purchaseIfNeeded() extraction, PackStatsView component, semantic fonts
- Strengthened test suite to 51 passing — vacuous tests replaced, edge cases added, ViewModel tests added

## 2026-03-17

- Better Swift audit (74 findings, 39 fixed): force unwrap removal, logger migration, Observable standardization, DRY consolidation, timer memory leak fix, N+1 persistence query fix, accessibility improvements
- Slug-based prompt ID system — slug column in TSV files, migration from text-based to slug-based UUIDs, deterministicId helper
- Local build & deploy — xcodebuild verification, deploy.sh for TestFlight, /release command, .env.example
- Codable round-trip tests, model tests, PersistenceManager CRUD tests, StreakManager tests
- TSVParser/VersionCompare/UUID edge case tests
