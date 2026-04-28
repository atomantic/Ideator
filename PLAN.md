# Development Plan

For completed work, see [DONE.md](./DONE.md).

## Next Up

1. **ObsidianSyncManager tests** — new sync service has no unit tests; cover sync result, folder picker fallback, and auto-sync gating
2. **Reduce-motion guards** — wrap unguarded `withAnimation` calls in HomeView.swift:55, OnboardingView.swift:474/485, IdeaListDetailView.swift:74

## Backlog

- [ ] XCUITests for navigation flows — placeholder tests exist, real tests not implemented

## Future / Ideas

- Design tokens system — shared cornerRadius, colors, padding constants
- Extract reusable empty-state component — DraftsView and HistoryView duplicate the same icon+title+subtitle layout
- New pack themes — professional-development, humor/comedy-writing, cooking/food
