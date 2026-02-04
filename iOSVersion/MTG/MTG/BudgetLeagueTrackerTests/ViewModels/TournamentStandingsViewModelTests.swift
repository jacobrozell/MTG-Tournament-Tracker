import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Tests for TournamentStandingsViewModel
@Suite("TournamentStandingsViewModel Tests", .serialized)
@MainActor
struct TournamentStandingsViewModelTests {
    
    @Suite("refresh")
    @MainActor
    struct RefreshTests {
        
        @Test("Loads and sorts players by total points")
        func loadsAndSortsPlayers() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let players = [
                TestFixtures.player(name: "Third", placementPoints: 10, achievementPoints: 5),   // 15
                TestFixtures.player(name: "First", placementPoints: 50, achievementPoints: 20),  // 70
                TestFixtures.player(name: "Second", placementPoints: 30, achievementPoints: 10)  // 40
            ]
            
            for player in players {
                context.insert(player)
            }
            
            let tournament = TestFixtures.tournament()
            context.insert(tournament)
            
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = tournament.id
            try context.save()
            
            let viewModel = TournamentStandingsViewModel(context: context)
            
            #expect(viewModel.sortedPlayers.count == 3)
            #expect(viewModel.sortedPlayers[0].name == "First")
            #expect(viewModel.sortedPlayers[1].name == "Second")
            #expect(viewModel.sortedPlayers[2].name == "Third")
        }
        
        @Test("Updates tournament status display")
        func updatesTournamentStatus() throws {
            let context = try TestHelpers.contextWithTournament()
            
            let viewModel = TournamentStandingsViewModel(context: context)
            
            #expect(viewModel.tournamentName == "Test Tournament")
        }
    }
    
    @Suite("close")
    @MainActor
    struct CloseTests {
        
        @Test("Closes standings and returns to tournaments")
        func closesAndReturns() throws {
            let context = try TestHelpers.contextWithTournament()
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.currentScreen = Screen.tournamentStandings.rawValue
            try context.save()
            
            let viewModel = TournamentStandingsViewModel(context: context)
            viewModel.close()
            
            let updated = try TestHelpers.fetchLeagueState(from: context)
            #expect(updated?.activeTournamentId == nil)
            #expect(updated?.screen == .tournaments)
        }
    }
    
    @Suite("Computed Properties")
    @MainActor
    struct ComputedPropertiesTests {
        
        @Test("sortedPlayers reflects standings array")
        func sortedPlayersReflectsStandings() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = TournamentStandingsViewModel(context: context)
            
            #expect(viewModel.sortedPlayers.isEmpty == true)
            
            let player = TestFixtures.player()
            context.insert(player)
            
            let tournament = TestFixtures.tournament()
            context.insert(tournament)
            
            let state = try TestHelpers.fetchLeagueState(from: context)!
            state.activeTournamentId = tournament.id
            try context.save()
            
            viewModel.refresh()
            
            #expect(viewModel.sortedPlayers.isEmpty == false)
        }
    }
}
