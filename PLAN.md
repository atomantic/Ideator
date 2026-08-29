# Development Plan

## Next Up

1. **ObsidianSyncManager tests** — new sync service has no unit tests; cover sync result, folder picker fallback, and auto-sync gating
2. **Reduce-motion guards** — wrap unguarded `withAnimation` calls in HomeView.swift:55, OnboardingView.swift:474/485, IdeaListDetailView.swift:74

## Backlog

- [ ] XCUITests for navigation flows — placeholder tests exist, real tests not implemented
- [ ] HomeView decomposition — file has grown to 956 lines; extract sections (Best Ideas, Seasonal, Prompt of the Day, Streaks) like the prior HistoryView split

## Future / Ideas

- Extract reusable empty-state component — DraftsView, HistoryView, and InsightsView duplicate the same icon+title+subtitle layout
- New pack themes — professional-development, humor/comedy-writing, cooking/food
