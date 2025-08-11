# Ideator

A creative brainstorming iOS app that helps users generate and capture ideas through prompted list-making exercises.

## Overview

Ideator is an iOS app designed to spark creativity and help users brainstorm ideas through guided prompts. The app presents users with various idea list prompts (e.g., "10 things I'd like to do before I die" or "10 ideas for an app"), allows them to input their ideas, and then export them to Apple Notes for future reference.

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

## Implementation Plan

### Phase 1: Core Foundation (Week 1)
- [ ] Set up project structure following MVVM pattern
- [ ] Create data models for prompts and idea lists
- [ ] Design prompt database structure
- [ ] Implement prompt storage system (JSON or Core Data)
- [ ] Create 50+ initial prompt templates across categories:
  - Personal Development
  - Professional/Career
  - Creative Projects
  - Lifestyle/Wellness
  - Relationships
  - Entertainment
  - Travel/Adventure
  - Learning/Skills
  - Financial Goals
  - Social Impact

### Phase 2: User Interface (Week 2)
- [ ] Design main navigation structure
- [ ] Create prompt selection view with categories
- [ ] Build idea input interface with:
  - Numbered list items (1-10)
  - Auto-focus on next field
  - Progress indicator
  - Character limit per idea
- [ ] Implement review/edit screen before export
- [ ] Add animations and transitions

### Phase 3: Core Functionality (Week 3)
- [ ] Implement prompt randomization logic
- [ ] Add prompt history tracking to avoid repetition
- [ ] Create idea list management system
- [ ] Build export functionality to Apple Notes
- [ ] Add share sheet integration
- [ ] Implement data persistence for drafts

### Phase 4: Polish & Enhancement (Week 4)
- [ ] Add onboarding flow
- [ ] Implement settings:
  - List size preference (5, 10, 15 items)
  - Theme selection
  - Export format options
- [ ] Create prompt suggestion feature
- [ ] Add daily prompt notifications (optional)
- [ ] Implement analytics for popular prompts

### Phase 5: Testing & Deployment
- [ ] Set up GitHub Actions CI/CD pipeline (adapt from HueKnew)
- [ ] Configure TestFlight deployment
- [ ] Write unit tests for models and view models
- [ ] UI testing for critical flows
- [ ] Beta testing feedback integration

## Prompt Generation Strategy

To ensure variety and prevent repetition:

1. **Template System**: Create prompt templates with variables
   - Example: "10 [adjective] ways to [verb] your [noun]"
   - Generate variations programmatically

2. **Category Rotation**: Track last-used categories and prioritize others

3. **Seasonal/Contextual Prompts**: Time-based prompts for holidays, seasons, etc.

4. **User Customization**: Allow users to create custom prompts

5. **Prompt Database Structure**:
   ```swift
   struct Prompt {
       let id: UUID
       let text: String
       let category: Category
       let suggestedCount: Int
       let tags: [String]
       let difficulty: Difficulty
   }
   ```

## Sample Prompts

### Personal Development
- 10 habits I want to develop this year
- 10 fears I want to overcome
- 10 skills I'd like to master
- 10 ways to improve my morning routine

### Creative
- 10 story ideas I'd love to write
- 10 inventions that would make life easier
- 10 art projects to try
- 10 podcast episode ideas

### Professional
- 10 business ideas to explore
- 10 ways to improve my workspace
- 10 networking opportunities to pursue
- 10 career goals for the next 5 years

### Fun & Lifestyle
- 10 bucket list adventures
- 10 recipes to try this month
- 10 books to read this year
- 10 places to visit in my city

## Data Models

### Core Models
```swift
// Prompt model
@Observable
class PromptModel {
    var currentPrompt: Prompt
    var usedPromptIds: Set<UUID>
    var categories: [Category]
}

// Idea list model
@Observable
class IdeaListModel {
    var prompt: Prompt
    var ideas: [String]
    var createdDate: Date
    var isComplete: Bool
}

// Export manager
class ExportManager {
    func exportToNotes(_ ideaList: IdeaListModel)
    func formatForExport(_ ideaList: IdeaListModel) -> String
}
```

## CI/CD Setup

### GitHub Actions Workflow
Based on HueKnew's successful implementation:

1. **Branches**:
   - `main`: Production releases to TestFlight
   - `develop`: Development builds
   - `feature/*`: Feature branches

2. **Required Secrets**:
   - `TEAM_ID`: Apple Developer Team ID
   - `APPSTORE_API_KEY_ID`: App Store Connect API Key
   - `APPSTORE_ISSUER_ID`: App Store Connect Issuer ID
   - `APPSTORE_API_PRIVATE_KEY`: Private key for App Store Connect

3. **Workflow Jobs**:
   - Build & Test on PR
   - Deploy to TestFlight on main branch push
   - Automated version bumping

## Apple Notes Integration

### Implementation Approach
1. Use `UIActivityViewController` for sharing
2. Format ideas as structured text
3. Include metadata (date, prompt, category)
4. Support rich text formatting
5. Alternative: Direct Notes API if available

### Export Format Example
```
Ideator List: 10 Business Ideas to Explore
Created: January 11, 2025

1. Sustainable packaging subscription service
2. AI-powered personal finance coach
3. Virtual reality language learning platform
[...]

---
Generated with Ideator
```

## Development Guidelines

### Code Organization
```
Ideator/
├── Models/
│   ├── PromptModel.swift
│   ├── IdeaListModel.swift
│   └── Category.swift
├── Views/
│   ├── ContentView.swift
│   ├── PromptSelectionView.swift
│   ├── IdeaInputView.swift
│   └── ExportView.swift
├── ViewModels/
│   ├── PromptViewModel.swift
│   └── IdeaListViewModel.swift
├── Services/
│   ├── PromptService.swift
│   ├── ExportManager.swift
│   └── PersistenceManager.swift
├── Data/
│   └── prompts.json
└── Resources/
    └── Assets.xcassets
```

### Best Practices
- Follow Swift naming conventions
- Use @Observable for state management
- Keep views small and focused
- Write testable code
- Document complex logic
- Use dependency injection

## Testing Strategy

### Unit Tests
- Prompt selection logic
- Export formatting
- Data persistence
- Prompt randomization

### UI Tests
- Complete idea flow
- Export functionality
- Navigation
- Error states

## Future Enhancements

### Version 2.0
- [ ] Collaborative lists with friends
- [ ] AI-powered prompt suggestions based on interests
- [ ] Voice input for ideas
- [ ] Rich media support (images, links)
- [ ] Cloud sync across devices

### Version 3.0
- [ ] Social sharing features
- [ ] Idea development tools (expand ideas into projects)
- [ ] Integration with other productivity apps
- [ ] Gamification elements
- [ ] Machine learning for personalized prompts

## License

[To be determined]

## Contact

[Your contact information]