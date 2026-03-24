# Development Plan

For completed work, see [DONE.md](./DONE.md).

## Next Up

1. **ExportManager tests** — simple service (25 lines) but untested; validate markdown/text export formats
2. **DraftsView + HistoryView shared row component** — similar row patterns could share IdeaListRowBase
3. **Onboarding intro** — explain app purpose on first launch
4. **Share page history notice** — tell user their list was saved to history after export

## Backlog

- [ ] SettingsView force unwrap — `URL(string:)!` on hardcoded URL (safe but poor style)
- [ ] XCUITests for navigation flows — placeholder tests exist, real tests not implemented
- [ ] Daily notification prompt — prompt user to enable daily notification after share/export

## Future / Ideas

- Design tokens system — shared cornerRadius, colors, padding constants
- Duplicate empty state pattern — extract reusable empty state component
- New pack themes — professional-development, humor/comedy-writing, cooking/food
- Seasonal/timely prompts — rotating prompts tied to seasons or holidays
- Reduce motion audit — comprehensive check for all remaining animation paths
