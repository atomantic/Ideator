# Development Plan

For completed work, see [DONE.md](./DONE.md).

## Next Up

1. **Home Screen Widget** — WidgetKit widget showing today's prompt + current streak count; tapping opens directly into ideation. Drives daily engagement without needing to open the app. Interactive widgets (iOS 17+) could include a "Start" button.
2. **Best Ideas Collection** — Users can favorite prompts but not individual ideas. Add a star/flag on each idea in History detail view that saves it to a curated "Best Ideas" collection accessible from Home. Surfaces the gems buried across dozens of completed lists.
3. **Idea Remix Challenge** — After completing a list, offer to randomly combine 2 of the user's ideas into a new creative prompt. "What if you combined 'underwater restaurant' with 'AI personal trainer'?" Creates a unique second-order ideation loop that keeps users generating.

## Backlog

- [ ] XCUITests for navigation flows — placeholder tests exist, real tests not implemented

## Future / Ideas

- Design tokens system — shared cornerRadius, colors, padding constants
- Duplicate empty state pattern — extract reusable empty state component
- New pack themes — professional-development, humor/comedy-writing, cooking/food
- Seasonal/timely prompts — rotating prompts tied to seasons or holidays
- Reduce motion audit — comprehensive check for all remaining animation paths
