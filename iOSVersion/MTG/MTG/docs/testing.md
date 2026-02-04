# Budget League Tracker — Testing

## Overview

The app uses a layered test strategy:

- **Unit tests** — Models, engines, ViewModels (Swift Testing)
- **Integration tests** — Tournament lifecycle, edit-round flow, scoring
- **Snapshot tests** — Components and screens (Swift Snapshot Testing)
- **UI tests** — Flows, screens, accessibility (XCTest)

Data-flow tests (engine logic and ViewModels that read/write context) are prioritized.

## How to run tests

- **Xcode:** Product → Test (⌘U), or run a specific test target/suite.
- **Command line:**  
  `xcodebuild test -scheme BudgetLeagueTracker -destination 'platform=iOS Simulator,name=iPhone 17'`

## Test layout

### BudgetLeagueTrackerTests

| Folder        | Contents                                                                 |
|---------------|---------------------------------------------------------------------------|
| Constants     | AppConstantsTests                                                         |
| Engine        | LeagueEngineTests, StatsEngineTests, AchievementStatsEngineTests         |
| Models        | AchievementTests, ChartDataTests, GameResultTests, LeagueStateTests, PlayerTests, ScreenTests, TournamentTests |
| ViewModels    | AchievementsViewModelTests, AddPlayersViewModelTests, AttendanceViewModelTests, ConfirmNewTournamentViewModelTests, DashboardViewModelTests, EditLastRoundViewModelTests, NewTournamentViewModelTests, PlayerDetailViewModelTests, PlayersViewModelTests, PodsViewModelTests, StatsViewModelTests, TournamentDetailViewModelTests, TournamentStandingsViewModelTests, TournamentsViewModelTests |
| Integration   | EditRoundSystemTests, ScoringIntegrationTests, TournamentLifecycleTests   |
| Components    | ComponentBehaviorTests, ComponentSnapshotTests (+ __Snapshots__)           |
| Screens       | ScreenSnapshotTests (+ __Snapshots__)                                     |
| Helpers       | TestFixtures, TestHelpers                                                 |
| (root)        | SnapshotTestConfiguration                                                 |

### BudgetLeagueTrackerUITests

| Folder        | Contents                                                                 |
|---------------|---------------------------------------------------------------------------|
| Flows         | CreateTournamentFlowTests, TournamentCompletionFlowTests, WeeklyRoundFlowTests |
| Screens       | AchievementsScreenTests, TournamentsScreenTests                          |
| Accessibility | AccessibilityAuditTests                                                 |
| Helpers       | UITestHelpers                                                            |

## What’s tested

- **Models:** LeagueState, Tournament, Player, Achievement, GameResult, Screen, ChartData types (PlayerPointsData, AchievementEarnData, PlacementData, etc.), AppConstants
- **Engines:** LeagueEngine, StatsEngine, AchievementStatsEngine
- **ViewModels:** All listed above (including AddPlayers, ConfirmNewTournament, Dashboard)
- **Integration:** Tournament lifecycle, edit-round system, scoring integration
- **Components/Screens:** Snapshot and behavior tests for shared components and main screens
- **UI:** Create tournament, tournament completion, weekly round flows; tours and achievements screens; accessibility audit

## What’s left / not covered

- **ContentView** — Navigation/routing from app state (typically exercised by UI tests).
- **BudgetLeagueTrackerApp** — App entry point; no dedicated unit tests.
- **Full E2E** — Beyond existing UI flows; additional edge cases as needed.

## Dependencies

- **TestHelpers** — `bootstrappedContext()`, `contextWithTournament()`, `fetchLeagueState()`, `fetchActiveTournament()`, `fetchAll()`, etc.
- **TestFixtures** — Player, Achievement, Tournament, GameResult, LeagueState, and context-insert helpers.
- **SnapshotTestConfiguration** — Shared config for component and screen snapshot tests.

## Failing tests and snapshot maintenance

- **TournamentDetailViewModel “goToAttendance”** — Fixed. The implementation presents the attendance *sheet* via `showAttendance = true` and does not set `LeagueState.screen` to `.attendance`. The test now asserts `showAttendance == true` and `activeTournamentId` is set.
- **Snapshot tests (Component Snapshot Tests, Screen Snapshot Tests)** — These compare rendered views to stored PNGs in `__Snapshots__/`. They can fail when the simulator, OS version, or rendering changes (fonts, layout, etc.). To refresh reference images: set `SnapshotTestConfiguration.record = true` in [SnapshotTestConfiguration.swift](BudgetLeagueTrackerTests/SnapshotTestConfiguration.swift), run the snapshot tests (they will write new images), then set `record = false` again and commit the updated `__Snapshots__/` files.
