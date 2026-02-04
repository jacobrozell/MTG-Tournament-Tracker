# Budget League Tracker iOS App – Context Document

This document provides an overview of the iOS app architecture so you can quickly resume development or onboard new contributors.

**Status:** Core implementation complete. All views, ViewModels, components, and engine functions are implemented. Ready for macOS/Xcode build and testing.

---

## What This App Is

**Budget League Tracker** is a native iOS app for organizing Magic: The Gathering (MTG) budget leagues. It is designed for the **organizer role** (not spectator/player):

- Multi-week tournaments (configurable 1–99 weeks)
- Pods of 4 players per game
- Placement points scoring (1st → 4, 2nd → 3, 3rd → 2, 4th → 1)
- Achievement points for optional weekly achievements
- Weekly and tournament standings

---

## Architecture

### Navigation

- **TabView** with 4 tabs: Dashboard, Pods, Stats, Achievements
- Each tab hosts a **NavigationStack**
- **Flow screens** (Confirm New Tournament → Add Players → Attendance) are pushed from the Dashboard stack with the tab bar hidden
- **Weekly Standings** presented as a `.sheet()`
- **Tournament Standings** presented as `.fullScreenCover()` when final
- **currentScreen** is persisted in `LeagueState` for state restoration on app launch

### State and Storage

- **SwiftData** is the sole persistence and caching layer
- **Models**: `Player`, `Achievement`, `LeagueState`
- `LeagueState` stores both persistent settings (totalWeeks, randomAchievementsPerWeek) and transient weekly state (presentPlayerIds, weeklyPoints, podHistory) via JSON-encoded `Data` properties
- **ModelContext** acts as the in-memory cache; **ModelContainer** handles persistence
- No separate cache layer—SwiftData handles both

### Business Logic

- **LeagueEngine** (`Engine/LeagueEngine.swift`) contains pure or near-pure functions for scoring, transitions, and state mutations
- Engine functions take `ModelContext`, fetch/update SwiftData models, and save
- Views/ViewModels call Engine functions rather than duplicating logic

### ViewModels

- One ViewModel per screen: `DashboardViewModel`, `ConfirmNewTournamentViewModel`, `AddPlayersViewModel`, `AttendanceViewModel`, `PodsViewModel`, `WeeklyStandingsViewModel`, `TournamentStandingsViewModel`, `StatsViewModel`, `AchievementsViewModel`
- ViewModels coordinate between Views, SwiftData, and the Engine
- Use `@Observable` macro for SwiftUI integration
- No UI code in ViewModels—they expose state and actions only

### Constants

- **AppConstants** (`Constants/AppConstants.swift`) centralizes all magic numbers:
  - `UI.minTouchTargetHeight` (44pt)
  - `League.weeksRange`, `randomAchievementsPerWeekRange`, `roundsPerWeek`, `podSize`
  - `Scoring.placementPoints(forPlace:)`, initial stats
  - `DefaultAchievement.name`, `points`, `alwaysOn`
- Engine, ViewModels, and Views reference these constants—no hardcoded literals

### Reusable Components

- **Buttons**: `PrimaryActionButton`, `SecondaryButton`, `DestructiveActionButton`
- **Controls**: `LabeledToggle`, `LabeledStepper`, `PlacementPicker`, `AchievementCheckItem`
- **Rows**: `PlayerRow` (display/removable/toggleable), `StandingsRow`, `AchievementListRow`
- **State/Hints**: `EmptyStateView`, `HintText`, `ModalActionBar`
- All components enforce 44pt minimum touch targets per iOS HIG

---

## Key Files

All paths below are relative to `ios/`:

| Path | Description |
|------|-------------|
| `project.yml` | XcodeGen project definition (Swift 6, iOS 17) |
| `CONTEXT.md` | This file – architecture and development context |
| `docs/ios-app-plan.md` | Full verbose implementation plan |
| `docs/ios-roadmap.md` | Roadmap from current state to App Store release |
| `BudgetLeagueTracker/BudgetLeagueTrackerApp.swift` | App entry point with modelContainer and bootstrap |
| `BudgetLeagueTracker/ContentView.swift` | Root TabView and navigation shell |
| `BudgetLeagueTracker/Models/` | SwiftData models: `Player`, `Achievement`, `LeagueState`, `Screen` |
| `BudgetLeagueTracker/Engine/LeagueEngine.swift` | Business logic functions (17 functions) |
| `BudgetLeagueTracker/ViewModels/` | One ViewModel per screen (9 ViewModels) |
| `BudgetLeagueTracker/Views/` | SwiftUI views for each screen (9 views) |
| `BudgetLeagueTracker/Components/` | Reusable UI components (13 components) |
| `BudgetLeagueTracker/Constants/AppConstants.swift` | Centralized constants (UI, League, Scoring, DefaultAchievement) |

---

## Data Flow

1. **User action** in View (button tap, toggle change, etc.)
2. View calls **ViewModel** method
3. ViewModel calls **LeagueEngine** function with `ModelContext`
4. Engine fetches current state from SwiftData, computes updates, writes back to models
5. Engine calls `context.save()`
6. SwiftUI automatically updates Views via `@Query` or `@Observable` bindings

---

## Specs and Wireframes

- `specs/` folder contains the source of truth for behavior
- `wireframes/` folder contains iOS UX mockups (inset grouped lists, 44pt targets, switches/steppers)

---

## What's Left for App Store

See `docs/ios-roadmap.md` for the full roadmap with phases, tasks, and timeline.

**Summary:**
1. Build & smoke test on macOS/Xcode
2. Testing (unit, UI, snapshots)
3. Accessibility audit (VoiceOver, Dynamic Type)
4. Theming & polish (light/dark mode)
5. App icon & launch screen
6. App Store preparation (metadata, screenshots)
7. Beta testing (TestFlight)
8. App Store release

**Future extensions (R&D):** Apple Watch, Widgets, Live Activities, iCloud Sync, iPad optimization

---

## Running the Project

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) if not already installed
2. Navigate to `ios/` directory
3. Run `xcodegen` to generate `BudgetLeagueTracker.xcodeproj`
4. Open the project in Xcode 15+ and build for iOS 17+ device or simulator
