import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Tests for EditLastRoundViewModel
@Suite("EditLastRoundViewModel Tests", .serialized)
@MainActor
struct EditLastRoundViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Suite("Initialization")
    @MainActor
    struct InitializationTests {
        
        @Test("Loads snapshot data correctly")
        func loadsSnapshotData() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            LeagueEngine.createTournament(
                context: context,
                name: "Edit VM Test",
                totalWeeks: 1,
                randomPerWeek: 0,
                playerIds: players.map { $0.id }
            )
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            
            LeagueEngine.confirmAttendance(
                context: context,
                presentIds: players.map { $0.id },
                achievementsOnThisWeek: false
            )
            
            // Complete a round
            for (index, player) in players.enumerated() {
                LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: index + 1)
            }
            LeagueEngine.finalizeRound(context: context)
            
            // Create ViewModel
            let viewModel = EditLastRoundViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.hasRoundToEdit == true)
            #expect(viewModel.players.count == 4)
            #expect(viewModel.placement(for: players[0].id) == 1)
            #expect(viewModel.placement(for: players[1].id) == 2)
        }
        
        @Test("Returns hasRoundToEdit false when no history")
        func noHistoryReturnsNoRoundToEdit() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            LeagueEngine.createTournament(
                context: context,
                name: "No History Test",
                totalWeeks: 1,
                randomPerWeek: 0,
                playerIds: players.map { $0.id }
            )
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            
            LeagueEngine.confirmAttendance(
                context: context,
                presentIds: players.map { $0.id },
                achievementsOnThisWeek: false
            )
            
            // Don't finalize any round - no history
            let viewModel = EditLastRoundViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.hasRoundToEdit == false)
            #expect(viewModel.players.isEmpty)
        }
    }
    
    // MARK: - Placement Tests
    
    @Suite("Placement Methods")
    @MainActor
    struct PlacementTests {
        
        @Test("placement(for:) returns pre-populated values")
        func placementReturnsPrePopulatedValues() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            LeagueEngine.createTournament(
                context: context,
                name: "Placement Test",
                totalWeeks: 1,
                randomPerWeek: 0,
                playerIds: players.map { $0.id }
            )
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            
            LeagueEngine.confirmAttendance(
                context: context,
                presentIds: players.map { $0.id },
                achievementsOnThisWeek: false
            )
            
            // Set specific placements
            LeagueEngine.updatePlacement(context: context, playerId: players[0].id, placement: 3)
            LeagueEngine.updatePlacement(context: context, playerId: players[1].id, placement: 1)
            LeagueEngine.updatePlacement(context: context, playerId: players[2].id, placement: 4)
            LeagueEngine.updatePlacement(context: context, playerId: players[3].id, placement: 2)
            LeagueEngine.finalizeRound(context: context)
            
            let viewModel = EditLastRoundViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.placement(for: players[0].id) == 3)
            #expect(viewModel.placement(for: players[1].id) == 1)
            #expect(viewModel.placement(for: players[2].id) == 4)
            #expect(viewModel.placement(for: players[3].id) == 2)
        }
        
        @Test("setPlacement(for:place:) updates local state")
        func setPlacementUpdatesLocalState() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            LeagueEngine.createTournament(
                context: context,
                name: "Set Placement Test",
                totalWeeks: 1,
                randomPerWeek: 0,
                playerIds: players.map { $0.id }
            )
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            
            LeagueEngine.confirmAttendance(
                context: context,
                presentIds: players.map { $0.id },
                achievementsOnThisWeek: false
            )
            
            // Complete a round
            for (index, player) in players.enumerated() {
                LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: index + 1)
            }
            LeagueEngine.finalizeRound(context: context)
            
            let viewModel = EditLastRoundViewModel(context: context, tournamentId: tournament.id)
            
            // Initial placement
            #expect(viewModel.placement(for: players[0].id) == 1)
            
            // Change placement
            viewModel.setPlacement(for: players[0].id, place: 4)
            
            // Verify local state updated
            #expect(viewModel.placement(for: players[0].id) == 4)
        }
    }
    
    // MARK: - Achievement Tests
    
    @Suite("Achievement Methods")
    @MainActor
    struct AchievementTests {
        
        @Test("isAchievementChecked returns pre-populated values")
        func isAchievementCheckedReturnsPrePopulatedValues() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            let achievement = TestFixtures.achievement(name: "Test Ach", points: 2, alwaysOn: true)
            context.insert(achievement)
            try context.save()
            
            LeagueEngine.createTournament(
                context: context,
                name: "Achievement Check Test",
                totalWeeks: 1,
                randomPerWeek: 0,
                playerIds: players.map { $0.id }
            )
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            tournament.activeAchievementIds = [achievement.id]
            try context.save()
            
            LeagueEngine.confirmAttendance(
                context: context,
                presentIds: players.map { $0.id },
                achievementsOnThisWeek: true
            )
            
            // Player 0 gets achievement, others don't
            for (index, player) in players.enumerated() {
                LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: index + 1)
            }
            LeagueEngine.updateAchievementCheck(
                context: context,
                playerId: players[0].id,
                achievementId: achievement.id,
                checked: true
            )
            LeagueEngine.finalizeRound(context: context)
            
            let viewModel = EditLastRoundViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.isAchievementChecked(playerId: players[0].id, achievementId: achievement.id) == true)
            #expect(viewModel.isAchievementChecked(playerId: players[1].id, achievementId: achievement.id) == false)
        }
        
        @Test("toggleAchievementCheck updates local state")
        func toggleAchievementCheckUpdatesLocalState() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            let achievement = TestFixtures.achievement(name: "Toggle Ach", points: 2, alwaysOn: true)
            context.insert(achievement)
            try context.save()
            
            LeagueEngine.createTournament(
                context: context,
                name: "Toggle Achievement Test",
                totalWeeks: 1,
                randomPerWeek: 0,
                playerIds: players.map { $0.id }
            )
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            tournament.activeAchievementIds = [achievement.id]
            try context.save()
            
            LeagueEngine.confirmAttendance(
                context: context,
                presentIds: players.map { $0.id },
                achievementsOnThisWeek: true
            )
            
            // No achievements checked initially
            for (index, player) in players.enumerated() {
                LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: index + 1)
            }
            LeagueEngine.finalizeRound(context: context)
            
            let viewModel = EditLastRoundViewModel(context: context, tournamentId: tournament.id)
            
            // Initially not checked
            #expect(viewModel.isAchievementChecked(playerId: players[0].id, achievementId: achievement.id) == false)
            
            // Toggle on
            viewModel.toggleAchievementCheck(playerId: players[0].id, achievementId: achievement.id)
            #expect(viewModel.isAchievementChecked(playerId: players[0].id, achievementId: achievement.id) == true)
            
            // Toggle off
            viewModel.toggleAchievementCheck(playerId: players[0].id, achievementId: achievement.id)
            #expect(viewModel.isAchievementChecked(playerId: players[0].id, achievementId: achievement.id) == false)
        }
    }
    
    // MARK: - Save Tests
    
    @Suite("Save Method")
    @MainActor
    struct SaveTests {
        
        @Test("save() calls engine with correct parameters")
        func saveCallsEngineCorrectly() throws {
            let context = try TestHelpers.bootstrappedContext()
            let players = TestFixtures.insertStandardPlayers(into: context)
            try context.save()
            
            LeagueEngine.createTournament(
                context: context,
                name: "Save Test",
                totalWeeks: 1,
                randomPerWeek: 0,
                playerIds: players.map { $0.id }
            )
            
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            
            LeagueEngine.confirmAttendance(
                context: context,
                presentIds: players.map { $0.id },
                achievementsOnThisWeek: false
            )
            
            // Complete a round: Player 0 wins (4 pts)
            for (index, player) in players.enumerated() {
                LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: index + 1)
            }
            LeagueEngine.finalizeRound(context: context)
            
            #expect(players[0].placementPoints == 4)
            #expect(players[0].wins == 1)
            
            let viewModel = EditLastRoundViewModel(context: context, tournamentId: tournament.id)
            
            // Edit: Player 1 wins instead
            viewModel.setPlacement(for: players[0].id, place: 2)
            viewModel.setPlacement(for: players[1].id, place: 1)
            
            // Save
            viewModel.save()
            
            // Verify stats changed
            #expect(players[0].placementPoints == 3) // 2nd place
            #expect(players[0].wins == 0) // No longer a win
            #expect(players[1].placementPoints == 4) // 1st place
            #expect(players[1].wins == 1) // Now has the win
        }
    }
    
    // MARK: - Computed Properties Tests
    
    @Suite("Computed Properties")
    @MainActor
    struct ComputedPropertiesTests {
        
        @Test("title returns correct round number")
        func titleReturnsCorrectRoundNumber() throws {
            let context = try TestHelpers.contextWithTournament(round: 2)
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            let players = try TestHelpers.fetchAll(Player.self, from: context)
            
            // Complete a round
            for (index, player) in players.enumerated() {
                LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: index + 1)
            }
            LeagueEngine.finalizeRound(context: context)
            
            let viewModel = EditLastRoundViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.title == "Edit Round 2")
        }
        
        @Test("subtitle returns correct week number")
        func subtitleReturnsCorrectWeekNumber() throws {
            let context = try TestHelpers.contextWithTournament(week: 3, round: 1)
            let tournament = try TestHelpers.fetchActiveTournament(from: context)!
            let players = try TestHelpers.fetchAll(Player.self, from: context)
            
            // Complete a round
            for (index, player) in players.enumerated() {
                LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: index + 1)
            }
            LeagueEngine.finalizeRound(context: context)
            
            let viewModel = EditLastRoundViewModel(context: context, tournamentId: tournament.id)
            
            #expect(viewModel.subtitle == "Week 3")
        }
    }
}
