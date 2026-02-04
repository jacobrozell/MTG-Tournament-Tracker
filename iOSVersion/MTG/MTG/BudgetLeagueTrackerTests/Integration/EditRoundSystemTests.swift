import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Integration tests for the edit round system
@Suite("Edit Round System Integration Tests", .serialized)
@MainActor
struct EditRoundSystemTests {
    
    @Test("Edit single round updates stats correctly")
    func editSingleRound() async throws {
        let context = try TestHelpers.bootstrappedContext()
        let players = TestFixtures.insertStandardPlayers(into: context)
        try context.save()
        
        LeagueEngine.createTournament(
            context: context,
            name: "Edit Test",
            totalWeeks: 1,
            randomPerWeek: 0,
            playerIds: players.map { $0.id }
        )
        
        LeagueEngine.confirmAttendance(
            context: context,
            presentIds: players.map { $0.id },
            achievementsOnThisWeek: false
        )
        
        // Complete a round: Player 0 wins
        LeagueEngine.updatePlacement(context: context, playerId: players[0].id, placement: 1)
        LeagueEngine.updatePlacement(context: context, playerId: players[1].id, placement: 2)
        LeagueEngine.updatePlacement(context: context, playerId: players[2].id, placement: 3)
        LeagueEngine.updatePlacement(context: context, playerId: players[3].id, placement: 4)
        LeagueEngine.finalizeRound(context: context)
        
        // Verify initial stats
        #expect(players[0].placementPoints == 4)
        #expect(players[0].wins == 1)
        #expect(players[1].placementPoints == 3)
        #expect(players[1].wins == 0)
        
        // Edit round: Change so Player 1 wins instead
        let newPlacements: [String: Int] = [
            players[0].id: 2,
            players[1].id: 1,
            players[2].id: 3,
            players[3].id: 4
        ]
        LeagueEngine.applyEditedRound(
            context: context,
            newPlacements: newPlacements,
            newAchievementChecks: []
        )
        
        // Verify stats updated correctly
        #expect(players[0].placementPoints == 3) // Changed from 1st (4pts) to 2nd (3pts)
        #expect(players[0].wins == 0) // No longer a win
        #expect(players[1].placementPoints == 4) // Changed from 2nd (3pts) to 1st (4pts)
        #expect(players[1].wins == 1) // Now has the win
    }
    
    @Test("Edit placements updates deltas correctly")
    func editPlacementsUpdatesDeltasCorrectly() async throws {
        let context = try TestHelpers.bootstrappedContext()
        let players = TestFixtures.insertStandardPlayers(into: context)
        try context.save()
        
        LeagueEngine.createTournament(
            context: context,
            name: "Edit Placements Test",
            totalWeeks: 1,
            randomPerWeek: 0,
            playerIds: players.map { $0.id }
        )
        
        LeagueEngine.confirmAttendance(
            context: context,
            presentIds: players.map { $0.id },
            achievementsOnThisWeek: false
        )
        
        // Complete a round with all players getting 4th place (1 point each)
        for player in players {
            LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: 4)
        }
        LeagueEngine.finalizeRound(context: context)
        
        // All should have 1 point
        for player in players {
            #expect(player.placementPoints == 1)
        }
        
        // Edit to give different placements
        let newPlacements: [String: Int] = [
            players[0].id: 1, // 4 pts
            players[1].id: 2, // 3 pts
            players[2].id: 3, // 2 pts
            players[3].id: 4  // 1 pt
        ]
        LeagueEngine.applyEditedRound(
            context: context,
            newPlacements: newPlacements,
            newAchievementChecks: []
        )
        
        // Verify correct points
        #expect(players[0].placementPoints == 4)
        #expect(players[1].placementPoints == 3)
        #expect(players[2].placementPoints == 2)
        #expect(players[3].placementPoints == 1)
    }
    
    @Test("Edit achievements updates points correctly")
    func editAchievementsUpdatesPoints() async throws {
        let context = try TestHelpers.bootstrappedContext()
        let players = TestFixtures.insertStandardPlayers(into: context)
        let achievement = TestFixtures.achievement(name: "Test Ach", points: 3, alwaysOn: true)
        context.insert(achievement)
        try context.save()
        
        LeagueEngine.createTournament(
            context: context,
            name: "Edit Achievements Test",
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
        
        // Player 0 gets achievement, Player 1 does not
        LeagueEngine.updatePlacement(context: context, playerId: players[0].id, placement: 1)
        LeagueEngine.updatePlacement(context: context, playerId: players[1].id, placement: 2)
        LeagueEngine.updatePlacement(context: context, playerId: players[2].id, placement: 3)
        LeagueEngine.updatePlacement(context: context, playerId: players[3].id, placement: 4)
        LeagueEngine.updateAchievementCheck(
            context: context,
            playerId: players[0].id,
            achievementId: achievement.id,
            checked: true
        )
        LeagueEngine.finalizeRound(context: context)
        
        // Verify initial state
        #expect(players[0].achievementPoints == 3)
        #expect(players[1].achievementPoints == 0)
        
        // Edit: Remove achievement from Player 0, give to Player 1
        let newPlacements: [String: Int] = [
            players[0].id: 1,
            players[1].id: 2,
            players[2].id: 3,
            players[3].id: 4
        ]
        let newChecks: Set<String> = ["\(players[1].id):\(achievement.id)"]
        
        LeagueEngine.applyEditedRound(
            context: context,
            newPlacements: newPlacements,
            newAchievementChecks: newChecks
        )
        
        // Verify achievement points swapped
        #expect(players[0].achievementPoints == 0)
        #expect(players[1].achievementPoints == 3)
    }
    
    @Test("Edit preserves other rounds' data")
    func editPreservesOtherRounds() async throws {
        let context = try TestHelpers.bootstrappedContext()
        let players = TestFixtures.insertStandardPlayers(into: context)
        try context.save()
        
        LeagueEngine.createTournament(
            context: context,
            name: "Preserve Test",
            totalWeeks: 1,
            randomPerWeek: 0,
            playerIds: players.map { $0.id }
        )
        
        LeagueEngine.confirmAttendance(
            context: context,
            presentIds: players.map { $0.id },
            achievementsOnThisWeek: false
        )
        
        // Round 1: Player 0 wins (4 pts)
        LeagueEngine.updatePlacement(context: context, playerId: players[0].id, placement: 1)
        LeagueEngine.updatePlacement(context: context, playerId: players[1].id, placement: 2)
        LeagueEngine.updatePlacement(context: context, playerId: players[2].id, placement: 3)
        LeagueEngine.updatePlacement(context: context, playerId: players[3].id, placement: 4)
        LeagueEngine.finalizeRound(context: context)
        
        // Round 2: Player 1 wins (4 pts) - this is the round we'll edit
        LeagueEngine.updatePlacement(context: context, playerId: players[1].id, placement: 1)
        LeagueEngine.updatePlacement(context: context, playerId: players[0].id, placement: 2)
        LeagueEngine.updatePlacement(context: context, playerId: players[2].id, placement: 3)
        LeagueEngine.updatePlacement(context: context, playerId: players[3].id, placement: 4)
        LeagueEngine.finalizeRound(context: context)
        
        // Before edit: Player 0 has 4+3=7 pts, Player 1 has 3+4=7 pts
        #expect(players[0].placementPoints == 7)
        #expect(players[1].placementPoints == 7)
        
        // Edit Round 2: Player 0 wins instead
        let newPlacements: [String: Int] = [
            players[0].id: 1,
            players[1].id: 2,
            players[2].id: 3,
            players[3].id: 4
        ]
        LeagueEngine.applyEditedRound(
            context: context,
            newPlacements: newPlacements,
            newAchievementChecks: []
        )
        
        // After edit: Player 0 has 4+4=8 pts, Player 1 has 3+3=6 pts
        #expect(players[0].placementPoints == 8)
        #expect(players[1].placementPoints == 6)
        #expect(players[0].wins == 2)
        #expect(players[1].wins == 0)
    }
    
    @Test("Edit updates GameResult records")
    func editUpdatesGameResults() async throws {
        let context = try TestHelpers.bootstrappedContext()
        let players = TestFixtures.insertStandardPlayers(into: context)
        try context.save()
        
        LeagueEngine.createTournament(
            context: context,
            name: "GameResult Update Test",
            totalWeeks: 1,
            randomPerWeek: 0,
            playerIds: players.map { $0.id }
        )
        
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
        
        // Verify GameResults exist
        var results = try TestHelpers.fetchAll(GameResult.self, from: context)
        #expect(results.count == 4)
        
        // Verify Player 0 has placement 1
        let player0Result = results.first { $0.playerId == players[0].id }!
        #expect(player0Result.placement == 1)
        #expect(player0Result.placementPoints == 4)
        
        // Edit: Swap placements
        let newPlacements: [String: Int] = [
            players[0].id: 4,
            players[1].id: 3,
            players[2].id: 2,
            players[3].id: 1
        ]
        LeagueEngine.applyEditedRound(
            context: context,
            newPlacements: newPlacements,
            newAchievementChecks: []
        )
        
        // Verify GameResults still exist (same count)
        results = try TestHelpers.fetchAll(GameResult.self, from: context)
        #expect(results.count == 4)
        
        // Verify Player 0 now has placement 4
        let updatedPlayer0Result = results.first { $0.playerId == players[0].id }!
        #expect(updatedPlayer0Result.placement == 4)
        #expect(updatedPlayer0Result.placementPoints == 1)
    }
    
    @Test("Edit updates weekly points correctly")
    func editWeeklyPoints() async throws {
        let context = try TestHelpers.bootstrappedContext()
        let players = TestFixtures.insertStandardPlayers(into: context)
        try context.save()
        
        LeagueEngine.createTournament(
            context: context,
            name: "Weekly Edit Test",
            totalWeeks: 1,
            randomPerWeek: 0,
            playerIds: players.map { $0.id }
        )
        
        LeagueEngine.confirmAttendance(
            context: context,
            presentIds: players.map { $0.id },
            achievementsOnThisWeek: false
        )
        
        // Round 1
        for (index, player) in players.enumerated() {
            LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: index + 1)
        }
        LeagueEngine.finalizeRound(context: context)
        
        var tournament = try TestHelpers.fetchActiveTournament(from: context)!
        #expect(tournament.weeklyPointsByPlayer[players[0].id]!.placementPoints == 4)
        
        // Edit Round 1: Change Player 0 from 1st to 4th
        let newPlacements: [String: Int] = [
            players[0].id: 4,
            players[1].id: 1,
            players[2].id: 2,
            players[3].id: 3
        ]
        LeagueEngine.applyEditedRound(
            context: context,
            newPlacements: newPlacements,
            newAchievementChecks: []
        )
        
        tournament = try TestHelpers.fetchActiveTournament(from: context)!
        #expect(tournament.weeklyPointsByPlayer[players[0].id]!.placementPoints == 1)
        #expect(tournament.weeklyPointsByPlayer[players[1].id]!.placementPoints == 4)
    }
    
    @Test("Multiple edits work correctly")
    func multipleEdits() async throws {
        let context = try TestHelpers.bootstrappedContext()
        let players = TestFixtures.insertStandardPlayers(into: context)
        try context.save()
        
        LeagueEngine.createTournament(
            context: context,
            name: "Multiple Edit Test",
            totalWeeks: 1,
            randomPerWeek: 0,
            playerIds: players.map { $0.id }
        )
        
        LeagueEngine.confirmAttendance(
            context: context,
            presentIds: players.map { $0.id },
            achievementsOnThisWeek: false
        )
        
        // Complete a round: Player 0 wins
        for (index, player) in players.enumerated() {
            LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: index + 1)
        }
        LeagueEngine.finalizeRound(context: context)
        
        #expect(players[0].placementPoints == 4)
        
        // First edit: Player 1 wins
        var newPlacements: [String: Int] = [
            players[0].id: 2,
            players[1].id: 1,
            players[2].id: 3,
            players[3].id: 4
        ]
        LeagueEngine.applyEditedRound(context: context, newPlacements: newPlacements, newAchievementChecks: [])
        
        #expect(players[0].placementPoints == 3)
        #expect(players[1].placementPoints == 4)
        
        // Second edit: Player 2 wins
        newPlacements = [
            players[0].id: 3,
            players[1].id: 2,
            players[2].id: 1,
            players[3].id: 4
        ]
        LeagueEngine.applyEditedRound(context: context, newPlacements: newPlacements, newAchievementChecks: [])
        
        #expect(players[0].placementPoints == 2)
        #expect(players[1].placementPoints == 3)
        #expect(players[2].placementPoints == 4)
        #expect(players[2].wins == 1)
    }
    
    @Test("Cannot edit when no history")
    func cannotEditWithNoHistory() async throws {
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
        
        LeagueEngine.confirmAttendance(
            context: context,
            presentIds: players.map { $0.id },
            achievementsOnThisWeek: false
        )
        
        let tournament = try TestHelpers.fetchActiveTournament(from: context)!
        #expect(tournament.podHistorySnapshots.isEmpty)
        
        // Edit should be no-op when no history
        let newPlacements: [String: Int] = [
            players[0].id: 1,
            players[1].id: 2,
            players[2].id: 3,
            players[3].id: 4
        ]
        LeagueEngine.applyEditedRound(context: context, newPlacements: newPlacements, newAchievementChecks: [])
        
        // Verify nothing changed
        for player in players {
            #expect(player.placementPoints == 0)
        }
    }
    
    @Test("Snapshot is replaced not removed after edit")
    func snapshotReplacedNotRemoved() async throws {
        let context = try TestHelpers.bootstrappedContext()
        let players = TestFixtures.insertStandardPlayers(into: context)
        try context.save()
        
        LeagueEngine.createTournament(
            context: context,
            name: "Snapshot Test",
            totalWeeks: 1,
            randomPerWeek: 0,
            playerIds: players.map { $0.id }
        )
        
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
        
        var tournament = try TestHelpers.fetchActiveTournament(from: context)!
        #expect(tournament.podHistorySnapshots.count == 1)
        
        // Edit the round
        let newPlacements: [String: Int] = [
            players[0].id: 4,
            players[1].id: 3,
            players[2].id: 2,
            players[3].id: 1
        ]
        LeagueEngine.applyEditedRound(context: context, newPlacements: newPlacements, newAchievementChecks: [])
        
        // Snapshot count should still be 1 (replaced, not added)
        tournament = try TestHelpers.fetchActiveTournament(from: context)!
        #expect(tournament.podHistorySnapshots.count == 1)
        
        // Verify the snapshot has updated placements
        let snapshot = tournament.podHistorySnapshots.first!
        #expect(snapshot.placements[players[0].id] == 4)
        #expect(snapshot.placements[players[3].id] == 1)
    }
}
