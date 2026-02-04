import Testing
import SwiftUI
import SnapshotTesting
@testable import BudgetLeagueTracker

/// Snapshot tests for visual regression testing of components
/// Note: Set `SnapshotTestConfiguration.record = true` to generate reference snapshots
@Suite("Component Snapshot Tests")
@MainActor
struct ComponentSnapshotTests {
    
    // MARK: - PrimaryActionButton Snapshots
    
    @Suite("PrimaryActionButton")
    @MainActor
    struct PrimaryActionButtonSnapshots {
        
        @Test("Enabled state")
        func enabledState() {
            let button = PrimaryActionButton(title: "Continue", action: {})
            let view = button.frame(width: 300)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("Disabled state")
        func disabledState() {
            let button = PrimaryActionButton(title: "Continue", action: {}, isDisabled: true)
            let view = button.frame(width: 300)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
    }
    
    // MARK: - SecondaryButton Snapshots
    
    @Suite("SecondaryButton")
    @MainActor
    struct SecondaryButtonSnapshots {
        @Test("Enabled state")
        func enabledState() {
            let button = SecondaryButton(title: "Cancel", action: {})
            let view = button.frame(width: 300)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("Disabled state")
        func disabledState() {
            let button = SecondaryButton(title: "Cancel", action: {}, isDisabled: true)
            let view = button.frame(width: 300)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
    }
    
    // MARK: - DestructiveActionButton Snapshots
    
    @Suite("DestructiveActionButton")
    @MainActor
    struct DestructiveActionButtonSnapshots {
        @Test("Enabled state")
        func enabledState() {
            let button = DestructiveActionButton(title: "Delete", action: {})
            let view = button.frame(width: 300)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("Disabled state")
        func disabledState() {
            let button = DestructiveActionButton(title: "Delete", action: {}, isDisabled: true)
            let view = button.frame(width: 300)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
    }
    
    // MARK: - PlacementPicker Snapshots
    
    @Suite("PlacementPicker")
    @MainActor
    struct PlacementPickerSnapshots {
        @Test("Selection 1")
        func selection1() {
            let picker = PlacementPicker(
                playerName: "Player",
                selection: .constant(1),
                isDisabled: false
            )
            let view = picker.frame(width: 300)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("Selection 2")
        func selection2() {
            let picker = PlacementPicker(
                playerName: "Player",
                selection: .constant(2),
                isDisabled: false
            )
            let view = picker.frame(width: 300)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("Selection 3")
        func selection3() {
            let picker = PlacementPicker(
                playerName: "Player",
                selection: .constant(3),
                isDisabled: false
            )
            let view = picker.frame(width: 300)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("Selection 4")
        func selection4() {
            let picker = PlacementPicker(
                playerName: "Player",
                selection: .constant(4),
                isDisabled: false
            )
            let view = picker.frame(width: 300)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("Disabled state")
        func disabledState() {
            let picker = PlacementPicker(
                playerName: "Player",
                selection: .constant(1),
                isDisabled: true
            )
            let view = picker.frame(width: 300)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
    }
    
    // MARK: - PlayerRow Snapshots
    
    @Suite("PlayerRow")
    @MainActor
    struct PlayerRowSnapshots {
        @Test("Display mode")
        func displayMode() {
            let row = PlayerRow(name: "Alice", mode: .display(subtitle: "Wins: 5, Games: 10"))
            let view = row.frame(width: 350)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("Removable mode")
        func removableMode() {
            let row = PlayerRow(name: "Bob", mode: .removable(onRemove: {}))
            let view = row.frame(width: 350)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("Toggleable mode - on")
        func toggleableModeOn() {
            let row = PlayerRow(name: "Charlie", mode: .toggleable(isOn: .constant(true)))
            let view = row.frame(width: 350)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("Toggleable mode - off")
        func toggleableModeOff() {
            let row = PlayerRow(name: "Diana", mode: .toggleable(isOn: .constant(false)))
            let view = row.frame(width: 350)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
    }
    
    // MARK: - StandingsRow Snapshots
    
    @Suite("StandingsRow")
    @MainActor
    struct StandingsRowSnapshots {
        @Test("Weekly mode")
        func weeklyMode() {
            let row = StandingsRow(
                rank: 1,
                name: "Leader",
                totalPoints: 28,
                placementPoints: 20,
                achievementPoints: 8,
                mode: .weekly
            )
            let view = row.frame(width: 350)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("Tournament mode")
        func tournamentMode() {
            let row = StandingsRow(
                rank: 1,
                name: "Champion",
                totalPoints: 70,
                placementPoints: 50,
                achievementPoints: 20,
                wins: 8,
                mode: .tournament
            )
            let view = row.frame(width: 350)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
    }
    
    // MARK: - AchievementCheckItem Snapshots
    
    @Suite("AchievementCheckItem")
    @MainActor
    struct AchievementCheckItemSnapshots {
        @Test("Checked state")
        func checkedState() {
            let item = AchievementCheckItem(
                name: "First Blood",
                points: 2,
                isChecked: .constant(true),
                isDisabled: false
            )
            let view = item.frame(width: 350)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("Unchecked state")
        func uncheckedState() {
            let item = AchievementCheckItem(
                name: "Combo Master",
                points: 3,
                isChecked: .constant(false),
                isDisabled: false
            )
            let view = item.frame(width: 350)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("Disabled state")
        func disabledState() {
            let item = AchievementCheckItem(
                name: "Mill Victory",
                points: 5,
                isChecked: .constant(false),
                isDisabled: true
            )
            let view = item.frame(width: 350)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
    }
    
    // MARK: - AchievementListRow Snapshots
    
    @Suite("AchievementListRow")
    @MainActor
    struct AchievementListRowSnapshots {
        @Test("AlwaysOn true")
        func alwaysOnTrue() {
            let row = AchievementListRow(
                name: "First Blood",
                points: 1,
                alwaysOn: .constant(true),
                onRemove: {}
            )
            let view = row.frame(width: 350)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("AlwaysOn false")
        func alwaysOnFalse() {
            let row = AchievementListRow(
                name: "Rare Win",
                points: 3,
                alwaysOn: .constant(false),
                onRemove: {}
            )
            let view = row.frame(width: 350)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
    }
    
    // MARK: - EmptyStateView Snapshots
    
    @Suite("EmptyStateView")
    @MainActor
    struct EmptyStateViewSnapshots {
        @Test("With hint")
        func withHint() {
            let view = EmptyStateView(
                message: "No tournaments yet",
                hint: "Tap the + button to create your first tournament"
            ).frame(width: 350, height: 200)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("Without hint")
        func withoutHint() {
            let view = EmptyStateView(message: "No players found")
                .frame(width: 350, height: 200)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
    }
    
    // MARK: - TournamentCell Snapshots
    
    @Suite("TournamentCell")
    @MainActor
    struct TournamentCellSnapshots {
        @Test("Ongoing tournament")
        func ongoingTournament() {
            let tournament = TestFixtures.tournament(name: "Spring League 2026")
            let cell = TournamentCell(
                tournament: tournament,
                playerCount: 6,
                winnerName: nil
            )
            let view = cell.frame(width: 350)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("Completed tournament")
        func completedTournament() {
            let tournament = TestFixtures.completedTournament()
            let cell = TournamentCell(
                tournament: tournament,
                playerCount: 8,
                winnerName: "Alice"
            )
            let view = cell.frame(width: 350)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
    }
    
    // MARK: - ModalActionBar Snapshots
    
    @Suite("ModalActionBar")
    @MainActor
    struct ModalActionBarSnapshots {
        @Test("Primary only")
        func primaryOnly() {
            let bar = ModalActionBar(
                primaryTitle: "Close",
                primaryAction: {}
            )
            let view = bar.frame(width: 350)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
        
        @Test("Primary and secondary")
        func primaryAndSecondary() {
            let bar = ModalActionBar(
                primaryTitle: "Continue",
                primaryAction: {},
                secondaryTitle: "Exit",
                secondaryAction: {}
            )
            let view = bar.frame(width: 350)
            
            assertSnapshot(of: view, as: .image, record: SnapshotTestConfiguration.record)
        }
    }
}
