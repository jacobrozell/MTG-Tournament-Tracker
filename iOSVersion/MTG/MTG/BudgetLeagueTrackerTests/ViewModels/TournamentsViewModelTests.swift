import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Tests for TournamentsViewModel
@Suite("TournamentsViewModel Tests", .serialized)
@MainActor
struct TournamentsViewModelTests {
    
    @Suite("refresh")
    @MainActor
    struct RefreshTests {
        
        @Test("Loads ongoing and completed tournaments separately")
        func loadsTournamentsBySeparately() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            // Create ongoing tournament
            let ongoing = TestFixtures.tournament(name: "Ongoing")
            context.insert(ongoing)
            
            // Create completed tournament
            let completed = TestFixtures.completedTournament()
            context.insert(completed)
            
            try context.save()
            
            let viewModel = TournamentsViewModel(context: context)
            
            #expect(viewModel.ongoingTournaments.count == 1)
            #expect(viewModel.completedTournaments.count == 1)
            #expect(viewModel.ongoingTournaments.first?.name == "Ongoing")
            #expect(viewModel.completedTournaments.first?.name == "Completed Tournament")
        }
        
        @Test("Loads players for counts")
        func loadsPlayers() throws {
            let context = try TestHelpers.bootstrappedContext()
            TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            let viewModel = TournamentsViewModel(context: context)
            
            #expect(viewModel.players.count == 4)
        }
    }
    
    @Suite("playerCount")
    @MainActor
    struct PlayerCountTests {
        
        @Test("Returns present player count for ongoing tournament")
        func returnsCountForOngoing() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let tournament = TestFixtures.tournament()
            tournament.presentPlayerIds = ["p1", "p2", "p3"]
            context.insert(tournament)
            try context.save()
            
            let viewModel = TournamentsViewModel(context: context)
            let count = viewModel.playerCount(for: tournament)
            
            #expect(count == 3)
        }
        
        @Test("Returns unique player count from GameResults for completed")
        func returnsCountForCompleted() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let tournament = TestFixtures.completedTournament()
            context.insert(tournament)
            
            // Create game results
            let result1 = TestFixtures.gameResult(tournamentId: tournament.id, playerId: "p1", placement: 1)
            let result2 = TestFixtures.gameResult(tournamentId: tournament.id, playerId: "p2", placement: 2)
            let result3 = TestFixtures.gameResult(tournamentId: tournament.id, playerId: "p1", placement: 1) // duplicate player
            context.insert(result1)
            context.insert(result2)
            context.insert(result3)
            try context.save()
            
            let viewModel = TournamentsViewModel(context: context)
            let count = viewModel.playerCount(for: tournament)
            
            #expect(count == 2) // p1 and p2
        }
    }
    
    @Suite("winnerName")
    @MainActor
    struct WinnerNameTests {
        
        @Test("Returns winner name for completed tournament")
        func returnsWinnerName() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let winner = TestFixtures.player(name: "Winner")
            let loser = TestFixtures.player(name: "Loser")
            context.insert(winner)
            context.insert(loser)
            
            let tournament = TestFixtures.completedTournament()
            context.insert(tournament)
            
            // Winner has more points
            let result1 = TestFixtures.gameResult(tournamentId: tournament.id, playerId: winner.id, placement: 1) // 4 pts
            let result2 = TestFixtures.gameResult(tournamentId: tournament.id, playerId: loser.id, placement: 4)  // 1 pt
            context.insert(result1)
            context.insert(result2)
            try context.save()
            
            let viewModel = TournamentsViewModel(context: context)
            let name = viewModel.winnerName(for: tournament)
            
            #expect(name == "Winner")
        }
        
        @Test("Returns nil for ongoing tournament")
        func returnsNilForOngoing() throws {
            let context = try TestHelpers.bootstrappedContext()
            let tournament = TestFixtures.tournament() // ongoing by default
            context.insert(tournament)
            try context.save()
            
            let viewModel = TournamentsViewModel(context: context)
            let name = viewModel.winnerName(for: tournament)
            
            #expect(name == nil)
        }
    }
    
    @Suite("createNewTournament")
    @MainActor
    struct CreateNewTournamentTests {
        
        @Test("Sets screen to newTournament")
        func setsScreenToNewTournament() throws {
            let context = try TestHelpers.bootstrappedContext()
            let viewModel = TournamentsViewModel(context: context)
            
            viewModel.createNewTournament()
            
            let state = try TestHelpers.fetchLeagueState(from: context)
            #expect(state?.screen == .newTournament)
        }
    }
    
    @Suite("setActiveTournament")
    @MainActor
    struct SetActiveTournamentTests {
        
        @Test("Sets activeTournamentId in LeagueState")
        func setsActiveTournamentId() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let tournament = TestFixtures.tournament()
            context.insert(tournament)
            try context.save()
            
            let viewModel = TournamentsViewModel(context: context)
            viewModel.setActiveTournament(tournament)
            
            let state = try TestHelpers.fetchLeagueState(from: context)
            #expect(state?.activeTournamentId == tournament.id)
        }
        
        @Test("Saves context after setting active tournament")
        func savesContext() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let tournament = TestFixtures.tournament()
            context.insert(tournament)
            try context.save()
            
            let viewModel = TournamentsViewModel(context: context)
            viewModel.setActiveTournament(tournament)
            
            // Fetch fresh to verify persistence
            let state = try TestHelpers.fetchLeagueState(from: context)
            #expect(state?.activeTournamentId == tournament.id)
        }
        
        @Test("Does not change screen state - navigation handled by SwiftUI")
        func doesNotChangeScreen() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            // Set initial screen state
            let initialState = try TestHelpers.fetchLeagueState(from: context)
            let initialScreen = initialState?.screen ?? .tournaments
            
            let tournament = TestFixtures.tournament()
            context.insert(tournament)
            try context.save()
            
            let viewModel = TournamentsViewModel(context: context)
            viewModel.setActiveTournament(tournament)
            
            // Screen should not be changed by setActiveTournament
            let state = try TestHelpers.fetchLeagueState(from: context)
            #expect(state?.screen == initialScreen)
        }
    }
    
    @Suite("Computed Properties")
    @MainActor
    struct ComputedPropertiesTests {
        
        @Test("hasOngoingTournaments reflects ongoing count")
        func hasOngoingTournaments() throws {
            let context = try TestHelpers.bootstrappedContext()
            var viewModel = TournamentsViewModel(context: context)
            
            #expect(viewModel.hasOngoingTournaments == false)
            
            let tournament = TestFixtures.tournament()
            context.insert(tournament)
            try context.save()
            viewModel.refresh()
            
            #expect(viewModel.hasOngoingTournaments == true)
        }
        
        @Test("hasCompletedTournaments reflects completed count")
        func hasCompletedTournaments() throws {
            let context = try TestHelpers.bootstrappedContext()
            var viewModel = TournamentsViewModel(context: context)
            
            #expect(viewModel.hasCompletedTournaments == false)
            
            let tournament = TestFixtures.completedTournament()
            context.insert(tournament)
            try context.save()
            viewModel.refresh()
            
            #expect(viewModel.hasCompletedTournaments == true)
        }
        
        @Test("hasTournaments is true if either ongoing or completed exists")
        func hasTournaments() throws {
            let context = try TestHelpers.bootstrappedContext()
            var viewModel = TournamentsViewModel(context: context)
            
            #expect(viewModel.hasTournaments == false)
            
            let tournament = TestFixtures.tournament()
            context.insert(tournament)
            try context.save()
            viewModel.refresh()
            
            #expect(viewModel.hasTournaments == true)
        }
    }
}
