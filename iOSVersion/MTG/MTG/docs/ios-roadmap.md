# Budget League Tracker iOS – Roadmap to App Store

## Current State

**Core implementation is complete:**
- SwiftUI views (9 screens)
- ViewModels (9)
- SwiftData models (Player, Achievement, LeagueState)
- Business logic engine (17 functions)
- Reusable components (13)
- Constants centralized (no magic numbers)
- Navigation shell (TabView + NavigationStack + sheet/fullScreenCover)

**Not yet done:**
- Never compiled or run on macOS/Xcode
- No tests
- No accessibility audit
- No theming/dark mode verification
- No app icon or launch screen
- No App Store assets

---

## Phase 1: Build & Smoke Test

**Goal:** Get the app compiling and running on simulator/device.

| Task | Description |
|------|-------------|
| Set up macOS environment | Install Xcode 15+, XcodeGen |
| Generate Xcode project | Run `xcodegen` in `ios/` |
| Fix compilation errors | Resolve any Swift 6 / SwiftData issues |
| Smoke test on simulator | Verify all screens load, navigation works |
| Smoke test core flows | Start tournament → Add players → Attendance → Pods → Standings |
| Fix runtime bugs | Address any crashes or logic errors |

**Deliverable:** App runs end-to-end on iOS 17 simulator.

---

## Phase 2: Testing

**Goal:** Comprehensive test coverage for confidence in refactoring and maintenance.

### 2.1 Unit Tests (Engine + ViewModels)

| Task | Description |
|------|-------------|
| Add test target | Update `project.yml` with test target |
| Test `LeagueEngine` functions | `startNewTournament`, `addPlayer`, `savePod`, `undoLastPod`, scoring, etc. |
| Test ViewModels | Verify state changes, action methods, computed properties |
| Test `AppConstants` | Verify scoring function, ranges |
| Use in-memory SwiftData | `ModelConfiguration(isStoredInMemoryOnly: true)` for isolated tests |

### 2.2 UI Tests

| Task | Description |
|------|-------------|
| Add UI test target | XCUITest target in `project.yml` |
| Test navigation flows | Dashboard → Confirm → Add Players → Attendance → Pods |
| Test modal presentation | Weekly Standings sheet, Tournament Standings fullScreenCover |
| Test button states | Disabled states for "Start Tournament" (0 players), "Confirm Attendance" (0 present) |

### 2.3 Snapshot Tests (Optional)

| Task | Description |
|------|-------------|
| Add snapshot testing library | swift-snapshot-testing or similar |
| Snapshot reusable components | PrimaryActionButton, PlayerRow, StandingsRow, etc. |
| Snapshot key screens | Dashboard, Pods, Standings in various states |

**Deliverable:** 80%+ code coverage on Engine/ViewModels; UI tests for critical paths.

---

## Phase 3: Accessibility

**Goal:** App is fully usable with VoiceOver, Dynamic Type, and meets Apple's accessibility guidelines.

| Task | Description |
|------|-------------|
| Audit touch targets | Verify all interactive elements are 44pt minimum |
| Test with VoiceOver | Navigate entire app using VoiceOver |
| Add missing accessibility labels | Ensure all buttons, controls, rows have descriptive labels |
| Add accessibility hints | Where actions aren't obvious from label alone |
| Test Dynamic Type | Verify text scales from xSmall to AX5 without truncation or overlap |
| Test with Accessibility Inspector | Xcode tool to find issues |
| Test with Voice Control | Verify all actions are reachable |
| Add accessibility identifiers | For UI tests |

**Deliverable:** App passes Accessibility Inspector audit; usable with VoiceOver end-to-end.

---

## Phase 4: Theming & Polish

**Goal:** App looks great in light and dark mode with consistent visual design.

### 4.1 Light/Dark Mode

| Task | Description |
|------|-------------|
| Test in dark mode | Verify all screens in dark appearance |
| Fix hardcoded colors | Replace any hardcoded colors with semantic colors |
| Use `Color.primary`, `.secondary` | For text |
| Use system backgrounds | `.background`, `Color(.systemBackground)` |
| Test both modes on device | Verify contrast ratios meet WCAG AA |

### 4.2 Visual Polish

| Task | Description |
|------|-------------|
| Consistent spacing | Audit padding/margins across screens |
| Loading states | Add loading indicators where needed (if any async operations) |
| Empty states | Verify empty state messages are helpful |
| Error states | User-friendly error messages |
| Animations | Subtle transitions for navigation, modals |
| Haptic feedback | Add haptics for save, undo, milestone actions |

**Deliverable:** App looks polished in both light and dark mode.

---

## Phase 5: App Icon & Launch Screen

**Goal:** Professional app identity.

| Task | Description |
|------|-------------|
| Design app icon | 1024x1024 master icon (all size variants generated) |
| Add icon to asset catalog | `Assets.xcassets/AppIcon.appiconset` |
| Design launch screen | Simple branded launch screen |
| Configure launch screen | Either storyboard or SwiftUI-based |
| Test icon on home screen | Verify appearance on device |

**Deliverable:** App has professional icon and launch experience.

---

## Phase 6: App Store Preparation

**Goal:** App is ready for TestFlight and App Store submission.

### 6.1 Metadata & Assets

| Task | Description |
|------|-------------|
| App name | Finalize "Budget League Tracker" or alternative |
| App description | Write compelling App Store description |
| Keywords | Research and select keywords for ASO |
| Screenshots | 6.7" (iPhone 15 Pro Max), 6.5" (iPhone 11 Pro Max), 5.5" (iPhone 8 Plus) |
| iPad screenshots | If supporting iPad |
| App preview video | Optional 15-30 second demo video |
| Privacy policy | Create and host privacy policy (even if no data collected) |
| Support URL | Create support page or contact method |

### 6.2 App Store Connect Setup

| Task | Description |
|------|-------------|
| Create App Store Connect record | Register app with bundle ID |
| Configure app information | Category, age rating, pricing (free) |
| Set up TestFlight | Internal and external testing groups |
| Configure in-app purchases | N/A for v1.0 |

### 6.3 Technical Requirements

| Task | Description |
|------|-------------|
| Bundle ID | Finalize `com.yourname.BudgetLeagueTracker` |
| Signing & capabilities | Configure provisioning profiles |
| Privacy manifest | Add if using any restricted APIs |
| Export compliance | Declare encryption usage (likely none) |

**Deliverable:** App is uploaded to App Store Connect, ready for review.

---

## Phase 7: Beta Testing

**Goal:** Real-world testing and feedback before public release.

| Task | Description |
|------|-------------|
| Internal TestFlight | Test with friends/family |
| External TestFlight | Broader beta with MTG community |
| Collect feedback | Bug reports, feature requests, UX issues |
| Fix critical bugs | Address showstoppers |
| Iterate on UX | Refine based on feedback |
| Monitor crash reports | Fix any crashes from TestFlight |

**Deliverable:** Stable build with positive beta feedback.

---

## Phase 8: App Store Release

**Goal:** App is live and available to everyone.

| Task | Description |
|------|-------------|
| Submit for review | Submit build to App Store review |
| Respond to review feedback | Address any rejection reasons |
| Set release date | Immediate or scheduled release |
| Announce launch | Social media, MTG communities |
| Monitor reviews | Respond to user reviews |
| Monitor crash reports | Fix post-launch issues |

**Deliverable:** App is live on the App Store.

---

## Phase 9: Post-Launch Maintenance

**Goal:** Keep app healthy and users happy.

| Task | Description |
|------|-------------|
| iOS version updates | Support new iOS versions (iOS 18, etc.) |
| Bug fixes | Address user-reported issues |
| Performance monitoring | Track and fix performance issues |
| User feedback triage | Prioritize feature requests |

---

## Phase 10: Extensions & Enhancements (R&D)

**Goal:** Explore platform extensions to enhance the app experience.

### 10.1 Apple Watch App (watchOS)

| Task | Description |
|------|-------------|
| **Research** | Determine useful Watch functionality |
| **Potential features** | Quick view of current week standings; Live round status; Haptic notifications when pod is saved |
| **Implementation** | WatchKit or SwiftUI for watchOS; Watch Connectivity for data sync |
| **Considerations** | Limited screen real estate; Focus on glanceable info |

### 10.2 Home Screen Widgets (WidgetKit)

| Task | Description |
|------|-------------|
| **Research** | Identify widget use cases |
| **Potential widgets** | Current week/round status (small); Top 3 standings (medium); Quick "Start Attendance" action (medium) |
| **Implementation** | WidgetKit + SwiftUI; App Intents for interactive widgets (iOS 17+) |
| **Considerations** | Widgets are read-only snapshots; Use App Intents for actions |

### 10.3 Live Activities & Dynamic Island

| Task | Description |
|------|-------------|
| **Research** | When would Live Activities make sense? |
| **Potential use** | Active tournament session showing current round and pods remaining |
| **Implementation** | ActivityKit; Requires iOS 16.1+ |
| **Considerations** | Only useful during active play sessions |

### 10.4 Siri Shortcuts & App Intents

| Task | Description |
|------|-------------|
| **Research** | Voice-driven actions |
| **Potential intents** | "Start attendance for Budget League"; "Who's winning the tournament?" |
| **Implementation** | App Intents framework (iOS 16+) |
| **Considerations** | Natural language variations; Siri response design |

### 10.5 iCloud Sync

| Task | Description |
|------|-------------|
| **Research** | Multi-device sync needs |
| **Implementation** | SwiftData + CloudKit container |
| **Considerations** | Conflict resolution; Offline support; Privacy |

### 10.6 iPad Optimization

| Task | Description |
|------|-------------|
| **Research** | iPad-specific layouts |
| **Implementation** | Adaptive layouts; Split view support; Keyboard shortcuts |
| **Considerations** | Larger screen real estate; Multitasking |

### 10.7 Mac Catalyst / Native Mac

| Task | Description |
|------|-------------|
| **Research** | Mac user demand |
| **Implementation** | Mac Catalyst (checkbox) or native SwiftUI for macOS |
| **Considerations** | Menu bar; Keyboard navigation; Window management |

### 10.8 SharePlay & Multiplayer

| Task | Description |
|------|-------------|
| **Research** | Remote tournament organization |
| **Implementation** | SharePlay for shared sessions; GroupActivities framework |
| **Considerations** | Complex sync requirements; Edge cases |

---

## Timeline Estimate

| Phase | Estimated Duration |
|-------|-------------------|
| Phase 1: Build & Smoke Test | 1-2 days |
| Phase 2: Testing | 1-2 weeks |
| Phase 3: Accessibility | 3-5 days |
| Phase 4: Theming & Polish | 3-5 days |
| Phase 5: App Icon & Launch Screen | 1-2 days |
| Phase 6: App Store Preparation | 2-3 days |
| Phase 7: Beta Testing | 2-4 weeks |
| Phase 8: App Store Release | 1-2 weeks (review time) |
| **Total to App Store** | **6-10 weeks** |
| Phase 9: Ongoing | Continuous |
| Phase 10: Extensions R&D | Ongoing / post-launch |

---

## Priority Matrix

### Must Have (v1.0)
- Compiles and runs
- Core flows work correctly
- Basic accessibility (VoiceOver navigable, 44pt targets)
- Light/dark mode support
- App icon
- TestFlight beta

### Should Have (v1.0)
- Comprehensive unit tests
- UI tests for critical paths
- Polished empty states and error messages
- Haptic feedback

### Nice to Have (v1.x)
- Snapshot tests
- iPad optimization
- Widgets
- iCloud sync

### Future (v2.0+)
- Apple Watch app
- Live Activities
- Siri Shortcuts
- SharePlay
- Mac app

---

## Next Steps

1. **Get access to a Mac** with Xcode 15+
2. **Run Phase 1** – Compile, fix errors, smoke test
3. **Create GitHub Issues** for each phase/task for tracking
4. **Start Phase 2** – Testing infrastructure

