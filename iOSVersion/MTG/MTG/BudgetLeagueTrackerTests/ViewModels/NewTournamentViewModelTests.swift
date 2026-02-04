import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Tests for NewTournamentViewModel
@Suite("NewTournamentViewModel Tests", .serialized)
@MainActor
struct NewTournamentViewModelTests {
    
    @Suite("refresh")
    @MainActor
    struct RefreshTests {
        
        @Test("Loads all players")
        func loadsAllPlayers() throws {
            let context = try TestHelpers.bootstrappedContext()
            TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            let viewModel = NewTournamentViewModel(context: context)
            
            #expect(viewModel.allPlayers.count == 4)
        }
        
        @Test("Starts with no players selected")
        func startsWithNoPlayersSelected() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            let viewModel = NewTournamentViewModel(context: context)
            
            for player in players {
                #expect(viewModel.isSelected(player) == false)
            }
        }
    }
    
    @Suite("togglePlayer")
    @MainActor
    struct TogglePlayerTests {
        
        @Test("Toggles player selection state")
        func togglesSelectionState() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            let viewModel = NewTournamentViewModel(context: context)
            let player = players[0]
            
            #expect(viewModel.isSelected(player) == false)
            
            viewModel.togglePlayer(player)
            #expect(viewModel.isSelected(player) == true)
            
            viewModel.togglePlayer(player)
            #expect(viewModel.isSelected(player) == false)
        }
    }
    
    @Suite("selectAll and deselectAll")
    @MainActor
    struct SelectAllDeselectAllTests {
        
        @Test("selectAll selects all players")
        func selectAllSelectsAll() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            let viewModel = NewTournamentViewModel(context: context)
            viewModel.selectAll()
            
            for player in players {
                #expect(viewModel.isSelected(player) == true)
            }
        }
        
        @Test("deselectAll deselects all players")
        func deselectAllDeselectsAll() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            let viewModel = NewTournamentViewModel(context: context)
            viewModel.selectAll()
            viewModel.deselectAll()
            
            for player in players {
                #expect(viewModel.isSelected(player) == false)
            }
        }
    }
    
    @Suite("addPlayer")
    @MainActor
    struct AddPlayerTests {
        
        @Test("Creates player and selects them")
        func createsAndSelects() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = NewTournamentViewModel(context: context)
            
            viewModel.newPlayerName = "New Player"
            viewModel.addPlayer()
            
            let addedPlayer = viewModel.allPlayers.first { $0.name == "New Player" }
            #expect(addedPlayer != nil)
            #expect(viewModel.isSelected(addedPlayer!) == true)
        }
        
        @Test("Clears input field after adding")
        func clearsInputField() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = NewTournamentViewModel(context: context)
            
            viewModel.newPlayerName = "New Player"
            viewModel.addPlayer()
            
            #expect(viewModel.newPlayerName == "")
        }
        
        @Test("Does not add player with empty name")
        func doesNotAddEmptyName() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = NewTournamentViewModel(context: context)
            let initialCount = viewModel.allPlayers.count
            
            viewModel.newPlayerName = "   "
            viewModel.addPlayer()
            
            #expect(viewModel.allPlayers.count == initialCount)
        }
    }
    
    @Suite("createTournament")
    @MainActor
    struct CreateTournamentTests {
        
        @Test("Creates tournament with selected players")
        func createsTournamentWithSelectedPlayers() throws {
            let context = try TestHelpers.bootstrappedContext()
            TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            let viewModel = NewTournamentViewModel(context: context)
            viewModel.tournamentName = "New Tournament"
            viewModel.totalWeeks = 8
            viewModel.randomAchievementsPerWeek = 3
            viewModel.selectAll()
            
            viewModel.createTournament()
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            #expect(tournament?.name == "New Tournament")
            #expect(tournament?.totalWeeks == 8)
            #expect(tournament?.randomAchievementsPerWeek == 3)
        }
        
        @Test("Sets screen to attendance after creation")
        func setsScreenToAttendance() throws {
            let context = try TestHelpers.bootstrappedContext()
            TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            let viewModel = NewTournamentViewModel(context: context)
            viewModel.tournamentName = "Test"
            viewModel.selectAll()
            viewModel.createTournament()
            
            let state = try TestHelpers.fetchLeagueState(from: context)
            #expect(state?.screen == .attendance)
        }
        
        @Test("Does not create without name")
        func doesNotCreateWithoutName() throws {
            let context = try TestHelpers.bootstrappedContext()
            TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            let viewModel = NewTournamentViewModel(context: context)
            viewModel.tournamentName = ""
            
            #expect(viewModel.canCreateTournament == false)
        }
        
        @Test("Does not create without players")
        func doesNotCreateWithoutPlayers() throws {
            let context = try TestHelpers.bootstrappedContext()
            TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            let viewModel = NewTournamentViewModel(context: context)
            viewModel.tournamentName = "Test"
            // No players selected by default
            
            #expect(viewModel.canCreateTournament == false)
        }
    }
    
    @Suite("cancel")
    @MainActor
    struct CancelTests {
        
        @Test("Returns to tournaments screen")
        func returnsToTournamentsScreen() throws {
            let context = try TestHelpers.bootstrappedContext()
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.currentScreen = Screen.newTournament.rawValue
            try context.save()
            
            let viewModel = NewTournamentViewModel(context: context)
            viewModel.cancel()
            
            let updatedState = try TestHelpers.fetchLeagueState(from: context)
            #expect(updatedState?.screen == .tournaments)
        }
    }
    
    @Suite("Computed Properties")
    @MainActor
    struct ComputedPropertiesTests {
        
        @Test("canCreateTournament requires name and players")
        func canCreateTournament() throws {
            let context = try TestHelpers.bootstrappedContext()
            TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            let viewModel = NewTournamentViewModel(context: context)
            
            // Has players but no name
            viewModel.selectAll()
            viewModel.tournamentName = ""
            #expect(viewModel.canCreateTournament == false)
            
            // Has name and players
            viewModel.tournamentName = "Test"
            #expect(viewModel.canCreateTournament == true)
            
            // Has name but no players
            viewModel.deselectAll()
            #expect(viewModel.canCreateTournament == false)
        }
        
        @Test("canAddPlayer requires non-empty name")
        func canAddPlayer() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = NewTournamentViewModel(context: context)
            
            viewModel.newPlayerName = ""
            #expect(viewModel.canAddPlayer == false)
            
            viewModel.newPlayerName = "   "
            #expect(viewModel.canAddPlayer == false)
            
            viewModel.newPlayerName = "Test"
            #expect(viewModel.canAddPlayer == true)
        }
        
        @Test("selectedPlayerCount returns correct count")
        func selectedPlayerCount() throws {
            let context = try TestHelpers.bootstrappedContext()
            TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            let viewModel = NewTournamentViewModel(context: context)
            #expect(viewModel.selectedPlayerCount == 0)
            
            viewModel.selectAll()
            #expect(viewModel.selectedPlayerCount == 4)
            
            viewModel.deselectAll()
            #expect(viewModel.selectedPlayerCount == 0)
        }
    }
}
