# SQLQuest

SQLQuest is an interactive iOS/iPadOS app built with SwiftUI that teaches SQL JOIN concepts (INNER, LEFT, and RIGHT JOIN) through live visual diagrams, hands-on data exploration, gamified quests, and an embedded AI tutor. It is packaged as a Swift Playground App (`.swiftpm`) and targets iOS 16.0 and later.

## Overview

Understanding how SQL JOINs behave is often abstract when taught only through text and static diagrams. SQLQuest turns the concept into something visual and interactive: users pick a JOIN type and immediately see the underlying Venn diagram, an animated data flow between two tables, the generated SQL, and the resulting row set update in real time. The app then reinforces that understanding through a 28-quest progression system and a context-aware AI chat tutor.

## Features

### Explore Joins (two-table mode)
- Interactive Venn diagram and animated particle flow that visualize how an INNER, LEFT, or RIGHT JOIN combines a `Students` table and a `Clubs` table.
- Live, syntax-highlighted SQL statement that updates as the JOIN type changes.
- A natural-language input field that maps a plain-English description (for example, "show all students, even without a club") to the matching JOIN type.
- A raw data inspector sheet showing the two underlying source tables before any JOIN is applied.
- VoiceOver accessibility descriptions for the diagram and result rows.

### 3-Table Joins (advanced mode)
- A chained JOIN pipeline across three tables: `Students`, `Enrollments`, and `Courses`.
- Independent JOIN type selection for each junction (Students to Enrollments, and Enrollments to Courses).
- A three-way Venn visualization and a dynamically generated multi-column result table.
- Generated SQL preview reflecting both JOIN choices.

### Quest Mode
- 28 quests spread across five difficulty tiers: Newbie, Easy, Medium, Hard, and SQL Expert.
- Four distinct question mechanics: Multiple Choice, SQL Builder, Reverse Engineer (infer the JOIN from a result table), and Sequence Order (reassemble scrambled SQL clauses).
- Per-difficulty countdown timer, an optional hint system, and an XP and leveling system (SQL Newbie through Database Sensei) with progress persisted on-device via `AppStorage`.
- Session statistics including accuracy and streak tracking, plus a failure hand-off that forwards the missed quest into the AI Tutor for a targeted explanation.

### AI Tutor
- A chat-based SQL tutor that is context-aware: it knows which JOIN the user is currently exploring and can reference the quest the user most recently failed.
- Works out of the box with a built-in, offline simulated response engine covering the most common JOIN questions, so no API key is required for a demo.
- Optionally connects to the Anthropic Claude API when a personal API key is supplied in-app, for open-ended, dynamically generated answers.
- Quick-start suggestion chips for common questions (for example, INNER JOIN analogies, LEFT vs. RIGHT JOIN, or generating a custom practice scenario).

### Adaptive interface
- `NavigationSplitView` sidebar layout on iPad (regular width) and a `TabView` layout on iPhone (compact width), driven by the same shared view models.

## Tech stack

- Swift 6
- SwiftUI (iOS 16.0+, iPad and iPhone)
- Swift Playground App package format (`.swiftpm`), buildable and runnable directly in Xcode or Swift Playgrounds
- `URLSession` for the optional live Anthropic API integration
- No third-party dependencies

## Project structure

```
SQLQuest.swiftpm/
├── Package.swift              App package manifest (iOS app target configuration)
├── MyApp.swift                App entry point
├── MainView.swift             Adaptive root view, Explore Joins and 3-Table Joins screens
├── DataModels.swift           JoinType, table/row models, quest difficulty, and app navigation enums
├── DesignSystem.swift         Shared typography, spacing, radius, and color tokens
├── JoinViewModel.swift        Two-table JOIN computation and natural-language query parsing
├── JoinSelectorView.swift     JOIN type picker control
├── VennCricle.swift           Two-circle Venn diagram component
├── DataFlowOverlay.swift      Animated data flow visualization over the Venn diagram
├── RawDataView.swift          Source table inspector sheet
├── MultiTableViewModel.swift  Three-table JOIN pipeline logic and SQL generation
├── ThreeWayVennView.swift     Three-circle Venn diagram component
├── QuestModel.swift           Quest data model and the full 28-quest question bank
├── QuestViewModel.swift       Quest state machine, timer, scoring, and submission logic
├── QuestView.swift            Quest hub, challenge, feedback, and summary screens
├── GameProgressViewModel.swift XP, leveling, streaks, and persisted quest completion
├── AITutorViewModel.swift     Chat state, simulated tutor responses, and Anthropic API calls
├── AITutorView.swift          AI Tutor chat interface
└── AppIcon.png                App icon asset
```

## Getting started

1. Open `SQLQuest.swiftpm` in Xcode 15 or later, or in the Swift Playgrounds app on iPad or Mac.
2. Select an iOS or iPadOS simulator (or a connected device) running iOS 16.0 or later.
3. Build and run.

The AI Tutor works without any configuration using its built-in simulated responses. To use live Claude-generated answers instead, enter a personal Anthropic API key in the AI Tutor tab; the key is used only for local API calls and is not bundled with the app.

## License

No license file is currently included in this repository. Add a license of your choice before distributing or open-sourcing the project.
