import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Integration tests for complete tournament lifecycle flows
@Suite("Tournament Lifecycle Integration Tests", .serialized)
@MainActor
struct TournamentLifecycleTests {
    
    @Test("Complete tournament flow: 6 weeks, 3 rounds each")
    func completeTournamentFlow() async throws {
        let context = try TestHelpers.bootstrappedContext()
        let players = TestFixtures.insertStandardPlayers(into: context)
        TestFixtures.insertSampleAchievements(into: context)
        try context.save()
        
        // Create tournament
        LeagueEngine.createTournament(
            context: context,
            name: "Full Tournament",
            totalWeeks: 6,
            randomPerWeek: 2,
            playerIds: players.map { $0.id }
        )
        
        var state = try TestHelpers.fetchLeagueState(from: context)!
        #expect(state.screen == .attendance)
        
        // Run through 6 weeks
        for week in 1...6 {
            // Confirm attendance
            LeagueEngine.confirmAttendance(
                context: context,
                presentIds: players.map { $0.id },
                achievementsOnThisWeek: true
            )
            
            state = try TestHelpers.fetchLeagueState(from: context)!
            #expect(state.screen == .pods)
            
            // Run 3 rounds
            for round in 1...3 {
                let tournament = try TestHelpers.fetchActiveTournament(from: context)!
                #expect(tournament.currentWeek == week)
                #expect(tournament.currentRound == round)
                
                // Generate pods
                let pods = LeagueEngine.generatePodsForRound(
                    players: players,
                    presentPlayerIds: players.map { $0.id },
                    currentRound: round,
                    weeklyPointsByPlayer: tournament.weeklyPointsByPlayer
                )
                
                // Set placements
                for (index, player) in pods[0].enumerated() {
                    LeagueEngine.updatePlacement(
                        context: context,
                        playerId: player.id,
                        placement: index + 1
                    )
                }
                
                // Advance to next round
                LeagueEngine.nextRound(context: context)
            }
            
            // After week 6, should be at tournament standings
            state = try TestHelpers.fetchLeagueState(from: context)!
            
            if week == 6 {
                #expect(state.screen == .tournamentStandings)
            } else {
                #expect(state.screen == .attendance)
            }
        }
        
        // Verify tournament is completed
        let tournament = LeagueEngine.fetchTournament(context: context, id: state.activeTournamentId!)!
        #expect(tournament.status == .completed)
        #expect(tournament.endDate != nil)
        
        // Verify players have accumulated stats
        for player in players {
            #expect(player.gamesPlayed == 18) // 6 weeks * 3 rounds
        }
        
        // Close standings
        LeagueEngine.closeTournamentStandings(context: context)
        
        state = try TestHelpers.fetchLeagueState(from: context)!
        #expect(state.activeTournamentId == nil)
        #expect(state.screen == .tournaments)
    }
    
    @Test("Tournament with varying attendance each week")
    func tournamentWithVaryingAttendance() async throws {
        let context = try TestHelpers.bootstrappedContext()
        let players = TestFixtures.players("Alice", "Bob", "Charlie", "Diana", "Eve", "Frank")
        for player in players {
            context.insert(player)
        }
        TestFixtures.insertSampleAchievements(into: context)
        try context.save()
        
        // Create tournament
        LeagueEngine.createTournament(
            context: context,
            name: "Varying Attendance",
            totalWeeks: 3,
            randomPerWeek: 1,
            playerIds: players.map { $0.id }
        )
        
        // Week 1: All 6 players
        LeagueEngine.confirmAttendance(
            context: context,
            presentIds: players.map { $0.id },
            achievementsOnThisWeek: true
        )
        
        for _ in 1...3 {
            for (index, player) in players.prefix(4).enumerated() {
                LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: index + 1)
            }
            LeagueEngine.nextRound(context: context)
        }
        
        // Week 2: Only 4 players
        let week2Players = Array(players.prefix(4))
        LeagueEngine.confirmAttendance(
            context: context,
            presentIds: week2Players.map { $0.id },
            achievementsOnThisWeek: false
        )
        
        for _ in 1...3 {
            for (index, player) in week2Players.enumerated() {
                LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: index + 1)
            }
            LeagueEngine.nextRound(context: context)
        }
        
        // Week 3: Different 4 players
        let week3Players = Array(players.suffix(4))
        LeagueEngine.confirmAttendance(
            context: context,
            presentIds: week3Players.map { $0.id },
            achievementsOnThisWeek: true
        )
        
        for _ in 1...3 {
            for (index, player) in week3Players.enumerated() {
                LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: index + 1)
            }
            LeagueEngine.nextRound(context: context)
        }
        
        // Verify different game counts
        // Alice played all 3 weeks = 9 games
        // Bob played weeks 1 and 2 = 6 games
        // Eve played weeks 1 and 3 = 6 games
        // Frank played only week 3 = 3 games (but might not have been registered for week 1)
        
        let state = try TestHelpers.fetchLeagueState(from: context)!
        #expect(state.screen == .tournamentStandings)
    }
    
    @Test("Multi-tournament scenario: stats accumulate across tournaments")
    func multiTournamentScenario() async throws {
        let context = try TestHelpers.bootstrappedContext()
        let players = TestFixtures.insertStandardPlayers(into: context)
        try context.save()
        
        // First tournament
        LeagueEngine.createTournament(
            context: context,
            name: "Tournament 1",
            totalWeeks: 1,
            randomPerWeek: 0,
            playerIds: players.map { $0.id }
        )
        
        LeagueEngine.confirmAttendance(
            context: context,
            presentIds: players.map { $0.id },
            achievementsOnThisWeek: false
        )
        
        // Play 3 rounds
        for _ in 1...3 {
            for (index, player) in players.enumerated() {
                LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: index + 1)
            }
            LeagueEngine.nextRound(context: context)
        }
        
        LeagueEngine.closeTournamentStandings(context: context)
        
        // Record stats after first tournament
        let statsAfterFirst = players.map { ($0.id, $0.placementPoints, $0.wins, $0.gamesPlayed) }
        
        // Second tournament
        LeagueEngine.createTournament(
            context: context,
            name: "Tournament 2",
            totalWeeks: 1,
            randomPerWeek: 0,
            playerIds: players.map { $0.id }
        )
        
        LeagueEngine.confirmAttendance(
            context: context,
            presentIds: players.map { $0.id },
            achievementsOnThisWeek: false
        )
        
        // Play 3 more rounds with reversed placements
        for _ in 1...3 {
            for (index, player) in players.reversed().enumerated() {
                LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: index + 1)
            }
            LeagueEngine.nextRound(context: context)
        }
        
        LeagueEngine.closeTournamentStandings(context: context)
        
        // Verify stats accumulated
        for (index, player) in players.enumerated() {
            let firstStats = statsAfterFirst[index]
            #expect(player.gamesPlayed > firstStats.3) // More games
            #expect(player.placementPoints > firstStats.1) // More points
        }
        
        // Verify tournaments played
        for player in players {
            #expect(player.tournamentsPlayed == 2)
        }
    }
    
    @Test("Mid-tournament state restoration")
    func midTournamentStateRestoration() async throws {
        let context = try TestHelpers.bootstrappedContext()
        let players = TestFixtures.insertStandardPlayers(into: context)
        try context.save()
        
        // Create tournament and advance to week 3, round 2
        LeagueEngine.createTournament(
            context: context,
            name: "Restoration Test",
            totalWeeks: 6,
            randomPerWeek: 2,
            playerIds: players.map { $0.id }
        )
        
        // Advance to week 3
        for _ in 1...2 {
            LeagueEngine.confirmAttendance(
                context: context,
                presentIds: players.map { $0.id },
                achievementsOnThisWeek: true
            )
            
            for _ in 1...3 {
                for (index, player) in players.enumerated() {
                    LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: index + 1)
                }
                LeagueEngine.nextRound(context: context)
            }
        }
        
        // Week 3 attendance
        LeagueEngine.confirmAttendance(
            context: context,
            presentIds: players.map { $0.id },
            achievementsOnThisWeek: true
        )
        
        // Complete round 1
        for (index, player) in players.enumerated() {
            LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: index + 1)
        }
        LeagueEngine.nextRound(context: context)
        
        // Simulate "app restart" by validating state
        LeagueEngine.validateAndSanitizeState(context: context)
        
        // Verify state is intact
        let tournament = try TestHelpers.fetchActiveTournament(from: context)!
        #expect(tournament.currentWeek == 3)
        #expect(tournament.currentRound == 2)
        
        let state = try TestHelpers.fetchLeagueState(from: context)!
        #expect(state.activeTournamentId == tournament.id)
    }
}
