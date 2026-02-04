# Budget League Tracker – SwiftUI iOS App Plan (Verbose)

This document is the full, verbose implementation plan for the **native iOS app** (SwiftUI only; no cross-platform or web): XcodeGen, Swift 6, SwiftData, and a dedicated step with examples for each view. **Focus: native iOS** — use SwiftUI `View` types, iOS Human Interface Guidelines (HIG), system list styles (e.g. `.insetGrouped`), 44pt minimum touch targets, Dynamic Type–friendly text, and native controls (`Button`, `Toggle`, `Stepper`, `Picker`). Testing is out of scope for the plan; reusable components are designed for snapshot/unit tests. Data is stored and cached via SwiftData.

---

## 1. Project setup (XcodeGen, Swift 6)

**Goal**: Generate the Xcode project from a single `project.yml` so the project is reproducible and avoids `.xcodeproj` merge conflicts.

**Location**: New directory `ios/` at the repo root (sibling to `react-app/`, `specs/`, `wireframes/`).

**Steps**:

1. Create `ios/project.yml` with:
   - **name**: BudgetLeagueTracker (or BudgetLeagueTracker-iOS).
   - **options**: `bundleIdPrefix`, `deploymentTarget` iOS 17, `xcodeVersion` if desired.
   - **settings**: `SWIFT_VERSION: "6.0"`, `SWIFT_STRICT_CONCURRENCY` if needed for Swift 6.
   - **targets**:
     - One target only: **BudgetLeagueTracker** (type: application).
     - **sources**: `BudgetLeagueTracker/` (include all Swift files; use `path` and `type: group` or equivalent so new files are picked up).
     - **settings**: Same Swift version; iOS 17 minimum; enable SwiftData (no extra frameworks beyond default).
   - No test target (testing deferred).

2. Create folder structure under `ios/`:
   - `BudgetLeagueTracker/` (app source).
   - Subfolders: `Models/`, `Engine/`, `Views/`, `ViewModels/` (one ViewModel per screen; coordinates View + SwiftData + Engine; see §4.1), `Components/` (reusable SwiftUI views: buttons, rows, empty state, etc.), `Constants/` (AppConstants: UI, League, Scoring, DefaultAchievement; no magic numbers; see §4.2), and optionally `State/` or keep state in a single store type.

3. Run `xcodegen` from `ios/` (e.g. `cd ios && xcodegen`) to generate `BudgetLeagueTracker.xcodeproj`. Optionally add the generated project to `.gitignore` if you prefer to regenerate on each pull.

**Example `project.yml` (minimal)**:

```yaml
name: BudgetLeagueTracker
options:
  bundleIdPrefix: com.example
  deploymentTarget:
    iOS: "17.0"
settings:
  SWIFT_VERSION: "6.0"
targets:
  BudgetLeagueTracker:
    type: application
    platform: iOS
    sources:
      - path: BudgetLeagueTracker
        type: group
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.example.BudgetLeagueTracker
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
```

Adjust `bundleIdPrefix` and paths to match your convention.

---

## 2. SwiftData models and storage

**Goal**: Persist and cache all league data (players, achievements, league state, current week state, pod history) using SwiftData. The ModelContext is the cache; the ModelContainer is the store.

**Models to define** (see [specs/03-data-and-scoring.md](../specs/03-data-and-scoring.md)):

- **Player** `@Model`
  - `id: String` (e.g. `UUID().uuidString` when creating).
  - `name: String`.
  - `placementPoints: Int`, `achievementPoints: Int`, `wins: Int`, `gamesPlayed: Int`.
  - All numeric fields start at 0; on "Start New Tournament" they are either deleted and recreated or reset to 0.

- **Achievement** `@Model`
  - `id: String`, `name: String`, `points: Int`, `alwaysOn: Bool`.
  - Seed one default achievement ("First Blood", 1 pt, alwaysOn: false) when the Achievement store is empty (e.g. in app init or first launch).

- **LeagueState** `@Model` (single instance)
  - `started: Bool`, `currentWeek: Int`, `totalWeeks: Int`, `currentRound: Int`, `randomAchievementsPerWeek: Int`, `achievementsOnThisWeek: Bool`, `currentScreen: String` (raw value of Screen enum).
  - Optionally: `presentPlayerIds: [String]` (stored as transformable or encoded JSON), `weeklyPointsByPlayerJSON: Data?`, `activeAchievementIds: [String]`, `podHistorySnapshotsJSON: Data?` to hold current week and undo stack (Option A from the prior plan). Alternatively use separate entities for present players, weekly points, and pod snapshots (Option B).

**Persistence and caching**:

- In the app entry point (e.g. `@main` struct), attach `.modelContainer(for: [Player.self, Achievement.self, LeagueState.self])` so SwiftUI injects the shared ModelContainer and ModelContext into the environment.
- All reads: use `@Query` in views or fetch from `modelContext` when you need a single LeagueState or filtered players.
- All writes: mutate model instances and call `modelContext.save()` (or rely on autosave). No separate "cache" layer; the context is the cache.

**Example Player model**:

```swift
import Foundation
import SwiftData

@Model
final class Player {
    var id: String
    var name: String
    var placementPoints: Int
    var achievementPoints: Int
    var wins: Int
    var gamesPlayed: Int

    init(id: String = UUID().uuidString, name: String, placementPoints: Int = 0, achievementPoints: Int = 0, wins: Int = 0, gamesPlayed: Int = 0) {
        self.id = id
        self.name = name
        self.placementPoints = placementPoints
        self.achievementPoints = achievementPoints
        self.wins = wins
        self.gamesPlayed = gamesPlayed
    }
}
```

**Example LeagueState (Option A – current week + pod history in same model)**:

- Add attributes such as `presentPlayerIdsData: Data?` (JSON-encoded `[String]`), `weeklyPointsJSON: Data?`, `activeAchievementIdsData: Data?`, `podHistoryData: Data?`. On read, decode; on write, encode and assign. This keeps one "document" for the current week and undo stack.

**Bootstrap**:

- On first launch (or when LeagueState fetch returns nil), create one LeagueState with defaults (started: false, currentWeek: 0, totalWeeks: 6, currentRound: 1, randomAchievementsPerWeek: 2, achievementsOnThisWeek: true, currentScreen: "dashboard"). If Achievement count is 0, insert the default "First Blood" achievement.

---

## 3. Engine (business logic)

**Goal**: Keep scoring and flow transitions in pure or mostly pure functions so the SwiftUI layer only reads/writes SwiftData and calls the engine. Mirrors [react-app/src/state.ts](../react-app/src/state.ts).

**Functions to implement** (names and behavior aligned with spec):

- `startNewTournament(context)` or equivalent: Delete all Player rows (or reset their stats), reset LeagueState to defaults, clear presentPlayerIds and weekly points and pod history, set currentScreen to addPlayers. Persist.
- `addPlayer(context, name)`: Insert new Player with zeroed stats.
- `removePlayer(context, id)`: Delete player by id.
- `startTournament(context, totalWeeks, randomPerWeek)`: Clamp weeks to `AppConstants.League.weeksRange`, random to `AppConstants.League.randomAchievementsPerWeekRange`; set league.started = true, currentWeek = 1, currentRound = 1; roll active achievements for week 1; set currentScreen = attendance.
- `confirmAttendance(context, presentIds, achievementsOnThisWeek)`: Set presentPlayerIds = presentIds, reset weeklyPointsByPlayer for all players, set achievementsOnThisWeek, currentRound = 1, currentScreen = pods.
- `addWeeklyPlayer(context, name)`: Same as addPlayer and add that player’s id to presentPlayerIds and weeklyPointsByPlayer.
- `generatePodsForRound(players, currentRound, weeklyPointsByPlayer)`: Round 1: shuffle then split into groups of `AppConstants.League.podSize`; later rounds: sort by weekly total then split. Return `[[Player]]` (or array of player ids per pod).
- `savePod(context, group, placements, achievementChecks)`: Compute placement points via `AppConstants.Scoring.placementPoints(forPlace:)` (1→4, 2→3, 3→2, 4→1); update each player’s placementPoints, achievementPoints, wins, gamesPlayed and weekly points; push snapshot to pod history.
- `undoLastPod(context)`: Pop last snapshot; restore affected players’ stats and weekly points from snapshot.
- `nextRound(context)`: If currentRound < `AppConstants.League.roundsPerWeek`, increment currentRound; else set currentScreen = weeklyStandings.
- `closeWeeklyStandings(context)`: If currentWeek >= totalWeeks, set currentScreen = tournamentStandings; else increment currentWeek, currentRound = 1, roll new active achievements, currentScreen = attendance.
- `exitWeeklyStandings(context)`: Set currentScreen = pods.
- `closeTournamentStandings(context)`: Set currentScreen = dashboard.
- `rollActiveAchievements(achievements, randomPerWeek)`: Always-on + random sample of non–always-on; return [Achievement].
- `addAchievement(context, name, points, alwaysOn)`, `removeAchievement(context, id)`.
- `setScreen(context, screen)`.

**Example**: `savePod` should take the current league state, the pod’s players, a dictionary of placement (playerId → 1...4), and the list of (playerId, achievementId) checks; then compute deltas, update Player and weekly point state, and append one snapshot to pod history. The SwiftUI view will call this with data from SwiftData and then write the results back into the models.

---

## 4. ViewModel and Constants standards (SwiftData-friendly, no magic numbers)

**Goal**: One standard for **ViewModels** (how views talk to SwiftData and the Engine) and one for **Constants** (centralize all numeric and string literals so SwiftData, Engine, and UI stay consistent and testable).

### 4.1 ViewModel standard

- **Naming**: One ViewModel per screen (or per flow). Name: `{Screen}ViewModel`, e.g. `DashboardViewModel`, `AddPlayersViewModel`, `AttendanceViewModel`, `PodsViewModel`, `WeeklyStandingsViewModel`, `TournamentStandingsViewModel`, `StatsViewModel`, `AchievementsViewModel`. For flow-only screens that share little logic, a single flow ViewModel (e.g. `LeagueFlowViewModel`) is optional; prefer one ViewModel per view when the view has distinct actions.
- **Responsibility**: The ViewModel owns the bridge between the **View** and **SwiftData + Engine**. It should:
  - **Read**: Hold or receive `ModelContext` (and optionally `@Query` results or fetched LeagueState/players/achievements). Expose to the view only what the view needs (e.g. league.started, currentWeek, list of players, presentPlayerIds).
  - **Actions**: Expose methods that the view calls (e.g. `startNewTournament()`, `addPlayer(name:)`, `confirmAttendance(presentIds:achievementsOnThisWeek:)`). Inside those methods, the ViewModel fetches current state from SwiftData, calls the **Engine** (pure functions) with that state, then applies the returned or side-effecting updates back to SwiftData (insert/update/delete) and calls `modelContext.save()`.
  - **No UI**: ViewModel does not import SwiftUI for layout; it may use Swift types (String, Int, Bool, arrays) and SwiftData types (ModelContext, Model). This keeps the ViewModel testable with a mock or in-memory context.
- **Lifecycle**: ViewModels can be created per view (e.g. `@StateObject` or `@Observable` in the view) and receive `ModelContext` via initializer or environment. For a single shared store, one root ViewModel or a shared observable that holds the context and exposes screen-specific state is also valid.
- **SwiftData**: ViewModel uses `ModelContext` to fetch/insert/update/delete. Prefer fetching in the ViewModel (or passing in fetched data) so the Engine stays pure (takes plain structs or model IDs and returns updates); the ViewModel then applies those updates to SwiftData models. Alternatively, the Engine can take `ModelContext` and mutate directly if you prefer; either way, the **standard** is: ViewModel is the only place that coordinates View + SwiftData + Engine.
- **Testing**: ViewModels can be unit-tested by injecting a ModelContext (e.g. in-memory container) and asserting that after calling a method, the context’s state matches expectations. Use **Constants** (see below) so tests and app share the same numeric/string values.

**Example**: `AddPlayersViewModel` has `func addPlayer(name: String)` which inserts a new `Player` with `name` and zeroed stats (using `Constants.Scoring.initialPlacementPoints`, etc.), then `modelContext.save()`. `func startTournament(totalWeeks: Int, randomPerWeek: Int)` clamps to `Constants.League.weeksRange` and `Constants.League.randomAchievementsPerWeekRange`, then calls Engine’s `startTournament(context, totalWeeks, randomPerWeek)` and saves.

### 4.2 Constants standard

- **Location**: One place for all magic numbers and literal strings. Use an enum or struct namespace so they are discoverable and avoid typos. Suggested: `AppConstants` or `LeagueConstants` in a file `Constants.swift` under `BudgetLeagueTracker/Constants/` (or `Support/Constants.swift`).
- **What to centralize** (from [specs/03-data-and-scoring.md](../specs/03-data-and-scoring.md) and iOS HIG):

  - **UI / Accessibility**
    - Minimum touch target height: `44` (pt) — use in Components (buttons, rows). e.g. `AppConstants.UI.minTouchTargetHeight`.
    - Any other layout numbers used in multiple places (e.g. list row height, spacing) if they become repeated.

  - **League / Tournament**
    - Weeks range: minimum `1`, maximum `99` (clamp total weeks and validate input). e.g. `AppConstants.League.weeksRange` (closed range) or `weeksMin`/`weeksMax`.
    - Random achievements per week range: minimum `0`, maximum `99`. e.g. `AppConstants.League.randomAchievementsPerWeekRange` or `randomAchievementsMin`/`randomAchievementsMax`.
    - Default total weeks when creating new league: e.g. `6`.
    - Default random achievements per week: e.g. `2`.
    - Rounds per week: `3` (max round index 1, 2, 3). e.g. `AppConstants.League.roundsPerWeek`.
    - Pod size: `4` (players per pod). e.g. `AppConstants.League.podSize`.

  - **Scoring (placement points)**
    - Map placement (1–4) to points: 1st → 4, 2nd → 3, 3rd → 2, 4th → 1. e.g. `AppConstants.Scoring.placementPoints(forPlace: Int) -> Int` or a dictionary `placementToPoints: [1: 4, 2: 3, 3: 2, 4: 1]`. Use in Engine (e.g. `savePod`) and anywhere that displays or validates placement.

  - **Scoring (defaults)**
    - Initial player stats: placement points `0`, achievement points `0`, wins `0`, games played `0`. e.g. `AppConstants.Scoring.initialPlacementPoints`, `initialAchievementPoints`, `initialWins`, `initialGamesPlayed`.
    - Default achievement (seed): name `"First Blood"`, points `1`, alwaysOn `false`. e.g. `AppConstants.DefaultAchievement.name`, `.points`, `.alwaysOn`.

  - **Persistence / SwiftData**
    - If you use a single LeagueState and need default values for a new league: e.g. `AppConstants.League.defaultCurrentWeek`, `defaultCurrentRound`, `defaultAchievementsOnThisWeek`. Use when creating or resetting LeagueState so SwiftData and Engine stay in sync.

  - **Screen / Navigation**
    - Screen raw values (if you use an enum and persist `currentScreen`): e.g. `Screen.dashboard.rawValue` — consider defining the enum in one place and using it in LeagueState and ViewModels so there are no string literals scattered.

- **Usage**: Engine, ViewModels, and Views should **only** use these constants (no literal `44`, `4`, `3`, `1...99` in business logic or layout). This makes it easy to change ranges or scoring in one place and keeps SwiftData defaults consistent with the spec.

**Example**: `Constants.swift` (structure only):

```swift
enum AppConstants {
    enum UI {
        static let minTouchTargetHeight: CGFloat = 44
    }
    enum League {
        static let weeksRange = 1...99
        static let randomAchievementsPerWeekRange = 0...99
        static let defaultTotalWeeks = 6
        static let defaultRandomAchievementsPerWeek = 2
        static let roundsPerWeek = 3
        static let podSize = 4
    }
    enum Scoring {
        static func placementPoints(forPlace place: Int) -> Int {
            switch place {
                case 1: return 4
                case 2: return 3
                case 3: return 2
                case 4: return 1
                default: return 0
            }
        }
        static let initialPlacementPoints = 0
        static let initialAchievementPoints = 0
        static let initialWins = 0
        static let initialGamesPlayed = 0
    }
    enum DefaultAchievement {
        static let name = "First Blood"
        static let points = 1
        static let alwaysOn = false
    }
}
```

- **Testing**: Unit tests for Engine and ViewModels should use the same `AppConstants` so that if you change a constant, tests that depend on it can be updated in one place or will fail and remind you.

---

## 5. Navigation and app shell (native iOS)

**Goal**: Tab bar on Dashboard, Pods, Stats, Achievements; flow stack for Dashboard → Confirm New Tournament → Add Players → Attendance → Pods; modals for Weekly Standings (sheet) and Tournament Standings (fullScreenCover when final).

**Implementation**:

- Root view: Either a `TabView` with four tabs (Dashboard, Pods, Stats, Achievements), each tab hosting a `NavigationStack`, and the "selected tab" and "current screen" driven by LeagueState.currentScreen (or a wrapper that maps screen to tab + stack state). When currentScreen is a flow-only screen (confirmNewTournament, addPlayers, attendance), show that screen in the appropriate stack (e.g. from Dashboard tab) and hide the tab bar. When currentScreen is weeklyStandings or tournamentStandings, present the modal and hide the tab bar.
- Flow: From Dashboard, "Start New Tournament" pushes or sets screen to confirmNewTournament. Confirm New Tournament has Cancel (→ dashboard) and Confirm (→ addPlayers). Add Players has Cancel (→ dashboard) and Start Tournament (→ attendance). Attendance has Confirm Attendance (→ pods). Pods has Next Round (→ next round or weeklyStandings). Weekly Standings: Continue (→ attendance or tournamentStandings) and Exit (→ pods). Tournament Standings: Close (→ dashboard).
- Persist currentScreen in LeagueState so on launch the app can restore and show the same screen (e.g. attendance for week 2).

---

## 6. View-by-view steps with examples

### 6.1 Dashboard

**Purpose**: Entry point; show league title and current week label when league has started; primary action to start a new tournament.

**Layout** (from [wireframes/dashboard.md](../wireframes/dashboard.md)):

- Navigation bar: title "Budget League Tracker" (or app name); subtitle or trailing "Week N" when `league.started` is true.
- Tab bar: visible (Dashboard, Pods, Stats, Achievements).
- Content: One prominent primary button: "Start New Tournament".

**Data**: Read LeagueState (e.g. single fetch or @Query for the one instance) to get `started` and `currentWeek` for the label.

**Actions**:

- "Start New Tournament" → set currentScreen to confirmNewTournament (or push Confirm New Tournament in the stack). Persist.

**Example (SwiftUI)**:

- `DashboardView`: `@Query` or injected LeagueState; show `Text("Week \(league.currentWeek)")` when `league.started`; `Button("Start New Tournament") { setScreen(.confirmNewTournament) }` with `.buttonStyle(.borderedProminent)`.

---

### 6.2 Confirm New Tournament

**Purpose**: Confirm before clearing all data; prevent accidental loss.

**Layout**:

- Navigation bar: title "New Tournament"; left button "Cancel" (secondary).
- Tab bar: hidden (flow-only).
- Content: Short message that all data will be erased and the action is not reversible; primary destructive button "Yes, Start New Tournament"; secondary "Cancel".

**Data**: No additional data; uses LeagueState and all SwiftData models for the reset.

**Actions**:

- Cancel: set currentScreen to dashboard; persist.
- Yes, Start New Tournament: call engine’s startNewTournament (clear/reset all players, achievements if desired, league state, present players, weekly points, pod history); set currentScreen to addPlayers; persist.

**Example**:

- `ConfirmNewTournamentView`: `NavigationStack` with toolbar Cancel; `Text("This will erase all current data. Start fresh?"); Button("Yes, Start New Tournament", role: .destructive) { startNewTournament(); setScreen(.addPlayers) }; Button("Cancel") { setScreen(.dashboard) }`.

---

### 6.3 Add Players

**Purpose**: Configure player list and league parameters (total weeks, random achievements per week) before starting the tournament.

**Layout**:

- Navigation bar: title "Add Players"; left "Cancel".
- Tab bar: hidden.
- Content (inset grouped list):
  - Section "Players": list of players with name and remove control; "Add player" row with text field and "Add" button.
  - Section "League settings": stepper or number field for "Number of weeks", stepper for "Random achievements per week".
  - Primary button "Start Tournament" at bottom.

**Data**: `@Query` all Players; read LeagueState for totalWeeks and randomAchievementsPerWeek (and use local @State for editing until Start).

**Actions**:

- Add player: insert new Player with trimmed name, zero stats; save context.
- Remove player: delete Player by id; save.
- Change weeks/random: update local state; on Start Tournament, clamp and write to LeagueState.
- Start Tournament: require at least one player (disable button or show alert when 0); call startTournament(context, weeks, random); persist.
- Cancel: set currentScreen to dashboard (document that uncommitted edits are discarded).

**Example**:

- `AddPlayersView`: `@Query(sort: \Player.name) var players`; `@State private var totalWeeks = 6`; `@State private var randomAchievementsPerWeek = 2`; `@State private var newName = ""`. List with Section("Players") { ForEach(players) { p in HStack { Text(p.name); Spacer(); Button(role: .destructive) { removePlayer(p) } label: { Image(systemName: "trash") } } }; HStack { TextField("Name", text: $newName); Button("Add") { addPlayer(newName); newName = "" } } }; Section("League settings") { Stepper("Weeks: \(totalWeeks)", value: $totalWeeks, in: 1...99); Stepper("Random achievements/week: \(randomAchievementsPerWeek)", value: $randomAchievementsPerWeek, in: 0...99) }; Button("Start Tournament") { startTournament(totalWeeks, randomAchievementsPerWeek) }.disabled(players.isEmpty)`.

---

### 6.4 Attendance

**Purpose**: For the current week, record who is present, whether achievements count, and optionally add a new player (who joins the league and is present this week).

**Layout**:

- Navigation bar: title "Attendance – Week N".
- Tab bar: hidden.
- Content (inset grouped list):
  - Section "This week": Switch "Count achievements this week".
  - Section "Players": One row per player with name and Switch (Present/Absent).
  - "Add player this week": text field + Add; new player is added to global list and marked present.
  - Primary button "Confirm Attendance".

**Data**: `@Query` players; LeagueState for currentWeek and achievementsOnThisWeek; local @State for present/absent per player id and for "Count achievements this week" and for new player name.

**Actions**:

- Toggle present/absent: update local dictionary or set.
- Toggle "Count achievements this week": update local state; on confirm, write to LeagueState.achievementsOnThisWeek.
- Add player this week: insert Player, add id to present list (and to LeagueState.presentPlayerIds when confirming), add to weeklyPointsByPlayer with zeros.
- Confirm Attendance: require at least one present (disable button or alert when 0); call confirmAttendance(context, presentIds, achievementsOnThisWeek); persist; set screen to pods.

**Example**:

- `AttendanceView`: `@State private var present: [String: Bool]` (init from all players as true); `@State private var achievementsOnThisWeek = true`; `@State private var newPlayerName = ""`. List: Section("This week") { Toggle("Count achievements this week", isOn: $achievementsOnThisWeek) }; Section("Players") { ForEach(players) { p in Toggle(p.name, isOn: binding(for: p.id)) } }; add row with TextField + Button "Add"; Button("Confirm Attendance") { confirmAttendance(presentIds, achievementsOnThisWeek) }.disabled(presentIds.isEmpty)`.

---

### 6.5 Pods

**Purpose**: Group present players into pods for the current round; record placement (1–4) and achievements per player; save (and lock) each pod; undo last saved pod; advance to next round or to Weekly Standings.

**Layout**:

- Navigation bar: title "Pods – Round N".
- Tab bar: visible.
- Toolbar: "Generate Pods" (primary when no pods), "Next Round", "Undo Last Saved Pod" (disabled when no history).
- Content: One card/group per pod. Per pod: for each player, name, placement picker (1–4), and if achievements on this week, checkboxes for each active achievement; "Save Pod" button. Once saved, pod is locked (no edits).

**Data**: `@Query` players; LeagueState for currentRound, achievementsOnThisWeek, presentPlayerIds, weeklyPointsByPlayer, activeAchievementIds, podHistory; local @State for generated pods (array of arrays of Player or ids), placements (playerId → 1...4), achievement checks (playerId, achievementId), and which pod indices are saved/locked.

**Actions**:

- Generate Pods: call generatePodsForRound with present players and current round and weekly points; set local pods state; clear placements and achievement checks.
- Per-player placement: update local placements state.
- Per-player achievement check: toggle in local achChecks array.
- Save Pod: call savePod(context, group, placements, achChecks); mark that pod index as saved; clear local placements/checks for that pod only if needed (or just hide controls when saved).
- Undo Last Saved Pod: call undoLastPod(context); clear local pods and mark all pods unsaved so user can regenerate.
- Next Round: call nextRound(context); if round < 3, increment round and clear local pods (user will Generate again); if round == 3, currentScreen becomes weeklyStandings and sheet is presented.

**Example**:

- `PodsView`: `@State private var pods: [[Player]] = []`; `@State private var placements: [String: Int] = [:]`; `@State private var achChecks: [(playerId: String, achievementId: String)] = []`; `@State private var savedPodIndices: Set<Int> = []`. Toolbar: Button("Generate Pods") { pods = generatePodsForRound(...) }.disabled(presentPlayers.isEmpty); Button("Next Round") { nextRound() }; Button("Undo Last Saved Pod") { undoLastPod(); pods = []; savedPodIndices = [] }.disabled(podHistory.isEmpty). ForEach(Array(pods.enumerated()), id: \.offset) { index, group in PodCard(players: group, placements: $placements, achChecks: $achChecks, saved: savedPodIndices.contains(index), achievementsOn: league.achievementsOnThisWeek, activeAchievements: activeAchievements) { savePod(group, placements, achChecks); savedPodIndices.insert(index) } }`.

---

### 6.6 Weekly Standings

**Purpose**: Show current week ranking (present players sorted by weekly points); Continue to next week or final standings; Exit to return to Pods without advancing.

**Layout**:

- Presented as **sheet** (drag to dismiss).
- Navigation bar: title "Week N Standings".
- Content: List of present players sorted by (weeklyPlacementPoints + weeklyAchievementPoints) descending; each row shows rank, name, total weekly points, placement points, achievement points.
- Buttons: "Continue to Next Week" (primary), "Exit Standings" (secondary).

**Data**: LeagueState (currentWeek, totalWeeks, presentPlayerIds); weeklyPointsByPlayer from LeagueState or derived; list of present Players from @Query filtered by presentPlayerIds.

**Actions**:

- Continue: call closeWeeklyStandings(context); if not final week, go to attendance; if final week, present Tournament Standings (fullScreenCover) and set currentScreen to tournamentStandings.
- Exit Standings: call exitWeeklyStandings(context); dismiss sheet; currentScreen = pods.

**Example**:

- `WeeklyStandingsView`: `@Environment(\.dismiss) var dismiss`. Compute sorted present players by weekly total. `List { ForEach(Array(sorted.enumerated()), id: \.element.id) { index, p in HStack { Text("#\(index + 1)"); Text(p.name); Text("\(totalWeeklyPoints(p)) pts") } } }`; `Button("Continue to Next Week") { closeWeeklyStandings(); if isFinalWeek { showTournamentStandings = true }; dismiss() }`; `Button("Exit Standings") { exitWeeklyStandings(); dismiss() }`.

---

### 6.7 Tournament Standings

**Purpose**: Show cumulative standings (all players, sorted by total tournament points); Close returns to Dashboard.

**Layout**:

- Presented as **fullScreenCover** when final (after last week’s Continue); otherwise could be sheet or embedded depending on spec.
- Navigation bar: title "Final Rankings" (when final) or "Tournament Rankings"; Close button.
- Content: List of all players sorted by (placementPoints + achievementPoints) descending; each row: rank, name, total points, placement points, achievement points, wins.
- Close button (or in nav bar).

**Data**: `@Query` all Players; LeagueState for currentWeek and totalWeeks to decide "final" vs not.

**Actions**:

- Close: call closeTournamentStandings(context); set currentScreen to dashboard; dismiss.

**Example**:

- `TournamentStandingsView`: `@Query(sort: \Player.placementPoints) var players` (or sort in memory by total); `let sorted = players.sorted { ($0.placementPoints + $0.achievementPoints) > ($1.placementPoints + $1.achievementPoints) }`. List with rank, name, totals; `Button("Close") { closeTournamentStandings(); dismiss() }`.

---

### 6.8 Stats

**Purpose**: Read-only summary of each player’s cumulative performance (wins, placement points, achievement points).

**Layout**:

- Navigation bar: title "Stats".
- Tab bar: visible.
- Content: Inset grouped list; one row per player with name, wins, placement points, achievement points.

**Data**: `@Query(sort: \Player.name) var players` (or sort by total points).

**Actions**: None (read-only).

**Example**:

- `StatsView`: `@Query var players`; `List(players) { p in VStack(alignment: .leading) { Text(p.name).font(.headline); Text("Wins: \(p.wins), Placement: \(p.placementPoints), Achievements: \(p.achievementPoints)") } }`. Empty state: if players.isEmpty { Text("No stats yet. Add players and run pods.") }.

---

### 6.9 Achievements

**Purpose**: Manage achievements: add (name, points, always on), remove; list all with name, points, and "Always on" switch.

**Layout**:

- Navigation bar: title "Achievements".
- Tab bar: visible.
- Content (inset grouped list): Section "Achievements": one row per achievement – name, points, Toggle "Always on", remove control. Section "Add achievement": name field, stepper for points, Toggle "Always on", "Add" button.

**Data**: `@Query` achievements; local @State for new name, points, alwaysOn.

**Actions**:

- Toggle "Always on" on existing achievement: update achievement.alwaysOn; save.
- Remove: delete achievement; save.
- Add: insert Achievement with name, points, alwaysOn; save; clear form.

**Example**:

- `AchievementsView`: `@Query(sort: \Achievement.name) var achievements`; `@State private var newName = ""`; `@State private var newPoints = 1`; `@State private var newAlwaysOn = false`. List: Section("Achievements") { ForEach(achievements) { a in HStack { Text(a.name); Text("\(a.points) pts"); Toggle("Always on", isOn: binding(a)); Button(role: .destructive) { removeAchievement(a) } } }; Section("Add achievement") { TextField("Name", text: $newName); Stepper("Points: \(newPoints)", value: $newPoints, in: 0...99); Toggle("Always on", isOn: $newAlwaysOn); Button("Add") { addAchievement(newName, newPoints, newAlwaysOn); newName = ""; newPoints = 1; newAlwaysOn = false } } }`.

---

## 7. Reusable top-level components (native iOS / SwiftUI; spec-driven, minimize duplication + maximize testability)

**Native iOS focus**: All components are SwiftUI `View` structs for iOS only. Use system APIs: `List` with `.listStyle(.insetGrouped)`, `Button` with `.buttonStyle(.borderedProminent)` / `.bordered` / `.borderless`, `Toggle`, `Stepper`, `Picker`; enforce **44pt minimum touch targets** via `.frame(minHeight: 44)` or `contentShape`; support **Dynamic Type** with `Text(…).font(.body)` (or `.headline` for titles); add `.accessibilityLabel(_:)` and `.accessibilityHint(_:)` where needed. Align with [specs/02-views-and-flows.md](../specs/02-views-and-flows.md) (iOS-style UI), [specs/07-ui-states-and-edge-cases.md](../specs/07-ui-states-and-edge-cases.md), and [wireframes/README.md](../wireframes/README.md). Create these **reusable SwiftUI views** first; each is used in multiple screens and is easy to unit- or snapshot-test in isolation.

### 7.1 Action buttons (spec: primary, secondary, destructive; iOS 44pt touch targets)

- **PrimaryActionButton** (SwiftUI `View`)  
  - `Button(title, action: …).buttonStyle(.borderedProminent).frame(maxWidth: .infinity, minHeight: 44)` (or in a `List` row, ensure 44pt tap area). Optional `isDisabled: Bool`; optional `accessibilityLabel`. Use `.font(.body)` so label scales with Dynamic Type.  
  - **Used in**: Dashboard, Add Players, Attendance, Pods (Generate, Save, Next Round), Confirm New Tournament (destructive variant), Weekly Standings (Continue), Tournament Standings (Close).  
  - **Testing**: Snapshot; verify label, disabled state, accessibility label.

- **SecondaryButton** (SwiftUI `View`)  
  - `Button(title, action: …).buttonStyle(.bordered).frame(minHeight: 44)`; optional `.accessibilityLabel`.  
  - **Used in**: Confirm New Tournament, Add Players, Attendance, Weekly Standings.  
  - **Testing**: Snapshot; accessibility.

- **DestructiveActionButton** (SwiftUI `View`)  
  - `Button(title, role: .destructive, action: …).frame(minHeight: 44)`; optional `.accessibilityLabel`.  
  - **Used in**: Confirm New Tournament only.  
  - **Testing**: Snapshot; role/accessibility.

**Rationale**: One place for iOS button style and 44pt minimum; all primary/secondary/destructive actions go through these. Tests ensure consistency and accessibility.

### 7.2 Inset grouped list section (spec: inset grouped lists, section headers; native List)

- **InsetGroupedSection** (SwiftUI `View` or standard pattern)  
  - Use `List { Section(header: Text(header)) { content } }.listStyle(.insetGrouped)` everywhere for list-based screens. Optionally a small helper: `struct InsetGroupedSection<Content: View>: View` that wraps `Section(header: Text(header)) { content }` so header text and content are consistent. Section headers: "Players", "League settings", "This week", "Achievements", "Add achievement".  
  - **Used in**: Add Players, Attendance, Pods (per-pod as section), Achievements, Stats, Weekly/Tournament Standings.  
  - **Testing**: Renders header + content inside `List` with `.listStyle(.insetGrouped)`.

**Rationale**: iOS HIG and spec require inset grouped list style with section headers. One pattern ensures native look and one place to fix layout/accessibility.

### 7.3 Labeled controls (spec: iOS Switches and Steppers; 44pt)

- **LabeledToggle** (SwiftUI `View`)  
  - `Toggle(title, isOn: binding).labelsHidden()` optional if you use custom label; wrap in a row with `Text(title)` + `Toggle` and apply `.frame(minHeight: 44)` to the row so the whole row is tappable. Use `.accessibilityLabel(title)` if needed.  
  - **Used in**: Attendance ("Count achievements this week"), Achievements ("Always on").  
  - **Testing**: Binding updates; label and accessibility.

- **LabeledStepper** (SwiftUI `View`)  
  - `HStack { Text(title); Spacer(); Stepper("", value: binding, in: range) }` or `Stepper(title, value: binding, in: range)` with value displayed; `.frame(minHeight: 44)`. Use `.accessibilityValue` for current value.  
  - **Used in**: Add Players (weeks, random achievements), Achievements (points).  
  - **Testing**: Value and range; label.

**Rationale**: Spec: "Switches for …", "Steppers or labeled number fields for …". Native `Toggle` and `Stepper` with consistent 44pt and labels; easy to test.

### 7.4 Player row (spec: player lists, pod player rows; native List row, 44pt)

- **PlayerRow** (SwiftUI `View`; variants or one view with enum)  
  - **Display variant**: `HStack { VStack(alignment: .leading) { Text(name).font(.headline); Text(subtitle).font(.caption) } }`; `.frame(minHeight: 44)`. **Used in**: Stats.  
  - **With trailing action**: name + `Button(role: .destructive)` (e.g. remove); use `List` row or `HStack` with `.frame(minHeight: 44)`. **Used in**: Add Players.  
  - **With toggle**: name + `Toggle("", isOn: binding).labelsHidden()`; row `.frame(minHeight: 44)`; `.accessibilityElement(children: .combine)` and label. **Used in**: Attendance.  
  - **With placement + achievements**: name + `PlacementPicker(selection:binding, isDisabled:locked)` + `ForEach(activeAchievements) { AchievementCheckItem(...) }`; row 44pt. **Used in**: Pods.  
  - **Testing**: Snapshot each variant; accessibility (list item, "Placement for [name]").

**Rationale**: Spec: "player lists, … pod player rows". Native `List` rows and `Toggle`; one row component enforces 44pt and list semantics.

### 7.5 Standings row (spec: weekly/tournament standings; native List row)

- **StandingsRow** (SwiftUI `View`; enum or two thin views)  
  - **Weekly mode**: `HStack { Text("#\(rank)"); Text(name).font(.headline); Spacer(); VStack(alignment: .trailing) { Text("\(total) pts"); Text("P: \(placement) A: \(achievement)").font(.caption) } }`; `.frame(minHeight: 44)`; `.accessibilityLabel("Rank \(rank), \(name), \(total) points")`.  
  - **Tournament mode**: same structure with wins; `.accessibilityLabel("Rank \(rank), \(name), \(total) points, \(wins) wins")`.  
  - **Used in**: Weekly Standings, Tournament Standings.  
  - **Testing**: Snapshot both modes; accessibility.

**Rationale**: Both modals use native `List`; one row component with mode minimizes duplication and keeps standings testable.

### 7.6 Empty state (spec: empty or explanatory state; native iOS)

- **EmptyStateView** (SwiftUI `View`)  
  - `VStack(spacing: 8) { Text(message).font(.body.multilineTextAlignment(.center)); if let hint { Text(hint).font(.caption).foregroundStyle(.secondary) } }`; use Dynamic Type–friendly fonts.  
  - **Used in**: Add Players (0 players), Pods (no present players / nothing to undo), Stats (no players), Achievements (optional).  
  - **Testing**: Renders message and hint; visibility when count is zero.

**Rationale**: Spec and 07 require "empty or explanatory state". One native view ensures consistent copy and layout.

### 7.7 Hint / validation message (spec: block or show message; native iOS)

- **HintText** (SwiftUI `View`)  
  - `Text(message).font(.caption).foregroundStyle(.secondary)`; optional `.accessibilityLabel`.  
  - **Used in**: Add Players, Attendance, Pods (Undo disabled), Weekly Standings.  
  - **Testing**: Renders text; visibility.

**Rationale**: Same pattern on flow screens; one style and one place to test copy.

### 7.8 Placement picker (spec: segmented control or picker 1–4; native iOS)

- **PlacementPicker** (SwiftUI `View`)  
  - `Picker("Placement", selection: binding) { ForEach(1...4, id: \.self) { Text("\($0)").tag($0) } }.pickerStyle(.segmented).disabled(isDisabled).accessibilityLabel("Placement for \(playerName)")`.  
  - **Used in**: Pods (per player in each pod).  
  - **Testing**: Selection binding; disabled state; accessibility.

**Rationale**: Spec: "segmented control or picker for placement (1–4)". Native `Picker` with `.pickerStyle(.segmented)`; one component, one test target.

### 7.9 Achievement row (Achievements list + Pods checklist; native iOS)

- **AchievementListRow** (SwiftUI `View`)  
  - `HStack { Text(name); Text("\(points) pts").font(.caption); Spacer(); Toggle("Always on", isOn: alwaysOnBinding); Button(role: .destructive) { onRemove() } }`; `.frame(minHeight: 44)`.  
  - **Used in**: Achievements screen.  
  - **Testing**: Toggle and remove; snapshot.

- **AchievementCheckItem** (SwiftUI `View`)  
  - `Toggle(isOn: isChecked) { HStack { Text(name); Text("+\(points)").font(.caption) } }`; `.frame(minHeight: 44)`.  
  - **Used in**: Pods (active weekly achievements per player).  
  - **Testing**: Checked binding; label and points.

**Rationale**: Native `Toggle` and list rows; two small views avoid duplication.

### 7.10 Flow screen navigation bar (spec: title + Cancel; native NavigationStack)

- **FlowScreenNavBar** (SwiftUI: use `.navigationTitle(title).toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { onCancel() } } }`)  
  - Title string; leading "Cancel" (`.cancellationAction`) that calls `onCancel()` (return to Dashboard).  
  - **Used in**: Confirm New Tournament, Add Players, Attendance.  
  - **Testing**: Title and Cancel action; document that Cancel discards uncommitted state.

**Rationale**: Spec: "Back or Cancel that returns to Dashboard" on flow-only screens. Native `NavigationStack` + toolbar; one pattern for all flow screens.

### 7.11 Modal action bar (sheet/fullScreenCover; native iOS)

- **ModalActionBar** (SwiftUI `View`)  
  - Either: `VStack { PrimaryActionButton(...); SecondaryButton(...) }` or single `PrimaryActionButton("Close", ...)`; buttons `.frame(minHeight: 44)`. Use at bottom of sheet/fullScreenCover.  
  - **Used in**: Weekly Standings (Continue + Exit), Tournament Standings (Close).  
  - **Testing**: Button labels and actions; 44pt.

**Rationale**: Native buttons in a vertical stack; one component for modal footers.

---

**Summary – create these now (native iOS / SwiftUI)**

| Component (SwiftUI View) | Used in | Test focus |
|-------------------------|--------|------------|
| PrimaryActionButton | Dashboard, Add Players, Attendance, Pods, Confirm, Weekly/Tournament Standings | Style, disabled, accessibility |
| SecondaryButton | Confirm, Add Players, Attendance, Weekly Standings | Style, accessibility |
| DestructiveActionButton | Confirm New Tournament | Role, accessibility |
| InsetGroupedSection / List + .listStyle(.insetGrouped) | All list-based views | Header + content in List |
| LabeledToggle | Attendance, Achievements | Binding, label, 44pt |
| LabeledStepper | Add Players, Achievements | Value, range, label |
| PlayerRow (variants) | Add Players, Attendance, Pods, Stats | Display, remove, toggle, placement+achievements |
| StandingsRow | Weekly Standings, Tournament Standings | Weekly vs tournament mode |
| EmptyStateView | Add Players, Attendance, Pods, Stats, Achievements | Message, visibility, Dynamic Type |
| HintText | Add Players, Attendance, Pods, Weekly Standings | Copy, visibility |
| PlacementPicker | Pods | Picker(.segmented), 1–4, disabled, accessibility |
| AchievementListRow | Achievements | Toggle, remove |
| AchievementCheckItem | Pods | Toggle, name, points |
| FlowScreenNavBar (toolbar .cancellationAction) | Confirm, Add Players, Attendance | Title, Cancel |
| ModalActionBar | Weekly Standings, Tournament Standings | Continue+Exit or Close |

Implementing these first gives: (1) one place per pattern (no duplicated button/list/row logic), (2) consistent native iOS 44pt (use `AppConstants.UI.minTouchTargetHeight`) and accessibility (HIG), (3) snapshot/unit tests per SwiftUI view so regressions are caught early. Use **Constants** (see §4.2) for 44pt and any other magic numbers.

---

## 8. Context document (CONTEXT.md)

**Goal**: Single file so you (or another developer) can resume and remember how the app is architected and what remains for a fully functional App Store app.

**Suggested path**: `ios/CONTEXT.md` (or repo-root `IOS_APP_CONTEXT.md`).

**Contents** (verbose):

1. **What this app is**: Budget League Tracker for MTG leagues; organizer role; multi-week, pods of 4, placement points (1→4, 2→3, 3→2, 4→1), achievement points, weekly and tournament standings.
2. **Architecture**:
   - Navigation: Tab bar (Dashboard, Pods, Stats, Achievements); flow stack Dashboard → Confirm New Tournament → Add Players → Attendance → Pods; modals: Weekly Standings (sheet), Tournament Standings (fullScreenCover when final).
   - State and storage: SwiftData only. Models: Player, Achievement, LeagueState (and optionally embedded current week + pod history in LeagueState). ModelContext = cache; ModelContainer = persistence.
   - Business logic: Engine module (pure or nearly pure functions) for scoring and transitions; views call engine and apply results to SwiftData.
3. **Key files**: `project.yml`; `BudgetLeagueTrackerApp.swift` (modelContainer); `ContentView` (TabView + navigation); `Models/Player.swift`, `Achievement.swift`, `LeagueState.swift`; `Engine/LeagueEngine.swift`; `ViewModels/` (one ViewModel per screen: DashboardViewModel, AddPlayersViewModel, …; coordinates View + SwiftData + Engine; see §4.1); `Constants/AppConstants.swift` (UI, League, Scoring, DefaultAchievement; no magic numbers; see §4.2); `Components/` (PrimaryActionButton, …); `Views/DashboardView.swift`, …; `CONTEXT.md`. **Focus: native iOS (SwiftUI)** — all UI is SwiftUI `View` types with system list style, 44pt touch targets (from AppConstants.UI), Dynamic Type, and accessibility.
4. **Data flow**: User action → view handler → read from @Query/modelContext → call engine with current data → write back to SwiftData (insert/update/delete) → save(). No separate cache; SwiftData handles it.
5. **Specs and wireframes**: `specs/` and `wireframes/` are the source of truth for behavior and iOS UX (inset grouped lists, 44pt targets, switches/steppers, etc.).
6. **What’s left for App Store**:
   - Validation: Block or warn when 0 players at Start Tournament and 0 present at Confirm Attendance (per [specs/07-ui-states-and-edge-cases.md](../specs/07-ui-states-and-edge-cases.md)).
   - Error handling: Clear messages for empty pods, nothing to undo; clamp numeric inputs.
   - Persistence: Ensure state restoration (currentScreen) and robust save on every meaningful change.
   - Polish: Accessibility (Dynamic Type, VoiceOver, 44pt); optional onboarding; app icon and launch screen.
   - Release: Privacy policy if needed; TestFlight; App Store listing.

---

## Summary table (native iOS / SwiftUI)

**Focus: native iOS only.** All views and components are SwiftUI `View` types; use system list style (`.insetGrouped`), native `Button`/`Toggle`/`Stepper`/`Picker`, 44pt minimum touch targets, Dynamic Type–friendly text, and accessibility labels per HIG.

| Step | Item | What will be done |
|------|------|-------------------|
| 1 | Project | Create `ios/project.yml` (app target only, Swift 6, iOS 17); run XcodeGen; create BudgetLeagueTracker/ folder structure (Models, Engine, Views, ViewModels, Components, Constants). |
| 2 | SwiftData | Define @Model Player, Achievement, LeagueState; Option A for current week + pod history in LeagueState; .modelContainer(for: [...]) in app entry; bootstrap LeagueState and default achievement (use AppConstants.DefaultAchievement). |
| 3 | Engine | Implement startNewTournament, add/removePlayer, startTournament, confirmAttendance, addWeeklyPlayer, generatePodsForRound, savePod, undoLastPod, nextRound, closeWeeklyStandings, exitWeeklyStandings, closeTournamentStandings, rollActiveAchievements, add/removeAchievement, setScreen; use AppConstants for placement points, ranges, pod size, rounds; use from ViewModels with SwiftData read/write. |
| 4 | ViewModel and Constants | **ViewModels**: One ViewModel per screen ({Screen}ViewModel); coordinates View + SwiftData + Engine; no UI; testable with in-memory context (see §4.1). **Constants**: AppConstants (UI.minTouchTargetHeight 44, League.weeksRange/randomAchievementsPerWeekRange/roundsPerWeek/podSize, Scoring.placementPoints/initial*, DefaultAchievement); no magic numbers in Engine/ViewModels/Views (see §4.2). |
| 5 | Navigation | TabView (4 tabs); NavigationStack per tab; show flow screens from Dashboard stack; present Weekly Standings as sheet, Tournament Standings as fullScreenCover when final; persist currentScreen for restoration. |
| 6.1–6.9 | Views | Dashboard, Confirm New Tournament, Add Players, Attendance, Pods, Weekly Standings, Tournament Standings, Stats, Achievements — each backed by a ViewModel; use Components and AppConstants. |
| 7 | Reusable components (native iOS) | Create SwiftUI views: PrimaryActionButton, SecondaryButton, DestructiveActionButton; List + .listStyle(.insetGrouped) + Section; LabeledToggle, LabeledStepper; PlayerRow (variants), StandingsRow, EmptyStateView, HintText, PlacementPicker (.pickerStyle(.segmented)), AchievementListRow, AchievementCheckItem; FlowScreenNavBar (toolbar .cancellationAction); ModalActionBar. Use AppConstants.UI.minTouchTargetHeight for 44pt; Dynamic Type–friendly; accessibility labels (see §7). |
| 8 | Context doc | Write CONTEXT.md with architecture, data flow, key files (including ViewModels and Constants), and App Store todo. |

This plan is intentionally verbose and **focused on native iOS (SwiftUI)**. Each view has a dedicated step with layout, data, actions, and example code. Use it as the single reference when implementing the iOS app.
