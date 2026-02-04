import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Integration tests for scoring calculations
@Suite("Scoring Integration Tests", .serialized)
@MainActor
struct ScoringIntegrationTests {
    
    @Test("Placement points accumulation: 1st=4, 2nd=3, 3rd=2, 4th=1")
    func placementPointsAccumulation() async throws {
        let context = try TestHelpers.bootstrappedContext()
        let players = TestFixtures.insertStandardPlayers(into: context)
        try context.save()
        
        // Create tournament
        LeagueEngine.createTournament(
            context: context,
            name: "Scoring Test",
            totalWeeks: 1,
            randomPerWeek: 0,
            playerIds: players.map { $0.id }
        )
        
        LeagueEngine.confirmAttendance(
            context: context,
            presentIds: players.map { $0.id },
            achievementsOnThisWeek: false
        )
        
        // Set specific placements
        LeagueEngine.updatePlacement(context: context, playerId: players[0].id, placement: 1)
        LeagueEngine.updatePlacement(context: context, playerId: players[1].id, placement: 2)
        LeagueEngine.updatePlacement(context: context, playerId: players[2].id, placement: 3)
        LeagueEngine.updatePlacement(context: context, playerId: players[3].id, placement: 4)
        
        LeagueEngine.finalizeRound(context: context)
        
        // Verify placement points
        #expect(players[0].placementPoints == 4) // 1st place
        #expect(players[1].placementPoints == 3) // 2nd place
        #expect(players[2].placementPoints == 2) // 3rd place
        #expect(players[3].placementPoints == 1) // 4th place
    }
    
    @Test("Achievement points accumulation with alwaysOn and random")
    func achievementPointsAccumulation() async throws {
        let context = try TestHelpers.bootstrappedContext()
        let players = TestFixtures.insertStandardPlayers(into: context)
        
        // Create achievements: 1 alwaysOn (2 pts), 2 random (1 pt each)
        let alwaysOnAch = TestFixtures.achievement(name: "Always On", points: 2, alwaysOn: true)
        let random1 = TestFixtures.achievement(name: "Random 1", points: 1, alwaysOn: false)
        let random2 = TestFixtures.achievement(name: "Random 2", points: 3, alwaysOn: false)
        
        context.insert(alwaysOnAch)
        context.insert(random1)
        context.insert(random2)
        try context.save()
        
        // Create tournament
        LeagueEngine.createTournament(
            context: context,
            name: "Achievement Test",
            totalWeeks: 1,
            randomPerWeek: 2,
            playerIds: players.map { $0.id }
        )
        
        // Set active achievements manually
        let tournament = try TestHelpers.fetchActiveTournament(from: context)!
        tournament.activeAchievementIds = [alwaysOnAch.id, random1.id, random2.id]
        try context.save()
        
        LeagueEngine.confirmAttendance(
            context: context,
            presentIds: players.map { $0.id },
            achievementsOnThisWeek: true
        )
        
        // Player 0 gets all achievements
        LeagueEngine.updatePlacement(context: context, playerId: players[0].id, placement: 1)
        LeagueEngine.updateAchievementCheck(context: context, playerId: players[0].id, achievementId: alwaysOnAch.id, checked: true)
        LeagueEngine.updateAchievementCheck(context: context, playerId: players[0].id, achievementId: random1.id, checked: true)
        LeagueEngine.updateAchievementCheck(context: context, playerId: players[0].id, achievementId: random2.id, checked: true)
        
        // Player 1 gets 1 achievement
        LeagueEngine.updatePlacement(context: context, playerId: players[1].id, placement: 2)
        LeagueEngine.updateAchievementCheck(context: context, playerId: players[1].id, achievementId: alwaysOnAch.id, checked: true)
        
        // Player 2 gets no achievements
        LeagueEngine.updatePlacement(context: context, playerId: players[2].id, placement: 3)
        
        // Player 3 gets no achievements
        LeagueEngine.updatePlacement(context: context, playerId: players[3].id, placement: 4)
        
        LeagueEngine.finalizeRound(context: context)
        
        // Verify achievement points
        #expect(players[0].achievementPoints == 6) // 2 + 1 + 3
        #expect(players[1].achievementPoints == 2) // 2
        #expect(players[2].achievementPoints == 0)
        #expect(players[3].achievementPoints == 0)
    }
    
    @Test("Wins tracking: only 1st place counts")
    func winsTracking() async throws {
        let context = try TestHelpers.bootstrappedContext()
        let players = TestFixtures.insertStandardPlayers(into: context)
        try context.save()
        
        LeagueEngine.createTournament(
            context: context,
            name: "Wins Test",
            totalWeeks: 1,
            randomPerWeek: 0,
            playerIds: players.map { $0.id }
        )
        
        LeagueEngine.confirmAttendance(
            context: context,
            presentIds: players.map { $0.id },
            achievementsOnThisWeek: false
        )
        
        // Round 1: Player 0 wins
        LeagueEngine.updatePlacement(context: context, playerId: players[0].id, placement: 1)
        LeagueEngine.updatePlacement(context: context, playerId: players[1].id, placement: 2)
        LeagueEngine.updatePlacement(context: context, playerId: players[2].id, placement: 3)
        LeagueEngine.updatePlacement(context: context, playerId: players[3].id, placement: 4)
        LeagueEngine.nextRound(context: context)
        
        // Round 2: Player 1 wins
        LeagueEngine.updatePlacement(context: context, playerId: players[1].id, placement: 1)
        LeagueEngine.updatePlacement(context: context, playerId: players[0].id, placement: 2)
        LeagueEngine.updatePlacement(context: context, playerId: players[2].id, placement: 3)
        LeagueEngine.updatePlacement(context: context, playerId: players[3].id, placement: 4)
        LeagueEngine.nextRound(context: context)
        
        // Round 3: Player 0 wins again
        LeagueEngine.updatePlacement(context: context, playerId: players[0].id, placement: 1)
        LeagueEngine.updatePlacement(context: context, playerId: players[2].id, placement: 2)
        LeagueEngine.updatePlacement(context: context, playerId: players[1].id, placement: 3)
        LeagueEngine.updatePlacement(context: context, playerId: players[3].id, placement: 4)
        LeagueEngine.nextRound(context: context)
        
        // Verify wins
        #expect(players[0].wins == 2)
        #expect(players[1].wins == 1)
        #expect(players[2].wins == 0)
        #expect(players[3].wins == 0)
    }
    
    @Test("Weekly points reset but tournament accumulates")
    func weeklyVsTournamentPoints() async throws {
        let context = try TestHelpers.bootstrappedContext()
        let players = TestFixtures.insertStandardPlayers(into: context)
        try context.save()
        
        LeagueEngine.createTournament(
            context: context,
            name: "Weekly vs Tournament",
            totalWeeks: 2,
            randomPerWeek: 0,
            playerIds: players.map { $0.id }
        )
        
        // Week 1
        LeagueEngine.confirmAttendance(
            context: context,
            presentIds: players.map { $0.id },
            achievementsOnThisWeek: false
        )
        
        // Player 0 gets 1st place 3 times = 12 points
        for _ in 1...3 {
            for (index, player) in players.enumerated() {
                LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: index + 1)
            }
            LeagueEngine.nextRound(context: context)
        }
        
        // Record points after week 1
        let week1Points = players[0].placementPoints
        #expect(week1Points == 12) // 4 * 3
        
        // Week 2
        LeagueEngine.confirmAttendance(
            context: context,
            presentIds: players.map { $0.id },
            achievementsOnThisWeek: false
        )
        
        // Check weekly points reset
        let tournament = try TestHelpers.fetchActiveTournament(from: context)!
        #expect(tournament.weeklyPointsByPlayer[players[0].id]?.placementPoints == 0)
        
        // Another week of play
        for _ in 1...3 {
            for (index, player) in players.enumerated() {
                LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: index + 1)
            }
            LeagueEngine.nextRound(context: context)
        }
        
        // Tournament points accumulated
        #expect(players[0].placementPoints == 24) // 12 + 12
    }
    
    @Test("Head-to-head calculation from shared pods")
    func headToHeadCalculation() async throws {
        let context = try TestHelpers.bootstrappedContext()
        let players = TestFixtures.insertStandardPlayers(into: context)
        try context.save()
        
        LeagueEngine.createTournament(
            context: context,
            name: "Head to Head",
            totalWeeks: 1,
            randomPerWeek: 0,
            playerIds: players.map { $0.id }
        )
        
        LeagueEngine.confirmAttendance(
            context: context,
            presentIds: players.map { $0.id },
            achievementsOnThisWeek: false
        )
        
        // Round 1: Alice beats Bob
        LeagueEngine.updatePlacement(context: context, playerId: players[0].id, placement: 1)
        LeagueEngine.updatePlacement(context: context, playerId: players[1].id, placement: 2)
        LeagueEngine.updatePlacement(context: context, playerId: players[2].id, placement: 3)
        LeagueEngine.updatePlacement(context: context, playerId: players[3].id, placement: 4)
        LeagueEngine.nextRound(context: context)
        
        // Round 2: Bob beats Alice
        LeagueEngine.updatePlacement(context: context, playerId: players[1].id, placement: 1)
        LeagueEngine.updatePlacement(context: context, playerId: players[0].id, placement: 2)
        LeagueEngine.updatePlacement(context: context, playerId: players[2].id, placement: 3)
        LeagueEngine.updatePlacement(context: context, playerId: players[3].id, placement: 4)
        LeagueEngine.nextRound(context: context)
        
        // Round 3: Tie
        LeagueEngine.updatePlacement(context: context, playerId: players[2].id, placement: 1)
        LeagueEngine.updatePlacement(context: context, playerId: players[0].id, placement: 2) // Same placement
        LeagueEngine.updatePlacement(context: context, playerId: players[1].id, placement: 2) // Same placement
        LeagueEngine.updatePlacement(context: context, playerId: players[3].id, placement: 4)
        LeagueEngine.nextRound(context: context)
        
        // Calculate head-to-head
        let results = try TestHelpers.fetchAll(GameResult.self, from: context)
        let record = StatsEngine.headToHeadRecord(
            player1Id: players[0].id,
            player2Id: players[1].id,
            results: results
        )
        
        #expect(record.player1Wins == 1)
        #expect(record.player2Wins == 1)
        #expect(record.ties == 1)
        #expect(record.totalGames == 3)
    }
}
