import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

// MARK: - DEPRECATION NOTICE
// This test file tests PodsViewModel which has been deprecated.
// Pod management functionality has been moved to TournamentDetailViewModel.
// These tests are kept for backwards compatibility but should not be extended.
// New tests should be added to TournamentDetailViewModelTests.swift instead.
// See: TournamentDetailViewModelTests.swift for the replacement tests.

/// Tests for PodsViewModel
/// - Note: DEPRECATED - PodsViewModel has been replaced by TournamentDetailViewModel.
///   These tests are kept for backwards compatibility only.
@Suite("PodsViewModel Tests", .serialized)
@MainActor
struct PodsViewModelTests {
    
    @Suite("refresh")
    @MainActor
    struct RefreshTests {
        
        @Test("Loads players, achievements, and tournament state")
        func loadsState() throws {
            let context = try TestHelpers.contextWithTournament()
            TestFixtures.insertSampleAchievements(into: context)
            try context.save()
            
            let viewModel = PodsViewModel(context: context)
            
            #expect(viewModel.isLeagueStarted == true)
            #expect(viewModel.currentWeek == 1)
            #expect(viewModel.currentRound == 1)
        }
        
        @Test("Sets isLeagueStarted to false when no active tournament")
        func isLeagueStartedFalse() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let viewModel = PodsViewModel(context: context)
            
            #expect(viewModel.isLeagueStarted == false)
        }
    }
    
    @Suite("generatePods")
    @MainActor
    struct GeneratePodsTests {
        
        @Test("Generates pods correctly")
        func generatesPods() throws {
            let context = try TestHelpers.contextWithTournament(
                playerNames: ["A", "B", "C", "D", "E", "F", "G", "H"]
            )
            try context.save()
            
            let viewModel = PodsViewModel(context: context)
            viewModel.generatePods()
            
            #expect(viewModel.pods.count == 2)
            #expect(viewModel.pods[0].count == 4)
            #expect(viewModel.pods[1].count == 4)
        }
        
        @Test("Initializes default placements for each player")
        func initializesDefaultPlacements() throws {
            let context = try TestHelpers.contextWithTournament()
            try context.save()
            
            let viewModel = PodsViewModel(context: context)
            viewModel.generatePods()
            
            // Each player should have a placement
            let tournament = try TestHelpers.fetchActiveTournament(from: context)
            #expect(tournament?.roundPlacements.count == 4)
        }
    }
    
    @Suite("setPlacement and placement")
    @MainActor
    struct PlacementTests {
        
        @Test("Updates placement with auto-save")
        func updatesPlacement() throws {
            let context = try TestHelpers.contextWithTournament()
            try context.save()
            
            let viewModel = PodsViewModel(context: context)
            viewModel.generatePods()
            
            let playerId = viewModel.pods[0][0].id
            viewModel.setPlacement(for: playerId, place: 2)
            
            #expect(viewModel.placement(for: playerId) == 2)
        }
        
        @Test("Returns default 4 for unknown player")
        func returnsDefaultForUnknown() throws {
            let context = try TestHelpers.contextWithTournament()
            
            let viewModel = PodsViewModel(context: context)
            
            #expect(viewModel.placement(for: "unknown-id") == 4)
        }
    }
    
    @Suite("toggleAchievementCheck and isAchievementChecked")
    @MainActor
    struct AchievementCheckTests {
        
        @Test("Toggles achievement with auto-save")
        func togglesAchievement() throws {
            let context = try TestHelpers.contextWithTournament()
            let achievements = TestFixtures.insertSampleAchievements(into: context)
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            tournament.activeAchievementIds = achievements.map { $0.id }
            try context.save()
            
            let viewModel = PodsViewModel(context: context)
            viewModel.refresh()
            viewModel.generatePods()
            
            let playerId = viewModel.pods[0][0].id
            let achievementId = achievements[0].id
            
            #expect(viewModel.isAchievementChecked(playerId: playerId, achievementId: achievementId) == false)
            
            viewModel.toggleAchievementCheck(playerId: playerId, achievementId: achievementId)
            
            #expect(viewModel.isAchievementChecked(playerId: playerId, achievementId: achievementId) == true)
            
            viewModel.toggleAchievementCheck(playerId: playerId, achievementId: achievementId)
            
            #expect(viewModel.isAchievementChecked(playerId: playerId, achievementId: achievementId) == false)
        }
    }
    
    @Suite("editLastRound")
    @MainActor
    struct EditLastRoundTests {
        
        @Test("Calls engine and clears pods")
        func callsEngineAndClearsPods() throws {
            let context = try TestHelpers.contextWithTournament()
            try context.save()
            
            let viewModel = PodsViewModel(context: context)
            viewModel.generatePods()
            
            // Simulate a completed round
            LeagueEngine.nextRound(context: context)
            viewModel.refresh()
            
            #expect(viewModel.canEdit == true)
            
            viewModel.editLastRound()
            
            #expect(viewModel.pods.isEmpty)
        }
    }
    
    @Suite("nextRound")
    @MainActor
    struct NextRoundTests {
        
        @Test("Advances round correctly")
        func advancesRound() throws {
            let context = try TestHelpers.contextWithTournament()
            try context.save()
            
            let viewModel = PodsViewModel(context: context)
            viewModel.generatePods()
            
            viewModel.nextRound()
            viewModel.refresh()
            
            #expect(viewModel.currentRound == 2)
            #expect(viewModel.pods.isEmpty)
        }
    }
    
    @Suite("Computed Properties")
    @MainActor
    struct ComputedPropertiesTests {
        
        @Test("canGeneratePods requires present players")
        func canGeneratePods() throws {
            let context = try TestHelpers.contextWithTournament()
            try context.save()
            
            let viewModel = PodsViewModel(context: context)
            
            #expect(viewModel.canGeneratePods == true)
        }
        
        @Test("canEdit requires pod history")
        func canEdit() throws {
            let context = try TestHelpers.contextWithTournament()
            try context.save()
            
            let viewModel = PodsViewModel(context: context)
            
            #expect(viewModel.canEdit == false)
            
            viewModel.generatePods()
            LeagueEngine.nextRound(context: context)
            viewModel.refresh()
            
            #expect(viewModel.canEdit == true)
        }
        
        @Test("weeklyStandings returns sorted standings")
        func weeklyStandings() throws {
            let context = try TestHelpers.contextWithTournament()
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            let playerIds = tournament.presentPlayerIds
            
            // Set some weekly points
            tournament.weeklyPointsByPlayer = [
                playerIds[0]: WeeklyPlayerPoints(placementPoints: 10, achievementPoints: 2),
                playerIds[1]: WeeklyPlayerPoints(placementPoints: 5, achievementPoints: 1),
                playerIds[2]: WeeklyPlayerPoints(placementPoints: 8, achievementPoints: 3),
                playerIds[3]: WeeklyPlayerPoints(placementPoints: 3, achievementPoints: 0)
            ]
            try context.save()
            
            let viewModel = PodsViewModel(context: context)
            viewModel.refresh()
            
            let standings = viewModel.weeklyStandings
            
            #expect(standings.count == 4)
            // Should be sorted by total descending: 12, 11, 6, 3
            #expect(standings[0].points.total == 12)
            #expect(standings[1].points.total == 11)
        }
    }
}
