# Development Plan

For completed work, see [DONE.md](./DONE.md).

## Next Up

1. **ContentView coordinator extraction** — move business logic out of .onAppear (onboarding check, notification subscriptions) into a coordinator or ViewModel
2. **HistoryView decomposition** — 715-line view needs calendar, list, and header subviews extracted
3. **PromptService tests** — 319-line service with complex pack loading, migration, and filtering logic has zero test coverage
4. **Memoize groupedCategories** — `PromptSelectionView` calls Dictionary(grouping:) in body; `HomeView` has heavy computed property that should be cached

## Backlog

- [ ] HomeView async logic extraction — move pack update logic from view to PackManager
- [ ] PackManager task gate — add cancellation for concurrent pack update Tasks
- [ ] ExportManager tests — simple service (25 lines) but untested; validate markdown/text export formats
- [ ] DraftsView + HistoryView shared row component — similar row patterns could share IdeaListRowBase
- [ ] SettingsView force unwrap — `URL(string:)!` on hardcoded URL (safe but poor style)
- [ ] XCUITests for navigation flows — placeholder tests exist, real tests not implemented
- [ ] Onboarding intro — explain app purpose on first launch (README TODO)
- [ ] Share page history notice — tell user their list was saved to history after export
- [ ] Daily notification prompt — prompt user to enable daily notification after share/export

## Future / Ideas

- Design tokens system — shared cornerRadius, colors, padding constants
- Duplicate empty state pattern — extract reusable empty state component
- New pack themes — professional-development, humor/comedy-writing, cooking/food
- Seasonal/timely prompts — rotating prompts tied to seasons or holidays
- Reduce motion audit — comprehensive check for all remaining animation paths
