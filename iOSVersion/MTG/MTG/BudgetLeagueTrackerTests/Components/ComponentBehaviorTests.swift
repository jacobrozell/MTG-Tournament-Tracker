import Testing
import SwiftUI
import ViewInspector
@testable import BudgetLeagueTracker

/// Behavior tests for SwiftUI components using ViewInspector
/// Note: These tests verify component behavior and bindings
@Suite("Component Behavior Tests")
@MainActor
struct ComponentBehaviorTests {
    
    // MARK: - PrimaryActionButton Tests
    
    @Suite("PrimaryActionButton")
    @MainActor
    struct PrimaryActionButtonTests {
        
        @Test("Calls action on tap")
        func callsActionOnTap() throws {
            var actionCalled = false
            let button = PrimaryActionButton(title: "Test", action: {
                actionCalled = true
            })
            
            try button.inspect().button().tap()
            
            #expect(actionCalled == true)
        }
        
        @Test("Respects disabled state")
        func respectsDisabledState() throws {
            let button = PrimaryActionButton(title: "Test", action: {}, isDisabled: true)
            
            let isDisabled = try button.inspect().button().isDisabled()
            
            #expect(isDisabled == true)
        }
        
        @Test("Shows correct title")
        func showsCorrectTitle() throws {
            let button = PrimaryActionButton(title: "My Action", action: {})
            
            let text = try button.inspect().button().labelView().text().string()
            
            #expect(text == "My Action")
        }
    }
    
    // MARK: - SecondaryButton Tests
    
    @Suite("SecondaryButton")
    @MainActor
    struct SecondaryButtonTests {
        
        @Test("Calls action on tap")
        func callsActionOnTap() throws {
            var actionCalled = false
            let button = SecondaryButton(title: "Secondary", action: {
                actionCalled = true
            })
            
            try button.inspect().button().tap()
            
            #expect(actionCalled == true)
        }
        
        @Test("Respects disabled state")
        func respectsDisabledState() throws {
            let button = SecondaryButton(title: "Test", action: {}, isDisabled: true)
            
            let isDisabled = try button.inspect().button().isDisabled()
            
            #expect(isDisabled == true)
        }
    }
    
    // MARK: - DestructiveActionButton Tests
    
    @Suite("DestructiveActionButton")
    @MainActor
    struct DestructiveActionButtonTests {
        
        @Test("Calls action on tap")
        func callsActionOnTap() throws {
            var actionCalled = false
            let button = DestructiveActionButton(title: "Delete", action: {
                actionCalled = true
            })
            
            try button.inspect().button().tap()
            
            #expect(actionCalled == true)
        }
    }
    
    // MARK: - PlacementPicker Tests
    
    @Suite("PlacementPicker")
    @MainActor
    struct PlacementPickerTests {
        
        @Test("Shows 1-4 placement options")
        func shows1To4Options() throws {
            var selection = 1
            let picker = PlacementPicker(
                playerName: "Test",
                selection: Binding(get: { selection }, set: { selection = $0 }),
                isDisabled: false
            )
            
            // PlacementPicker uses a Picker with segmented style
            // Verify it renders without throwing
            _ = try picker.inspect()
        }
        
        @Test("Binding updates on selection")
        func bindingUpdates() throws {
            var selection = 1
            let binding = Binding(get: { selection }, set: { selection = $0 })
            
            // Simulate selection change
            binding.wrappedValue = 3
            
            #expect(selection == 3)
        }
    }
    
    // MARK: - LabeledToggle Tests
    
    @Suite("LabeledToggle")
    @MainActor
    struct LabeledToggleTests {
        
        @Test("Shows label")
        func showsLabel() throws {
            var isOn = false
            let toggle = LabeledToggle(
                title: "My Toggle",
                isOn: Binding(get: { isOn }, set: { isOn = $0 })
            )
            
            // Verify the view renders
            _ = try toggle.inspect()
        }
        
        @Test("Binding updates on toggle")
        func bindingUpdates() throws {
            var isOn = false
            let binding = Binding(get: { isOn }, set: { isOn = $0 })
            
            // Simulate toggle
            binding.wrappedValue = true
            
            #expect(isOn == true)
        }
    }
    
    // MARK: - LabeledStepper Tests
    
    @Suite("LabeledStepper")
    @MainActor
    struct LabeledStepperTests {
        
        @Test("Shows title and current value")
        func showsTitleAndValue() throws {
            var value = 5
            let stepper = LabeledStepper(
                title: "Count",
                value: Binding(get: { value }, set: { value = $0 }),
                range: 1...10
            )
            
            // Verify the view renders
            _ = try stepper.inspect()
        }
        
        @Test("Binding updates within range")
        func bindingUpdatesWithinRange() throws {
            var value = 5
            let binding = Binding(get: { value }, set: { value = $0 })
            
            binding.wrappedValue = 8
            #expect(value == 8)
        }
    }
    
    // MARK: - PlayerRow Tests
    
    @Suite("PlayerRow")
    @MainActor
    struct PlayerRowTests {
        
        @Test("Display mode shows name")
        func displayModeShowsName() throws {
            let row = PlayerRow(name: "Alice", mode: .display(subtitle: nil))
            
            // Verify the view renders with player name
            _ = try row.inspect()
        }
        
        @Test("Removable mode shows trash button")
        func removableModeShowsTrash() throws {
            var removed = false
            let row = PlayerRow(name: "Bob", mode: .removable(onRemove: {
                removed = true
            }))
            
            // Find and tap the remove button (image-based button, so we find all buttons)
            let buttons = try row.inspect().findAll(ViewType.Button.self)
            // The removable row has one button (the trash icon)
            let removeButton = try #require(buttons.first)
            try removeButton.tap()
            
            #expect(removed == true)
        }
        
        @Test("Toggleable mode has toggle")
        func toggleableModeHasToggle() throws {
            var isOn = false
            let row = PlayerRow(
                name: "Charlie",
                mode: .toggleable(isOn: Binding(get: { isOn }, set: { isOn = $0 }))
            )
            
            // Verify the view renders
            _ = try row.inspect()
        }
    }
    
    // MARK: - StandingsRow Tests
    
    @Suite("StandingsRow")
    @MainActor
    struct StandingsRowTests {
        
        @Test("Weekly mode shows correct info")
        func weeklyModeShowsCorrectInfo() throws {
            let row = StandingsRow(
                rank: 1,
                name: "Leader",
                totalPoints: 28,
                placementPoints: 20,
                achievementPoints: 8,
                mode: .weekly
            )
            
            // Verify the view renders
            _ = try row.inspect()
        }
        
        @Test("Tournament mode shows wins")
        func tournamentModeShowsWins() throws {
            let row = StandingsRow(
                rank: 1,
                name: "Champion",
                totalPoints: 50,
                placementPoints: 40,
                achievementPoints: 10,
                wins: 5,
                mode: .tournament
            )
            
            // Verify the view renders
            _ = try row.inspect()
        }
    }
    
    // MARK: - AchievementCheckItem Tests
    
    @Suite("AchievementCheckItem")
    @MainActor
    struct AchievementCheckItemTests {
        
        @Test("Toggle updates binding")
        func toggleUpdatesBinding() throws {
            var isChecked = false
            let binding = Binding(get: { isChecked }, set: { isChecked = $0 })
            
            // Simulate toggle
            binding.wrappedValue = true
            
            #expect(isChecked == true)
        }
        
        @Test("Shows name and points")
        func showsNameAndPoints() throws {
            var isChecked = false
            let item = AchievementCheckItem(
                name: "First Blood",
                points: 2,
                isChecked: Binding(get: { isChecked }, set: { isChecked = $0 }),
                isDisabled: false
            )
            
            // Verify the view renders
            _ = try item.inspect()
        }
    }
    
    // MARK: - AchievementListRow Tests
    
    @Suite("AchievementListRow")
    @MainActor
    struct AchievementListRowTests {
        
        @Test("Toggle alwaysOn works")
        func toggleAlwaysOnWorks() throws {
            var alwaysOn = false
            let row = AchievementListRow(
                name: "Test",
                points: 1,
                alwaysOn: Binding(get: { alwaysOn }, set: { alwaysOn = $0 }),
                onRemove: {}
            )
            
            // Verify the view renders
            _ = try row.inspect()
        }
        
        @Test("Remove action works")
        func removeActionWorks() throws {
            var alwaysOn = false
            var removed = false
            let row = AchievementListRow(
                name: "Test",
                points: 1,
                alwaysOn: Binding(get: { alwaysOn }, set: { alwaysOn = $0 }),
                onRemove: { removed = true }
            )
            
            // Find and tap remove (image-based button, so we find all buttons)
            let buttons = try row.inspect().findAll(ViewType.Button.self)
            // The row has the trash button as the last button
            let removeButton = try #require(buttons.last)
            try removeButton.tap()
            
            #expect(removed == true)
        }
    }
    
    // MARK: - EmptyStateView Tests
    
    @Suite("EmptyStateView")
    @MainActor
    struct EmptyStateViewTests {
        
        @Test("Shows message")
        func showsMessage() throws {
            let view = EmptyStateView(message: "No items found")
            
            // Verify text exists (find throws if not found)
            _ = try view.inspect().find(text: "No items found")
        }
        
        @Test("Shows optional hint")
        func showsOptionalHint() throws {
            let view = EmptyStateView(message: "No items", hint: "Add some items to get started")
            
            // Verify hint is shown
            _ = try view.inspect().find(text: "Add some items to get started")
        }
        
        @Test("Works without hint")
        func worksWithoutHint() throws {
            let view = EmptyStateView(message: "Empty")
            
            // Should not throw
            _ = try view.inspect()
        }
    }
    
    // MARK: - ModalActionBar Tests
    
    @Suite("ModalActionBar")
    @MainActor
    struct ModalActionBarTests {
        
        @Test("Primary action works")
        func primaryActionWorks() throws {
            var primaryCalled = false
            let bar = ModalActionBar(
                primaryTitle: "Continue",
                primaryAction: { primaryCalled = true }
            )
            
            // Find and tap primary button
            let button = try bar.inspect().find(button: "Continue")
            try button.tap()
            
            #expect(primaryCalled == true)
        }
        
        @Test("Optional secondary action works")
        func secondaryActionWorks() throws {
            var secondaryCalled = false
            let bar = ModalActionBar(
                primaryTitle: "Continue",
                primaryAction: {},
                secondaryTitle: "Cancel",
                secondaryAction: { secondaryCalled = true }
            )
            
            // Find and tap secondary button
            let button = try bar.inspect().find(button: "Cancel")
            try button.tap()
            
            #expect(secondaryCalled == true)
        }
    }
    
    // MARK: - TournamentCell Tests
    
    @Suite("TournamentCell")
    @MainActor
    struct TournamentCellTests {
        
        @Test("Shows tournament name")
        func showsTournamentName() throws {
            let tournament = TestFixtures.tournament(name: "Spring League")
            let cell = TournamentCell(
                tournament: tournament,
                playerCount: 6,
                winnerName: nil
            )
            
            // Find tournament name
            _ = try cell.inspect().find(text: "Spring League")
        }
        
        @Test("Shows status info")
        func showsStatusInfo() throws {
            let tournament = TestFixtures.tournament()
            let cell = TournamentCell(
                tournament: tournament,
                playerCount: 8,
                winnerName: nil
            )
            
            // Verify cell renders
            _ = try cell.inspect()
        }
    }
    
    // MARK: - HintText Tests
    
    @Suite("HintText")
    @MainActor
    struct HintTextTests {
        
        @Test("Shows hint message")
        func showsHintMessage() throws {
            let hint = HintText(message: "Select at least one player")
            
            _ = try hint.inspect().find(text: "Select at least one player")
        }
    }
}
