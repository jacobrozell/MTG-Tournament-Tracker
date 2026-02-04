import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Tests for TournamentDetailViewModel
/// This replaces the deprecated PodsViewModel tests with the new tournament detail view model.
@Suite("TournamentDetailViewModel Tests", .serialized)
@MainActor
struct TournamentDetailViewModelTests {
    
    @Suite("Initialization")
    @MainActor
    struct InitializationTests {
        
        @Test("Initializes with tournament data")
        func initializesWithTournament() throws {
            let context = try TestHelpers.contextWithTournament()
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.tournament != nil)
            #expect(viewModel.tournamentName == tournament.name)
        }
        
        @Test("Handles non-existent tournament gracefully")
        func handlesNonExistentTournament() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: "non-existent")
            
            #expect(viewModel.tournament == nil)
        }
    }
    
    @Suite("Tournament Properties")
    @MainActor
    struct TournamentPropertiesTests {
        
        @Test("isOngoing returns true for ongoing tournament")
        func isOngoingTrue() throws {
            let context = try TestHelpers.contextWithTournament()
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.isOngoing == true)
            #expect(viewModel.isCompleted == false)
        }
        
        @Test("isCompleted returns true for completed tournament")
        func isCompletedTrue() throws {
            let context = try TestHelpers.bootstrappedContext()
            let tournament = TestFixtures.completedTournament()
            context.insert(tournament)
            try context.save()
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.isCompleted == true)
            #expect(viewModel.isOngoing == false)
        }
        
        @Test("weekProgressString formats correctly")
        func weekProgressString() throws {
            let context = try TestHelpers.contextWithTournament()
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.weekProgressString.contains("Week"))
            #expect(viewModel.weekProgressString.contains("of"))
        }
        
        @Test("roundString formats correctly")
        func roundString() throws {
            let context = try TestHelpers.contextWithTournament()
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.roundString.contains("Round"))
        }
    }
    
    @Suite("hasPresentPlayers")
    @MainActor
    struct HasPresentPlayersTests {
        
        @Test("Returns true when players are present")
        func returnsTrueWithPlayers() throws {
            let context = try TestHelpers.contextWithTournament()
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            tournament.presentPlayerIds = ["p1", "p2", "p3"]
            try context.save()
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.hasPresentPlayers == true)
        }
        
        @Test("Returns false when no players are present")
        func returnsFalseWithNoPlayers() throws {
            let context = try TestHelpers.contextWithTournament()
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            tournament.presentPlayerIds = []
            try context.save()
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.hasPresentPlayers == false)
        }
    }
    
    @Suite("canGeneratePods")
    @MainActor
    struct CanGeneratePodsTests {
        
        @Test("Returns true when players are present")
        func returnsTrueWithPlayers() throws {
            let context = try TestHelpers.contextWithTournament()
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            tournament.presentPlayerIds = ["p1", "p2", "p3", "p4"]
            try context.save()
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.canGeneratePods == true)
        }
        
        @Test("Returns false when no players are present")
        func returnsFalseWithNoPlayers() throws {
            let context = try TestHelpers.contextWithTournament()
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            tournament.presentPlayerIds = []
            try context.save()
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.canGeneratePods == false)
        }
    }
    
    @Suite("generatePods")
    @MainActor
    struct GeneratePodsTests {
        
        @Test("Generates pods from present players")
        func generatesPods() throws {
            let context = try TestHelpers.contextWithTournament()
            let players = TestFixtures.insertStandardPlayers(into: context)
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            tournament.presentPlayerIds = players.map { $0.id }
            try context.save()
            
            var viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            viewModel.generatePods()
            
            #expect(!viewModel.pods.isEmpty)
            #expect(viewModel.pods[0].count == 4) // Standard 4-player pod
        }
        
        @Test("Does nothing when no tournament")
        func doesNothingWithNoTournament() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            var viewModel = TournamentDetailViewModel(context: context, tournamentId: "non-existent")
            viewModel.generatePods()
            
            #expect(viewModel.pods.isEmpty)
        }
    }
    
    @Suite("placement")
    @MainActor
    struct PlacementTests {
        
        @Test("Returns default placement of 4")
        func returnsDefaultPlacement() throws {
            let context = try TestHelpers.contextWithTournament()
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.placement(for: "unknown-player") == 4)
        }
        
        @Test("setPlacement updates tournament data")
        func setPlacementUpdates() throws {
            let context = try TestHelpers.contextWithTournament()
            let players = TestFixtures.insertStandardPlayers(into: context)
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            tournament.presentPlayerIds = players.map { $0.id }
            try context.save()
            
            let playerId = players[0].id
            var viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            viewModel.setPlacement(for: playerId, place: 1)
            
            #expect(viewModel.placement(for: playerId) == 1)
        }
    }
    
    @Suite("achievementChecks")
    @MainActor
    struct AchievementChecksTests {
        
        @Test("isAchievementChecked returns false by default")
        func returnsFalseByDefault() throws {
            let context = try TestHelpers.contextWithTournament()
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.isAchievementChecked(playerId: "p1", achievementId: "a1") == false)
        }
        
        @Test("toggleAchievementCheck toggles state")
        func togglesState() throws {
            let context = try TestHelpers.contextWithTournament()
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            TestFixtures.insertSampleAchievements(into: context)
            try context.save()
            
            var viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            let wasChecked = viewModel.isAchievementChecked(playerId: "p1", achievementId: "a1")
            viewModel.toggleAchievementCheck(playerId: "p1", achievementId: "a1")
            
            #expect(viewModel.isAchievementChecked(playerId: "p1", achievementId: "a1") != wasChecked)
        }
    }
    
    @Suite("canEdit")
    @MainActor
    struct CanEditTests {
        
        @Test("Returns false when no history")
        func returnsFalseWithNoHistory() throws {
            let context = try TestHelpers.contextWithTournament()
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            tournament.podHistorySnapshots = []
            try context.save()
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.canEdit == false)
        }
    }
    
    @Suite("weeklyStandings")
    @MainActor
    struct WeeklyStandingsTests {
        
        @Test("Returns empty when no present players")
        func returnsEmptyWithNoPlayers() throws {
            let context = try TestHelpers.contextWithTournament()
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            tournament.presentPlayerIds = []
            try context.save()
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.weeklyStandings.isEmpty)
        }
        
        @Test("Returns standings for present players")
        func returnsStandingsForPresentPlayers() throws {
            let context = try TestHelpers.contextWithTournament()
            let players = TestFixtures.insertStandardPlayers(into: context)
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            tournament.presentPlayerIds = players.map { $0.id }
            try context.save()
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.weeklyStandings.count == players.count)
        }
    }
    
    @Suite("finalStandings")
    @MainActor
    struct FinalStandingsTests {
        
        @Test("Returns empty for ongoing tournament")
        func returnsEmptyForOngoing() throws {
            let context = try TestHelpers.contextWithTournament()
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.finalStandings.isEmpty)
        }
        
        @Test("Returns standings for completed tournament with results")
        func returnsStandingsForCompleted() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let player1 = TestFixtures.player(name: "Winner")
            let player2 = TestFixtures.player(name: "Loser")
            context.insert(player1)
            context.insert(player2)
            
            let tournament = TestFixtures.completedTournament()
            context.insert(tournament)
            
            // Add game results
            let result1 = TestFixtures.gameResult(tournamentId: tournament.id, playerId: player1.id, placement: 1)
            let result2 = TestFixtures.gameResult(tournamentId: tournament.id, playerId: player2.id, placement: 4)
            context.insert(result1)
            context.insert(result2)
            try context.save()
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.finalStandings.count == 2)
            #expect(viewModel.finalStandings[0].player.name == "Winner") // Higher points first
        }
    }
    
    @Suite("winnerName")
    @MainActor
    struct WinnerNameTests {
        
        @Test("Returns winner name for completed tournament")
        func returnsWinnerName() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let player1 = TestFixtures.player(name: "Champion")
            let player2 = TestFixtures.player(name: "Runner Up")
            context.insert(player1)
            context.insert(player2)
            
            let tournament = TestFixtures.completedTournament()
            context.insert(tournament)
            
            let result1 = TestFixtures.gameResult(tournamentId: tournament.id, playerId: player1.id, placement: 1)
            let result2 = TestFixtures.gameResult(tournamentId: tournament.id, playerId: player2.id, placement: 4)
            context.insert(result1)
            context.insert(result2)
            try context.save()
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.winnerName == "Champion")
        }
        
        @Test("Returns nil for ongoing tournament")
        func returnsNilForOngoing() throws {
            let context = try TestHelpers.contextWithTournament()
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.winnerName == nil)
        }
    }
    
    @Suite("setAsActiveTournament")
    @MainActor
    struct SetAsActiveTournamentTests {
        
        @Test("Sets activeTournamentId in LeagueState")
        func setsActiveTournamentId() throws {
            let context = try TestHelpers.contextWithTournament()
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            
            // Create a different tournament
            let otherTournament = TestFixtures.tournament(name: "Other")
            context.insert(otherTournament)
            try context.save()
            
            var viewModel = TournamentDetailViewModel(context: context, tournamentId: otherTournament.id)
            viewModel.setAsActiveTournament()
            
            let state = try TestHelpers.fetchLeagueState(from: context)
            #expect(state?.activeTournamentId == otherTournament.id)
        }
    }
    
    @Suite("goToAttendance")
    @MainActor
    struct GoToAttendanceTests {
        
        @Test("Sets active tournament and shows attendance sheet")
        func setsActiveTournamentAndShowsAttendanceSheet() throws {
            let context = try TestHelpers.contextWithTournament()
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            
            let viewModel = TournamentDetailViewModel(context: context, tournamentId: tournament.id)
            #expect(viewModel.showAttendance == false)
            
            viewModel.goToAttendance()
            
            // goToAttendance() sets active tournament and presents attendance via sheet (showAttendance), not global screen
            let state = try TestHelpers.fetchLeagueState(from: context)
            #expect(state?.activeTournamentId == tournament.id)
            #expect(viewModel.showAttendance == true)
        }
    }
}
