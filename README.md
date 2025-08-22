# Idea Loom

A creative brainstorming iOS app that helps users generate and capture ideas through prompted list-making exercises.

## Overview

Idea Loom is an iOS app designed to spark creativity and help users brainstorm ideas through guided prompts. The app presents users with various idea list prompts (e.g., "things I'd like to do before I die" or "ideas for an app"), allows them to input their ideas, and then export them to Apple Notes or other sources for future reference.

## Features

- **Dynamic Prompts**: Variety of idea list prompts to inspire creative thinking
- **Intuitive Input**: Simple interface for entering ideas quickly
- **Apple Notes Integration**: Export completed idea lists directly to Apple Notes
- **Prompt Categories**: Organized prompts by theme (personal, professional, creative, etc.)
- **Progress Tracking**: Visual feedback as users complete their lists

## Tech Stack

- **Platform**: iOS 18.2+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM with @Observable
- **Export**: Apple Notes integration via Share Sheet
- **CI/CD**: GitHub Actions with TestFlight deployment

## Prompt Generation Strategy

To ensure variety and prevent repetition:

1. **Template System**: Create prompt templates with variables
   - Example: "[adjective] ways to [verb] your [noun]"
   - Generate variations programmatically

2. **Category Rotation**: Track last-used categories and prioritize others

3. **Seasonal/Contextual Prompts**: Time-based prompts for holidays, seasons, etc.

4. **User Customization**: Allow users to create custom prompts

## Sample Prompts

### Personal Development
- habits I want to develop this year
- fears I want to overcome
- skills I'd like to master
- ways to improve my morning routine

### Creative
- story ideas I'd love to write
- inventions that would make life easier
- art projects to try
- podcast episode ideas

### Professional
- business ideas to explore
- ways to improve my workspace
- networking opportunities to pursue
- career goals for the next 5 years

### Fun & Lifestyle
- bucket list adventures
- recipes to try this month
- books to read this year
- places to visit in my city

## TODO:

- intro explaining app
- on share page explain that we've saved it in history
- should prompt to set daily notification

## License

[Idea Loom License](./LICENSE)
### Prompt Pack Version Selection

The app downloads community packs from the `IdeatorPromptPacks` repo. To avoid breaking older app versions when the prompt schema evolves, the app chooses which git ref (branch/tag) to read from:

- The packs repo publishes a root `schema.json` with `schemaMajor`.
- On startup, the app fetches `schema.json` from `main`:
  - If `schemaMajor` on `main` is greater than the app’s supported schema, the app reads packs from the git tag that matches the app version: `v{CFBundleShortVersionString}`.
  - Otherwise, it reads from `main`.
- If fetching from the chosen ref fails, the app falls back to `main`.

Release flow:
- Before introducing a breaking schema change on `main`, tag the packs repo with the current App Store version `vX.Y.Z` and bump `schemaMajor` in `schema.json`.
- Ship the new app when ready; older apps will continue reading their matching tag; newer apps will read `main`.
