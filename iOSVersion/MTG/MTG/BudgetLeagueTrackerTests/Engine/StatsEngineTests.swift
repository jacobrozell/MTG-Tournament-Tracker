import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Comprehensive tests for StatsEngine statistics calculations
@Suite("StatsEngine Tests", .serialized)
@MainActor
struct StatsEngineTests {
    
    // MARK: - All-Time Stats Tests
    
    @Suite("winRate")
    @MainActor
    struct WinRateTests {
        
        @Test("Calculates correct win rate", arguments: [
            (wins: 5, gamesPlayed: 10, expected: 0.5),
            (wins: 3, gamesPlayed: 12, expected: 0.25),
            (wins: 10, gamesPlayed: 10, expected: 1.0),
            (wins: 0, gamesPlayed: 5, expected: 0.0),
            (wins: 1, gamesPlayed: 4, expected: 0.25)
        ])
        func calculatesCorrectWinRate(wins: Int, gamesPlayed: Int, expected: Double) {
            let player = TestFixtures.player(wins: wins, gamesPlayed: gamesPlayed)
            
            let rate = StatsEngine.winRate(for: player)
            
            #expect(abs(rate - expected) < 0.001)
        }
        
        @Test("Returns 0 for player with no games")
        func returnsZeroForNoGames() {
            let player = TestFixtures.player(wins: 0, gamesPlayed: 0)
            
            let rate = StatsEngine.winRate(for: player)
            
            #expect(rate == 0.0)
        }
    }
    
    @Suite("averagePlacement")
    @MainActor
    struct AveragePlacementTests {
        
        @Test("Calculates correct average placement")
        func calculatesCorrectAverage() {
            let playerId = "player1"
            let results = [
                TestFixtures.gameResult(tournamentId: "t1", playerId: playerId, placement: 1),
                TestFixtures.gameResult(tournamentId: "t1", playerId: playerId, placement: 2),
                TestFixtures.gameResult(tournamentId: "t1", playerId: playerId, placement: 3),
                TestFixtures.gameResult(tournamentId: "t1", playerId: playerId, placement: 4)
            ]
            
            let average = StatsEngine.averagePlacement(playerId: playerId, results: results)
            
            // (1 + 2 + 3 + 4) / 4 = 2.5
            #expect(abs(average - 2.5) < 0.001)
        }
        
        @Test("Returns 0 for player with no results")
        func returnsZeroForNoResults() {
            let average = StatsEngine.averagePlacement(playerId: "player1", results: [])
            
            #expect(average == 0.0)
        }
        
        @Test("Filters results by player ID")
        func filtersResultsByPlayerId() {
            let results = [
                TestFixtures.gameResult(tournamentId: "t1", playerId: "player1", placement: 1),
                TestFixtures.gameResult(tournamentId: "t1", playerId: "player2", placement: 4),
                TestFixtures.gameResult(tournamentId: "t1", playerId: "player1", placement: 1)
            ]
            
            let average = StatsEngine.averagePlacement(playerId: "player1", results: results)
            
            // (1 + 1) / 2 = 1.0
            #expect(average == 1.0)
        }
    }
    
    @Suite("placementDistribution")
    @MainActor
    struct PlacementDistributionTests {
        
        @Test("Returns correct counts for each placement")
        func returnsCorrectCounts() {
            let playerId = "player1"
            let results = [
                TestFixtures.gameResult(tournamentId: "t1", playerId: playerId, placement: 1),
                TestFixtures.gameResult(tournamentId: "t1", playerId: playerId, placement: 1),
                TestFixtures.gameResult(tournamentId: "t1", playerId: playerId, placement: 2),
                TestFixtures.gameResult(tournamentId: "t1", playerId: playerId, placement: 3),
                TestFixtures.gameResult(tournamentId: "t1", playerId: playerId, placement: 4),
                TestFixtures.gameResult(tournamentId: "t1", playerId: playerId, placement: 4)
            ]
            
            let distribution = StatsEngine.placementDistribution(playerId: playerId, results: results)
            
            #expect(distribution[1] == 2)
            #expect(distribution[2] == 1)
            #expect(distribution[3] == 1)
            #expect(distribution[4] == 2)
        }
        
        @Test("Returns zeros for placements without results")
        func returnsZerosForMissingPlacements() {
            let playerId = "player1"
            let results = [
                TestFixtures.gameResult(tournamentId: "t1", playerId: playerId, placement: 1)
            ]
            
            let distribution = StatsEngine.placementDistribution(playerId: playerId, results: results)
            
            #expect(distribution[1] == 1)
            #expect(distribution[2] == 0)
            #expect(distribution[3] == 0)
            #expect(distribution[4] == 0)
        }
        
        @Test("Returns all zeros for player with no results")
        func returnsAllZerosForNoResults() {
            let distribution = StatsEngine.placementDistribution(playerId: "player1", results: [])
            
            #expect(distribution[1] == 0)
            #expect(distribution[2] == 0)
            #expect(distribution[3] == 0)
            #expect(distribution[4] == 0)
        }
    }
    
    @Suite("pointsPerGame")
    @MainActor
    struct PointsPerGameTests {
        
        @Test("Calculates correct points per game")
        func calculatesCorrectPPG() {
            let player = TestFixtures.player(
                placementPoints: 20,
                achievementPoints: 10,
                gamesPlayed: 6
            )
            
            let ppg = StatsEngine.pointsPerGame(for: player)
            
            // (20 + 10) / 6 = 5.0
            #expect(abs(ppg - 5.0) < 0.001)
        }
        
        @Test("Returns 0 for player with no games")
        func returnsZeroForNoGames() {
            let player = TestFixtures.player(
                placementPoints: 0,
                achievementPoints: 0,
                gamesPlayed: 0
            )
            
            let ppg = StatsEngine.pointsPerGame(for: player)
            
            #expect(ppg == 0.0)
        }
    }
    
    // MARK: - Per-Tournament Stats Tests
    
    @Suite("tournamentStats")
    @MainActor
    struct TournamentStatsTests {
        
        @Test("Aggregates all stats correctly for tournament")
        func aggregatesAllStats() {
            let playerId = "player1"
            let tournamentId = "tournament1"
            
            let results = [
                TestFixtures.gameResult(
                    tournamentId: tournamentId,
                    week: 1,
                    round: 1,
                    playerId: playerId,
                    placement: 1,
                    achievementPoints: 2
                ),
                TestFixtures.gameResult(
                    tournamentId: tournamentId,
                    week: 1,
                    round: 2,
                    playerId: playerId,
                    placement: 2,
                    achievementPoints: 1
                ),
                TestFixtures.gameResult(
                    tournamentId: tournamentId,
                    week: 2,
                    round: 1,
                    playerId: playerId,
                    placement: 3,
                    achievementPoints: 0
                )
            ]
            
            let stats = StatsEngine.tournamentStats(
                playerId: playerId,
                tournamentId: tournamentId,
                results: results
            )
            
            #expect(stats.gamesPlayed == 3)
            #expect(stats.wins == 1)  // Only 1st place counts as win
            #expect(stats.placementPoints == 4 + 3 + 2)  // 9
            #expect(stats.achievementPoints == 2 + 1 + 0)  // 3
            #expect(stats.totalPoints == 9 + 3)  // 12
            #expect(stats.placementDistribution[1] == 1)
            #expect(stats.placementDistribution[2] == 1)
            #expect(stats.placementDistribution[3] == 1)
            #expect(stats.placementDistribution[4] == 0)
        }
        
        @Test("Filters by tournament ID")
        func filtersByTournamentId() {
            let playerId = "player1"
            
            let results = [
                TestFixtures.gameResult(tournamentId: "tournament1", playerId: playerId, placement: 1),
                TestFixtures.gameResult(tournamentId: "tournament2", playerId: playerId, placement: 4),
                TestFixtures.gameResult(tournamentId: "tournament1", playerId: playerId, placement: 1)
            ]
            
            let stats = StatsEngine.tournamentStats(
                playerId: playerId,
                tournamentId: "tournament1",
                results: results
            )
            
            #expect(stats.gamesPlayed == 2)
            #expect(stats.wins == 2)
        }
        
        @Test("Returns empty stats for no matching results")
        func returnsEmptyStatsForNoResults() {
            let stats = StatsEngine.tournamentStats(
                playerId: "player1",
                tournamentId: "tournament1",
                results: []
            )
            
            #expect(stats.gamesPlayed == 0)
            #expect(stats.wins == 0)
            #expect(stats.totalPoints == 0)
            #expect(stats.winRate == 0.0)
        }
        
        @Test("Calculates correct win rate")
        func calculatesCorrectWinRate() {
            let playerId = "player1"
            let tournamentId = "t1"
            
            let results = [
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: playerId, placement: 1),
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: playerId, placement: 2),
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: playerId, placement: 1),
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: playerId, placement: 3)
            ]
            
            let stats = StatsEngine.tournamentStats(
                playerId: playerId,
                tournamentId: tournamentId,
                results: results
            )
            
            // 2 wins out of 4 games = 0.5
            #expect(abs(stats.winRate - 0.5) < 0.001)
        }
    }
    
    // MARK: - Head-to-Head Stats Tests
    
    @Suite("headToHeadRecord")
    @MainActor
    struct HeadToHeadRecordTests {
        
        @Test("Calculates correct wins/losses/ties")
        func calculatesCorrectRecord() {
            let pod1Id = UUID().uuidString
            let pod2Id = UUID().uuidString
            let pod3Id = UUID().uuidString
            
            let results = [
                // Pod 1: Player 1 beats Player 2
                TestFixtures.gameResult(tournamentId: "t1", playerId: "player1", placement: 1, podId: pod1Id),
                TestFixtures.gameResult(tournamentId: "t1", playerId: "player2", placement: 3, podId: pod1Id),
                
                // Pod 2: Player 2 beats Player 1
                TestFixtures.gameResult(tournamentId: "t1", playerId: "player1", placement: 4, podId: pod2Id),
                TestFixtures.gameResult(tournamentId: "t1", playerId: "player2", placement: 2, podId: pod2Id),
                
                // Pod 3: Tie
                TestFixtures.gameResult(tournamentId: "t1", playerId: "player1", placement: 2, podId: pod3Id),
                TestFixtures.gameResult(tournamentId: "t1", playerId: "player2", placement: 2, podId: pod3Id)
            ]
            
            let record = StatsEngine.headToHeadRecord(
                player1Id: "player1",
                player2Id: "player2",
                results: results
            )
            
            #expect(record.player1Wins == 1)
            #expect(record.player2Wins == 1)
            #expect(record.ties == 1)
            #expect(record.totalGames == 3)
        }
        
        @Test("Only counts games where both players are in same pod")
        func onlyCountsSharedPods() {
            let sharedPodId = UUID().uuidString
            let soloP1PodId = UUID().uuidString
            let soloP2PodId = UUID().uuidString
            
            let results = [
                // Shared pod
                TestFixtures.gameResult(tournamentId: "t1", playerId: "player1", placement: 1, podId: sharedPodId),
                TestFixtures.gameResult(tournamentId: "t1", playerId: "player2", placement: 4, podId: sharedPodId),
                
                // Player 1 only pod
                TestFixtures.gameResult(tournamentId: "t1", playerId: "player1", placement: 1, podId: soloP1PodId),
                TestFixtures.gameResult(tournamentId: "t1", playerId: "player3", placement: 2, podId: soloP1PodId),
                
                // Player 2 only pod
                TestFixtures.gameResult(tournamentId: "t1", playerId: "player2", placement: 1, podId: soloP2PodId),
                TestFixtures.gameResult(tournamentId: "t1", playerId: "player4", placement: 2, podId: soloP2PodId)
            ]
            
            let record = StatsEngine.headToHeadRecord(
                player1Id: "player1",
                player2Id: "player2",
                results: results
            )
            
            #expect(record.totalGames == 1)
            #expect(record.player1Wins == 1)
            #expect(record.player2Wins == 0)
        }
        
        @Test("Returns zeros for players who never met")
        func returnsZerosForNoMeetings() {
            let pod1Id = UUID().uuidString
            let pod2Id = UUID().uuidString
            
            let results = [
                TestFixtures.gameResult(tournamentId: "t1", playerId: "player1", placement: 1, podId: pod1Id),
                TestFixtures.gameResult(tournamentId: "t1", playerId: "player2", placement: 1, podId: pod2Id)
            ]
            
            let record = StatsEngine.headToHeadRecord(
                player1Id: "player1",
                player2Id: "player2",
                results: results
            )
            
            #expect(record.totalGames == 0)
            #expect(record.player1Wins == 0)
            #expect(record.player2Wins == 0)
            #expect(record.ties == 0)
        }
    }
    
    // MARK: - Tournament Summary Tests
    
    @Suite("tournamentSummary")
    @MainActor
    struct TournamentSummaryTests {
        
        @Test("Calculates correct participant count")
        func calculatesParticipantCount() {
            let tournamentId = "t1"
            let podId = UUID().uuidString
            
            let results = [
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: "p1", placement: 1, podId: podId),
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: "p2", placement: 2, podId: podId),
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: "p3", placement: 3, podId: podId),
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: "p1", placement: 2, podId: UUID().uuidString)
            ]
            
            let players: [Player] = []  // Not needed for participant count
            
            let summary = StatsEngine.tournamentSummary(
                tournamentId: tournamentId,
                results: results,
                players: players
            )
            
            #expect(summary.participantCount == 3)  // p1, p2, p3
        }
        
        @Test("Identifies winner correctly")
        func identifiesWinner() {
            let tournamentId = "t1"
            
            let player1 = TestFixtures.player(name: "Winner")
            let player2 = TestFixtures.player(name: "Loser")
            
            let results = [
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: player1.id, placement: 1),
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: player1.id, placement: 1),
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: player2.id, placement: 4),
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: player2.id, placement: 4)
            ]
            
            let summary = StatsEngine.tournamentSummary(
                tournamentId: tournamentId,
                results: results,
                players: [player1, player2]
            )
            
            #expect(summary.winnerName == "Winner")
            #expect(summary.winnerPoints == 8)  // 4 + 4
        }
        
        @Test("Calculates total games from unique pods")
        func calculatesTotalGames() {
            let tournamentId = "t1"
            let pod1 = UUID().uuidString
            let pod2 = UUID().uuidString
            
            let results = [
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: "p1", placement: 1, podId: pod1),
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: "p2", placement: 2, podId: pod1),
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: "p3", placement: 3, podId: pod1),
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: "p4", placement: 4, podId: pod1),
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: "p1", placement: 1, podId: pod2),
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: "p2", placement: 2, podId: pod2)
            ]
            
            let summary = StatsEngine.tournamentSummary(
                tournamentId: tournamentId,
                results: results,
                players: []
            )
            
            #expect(summary.totalGames == 2)  // 2 unique pods
        }
        
        @Test("Calculates standings correctly")
        func calculatesStandings() {
            let tournamentId = "t1"
            
            let player1 = TestFixtures.player(name: "First")
            let player2 = TestFixtures.player(name: "Second")
            let player3 = TestFixtures.player(name: "Third")
            
            let results = [
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: player1.id, placement: 1),  // 4 pts
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: player2.id, placement: 2),  // 3 pts
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: player3.id, placement: 4),  // 1 pt
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: player1.id, placement: 2),  // +3 pts = 7
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: player2.id, placement: 3),  // +2 pts = 5
                TestFixtures.gameResult(tournamentId: tournamentId, playerId: player3.id, placement: 4)   // +1 pt = 2
            ]
            
            let summary = StatsEngine.tournamentSummary(
                tournamentId: tournamentId,
                results: results,
                players: [player1, player2, player3]
            )
            
            #expect(summary.standings.count == 3)
            #expect(summary.standings[0].player.name == "First")
            #expect(summary.standings[0].points == 7)
            #expect(summary.standings[1].player.name == "Second")
            #expect(summary.standings[1].points == 5)
            #expect(summary.standings[2].player.name == "Third")
            #expect(summary.standings[2].points == 2)
        }
    }
    
    // MARK: - Fetch Helper Tests
    
    @Suite("fetchHelpers")
    @MainActor
    struct FetchHelperTests {
        
        @Test("fetchResultsForPlayer filters by player ID")
        func fetchResultsForPlayerFilters() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let result1 = TestFixtures.gameResult(tournamentId: "t1", playerId: "player1", placement: 1)
            let result2 = TestFixtures.gameResult(tournamentId: "t1", playerId: "player2", placement: 2)
            let result3 = TestFixtures.gameResult(tournamentId: "t1", playerId: "player1", placement: 3)
            
            context.insert(result1)
            context.insert(result2)
            context.insert(result3)
            try context.save()
            
            let results = StatsEngine.fetchResultsForPlayer("player1", context: context)
            
            #expect(results.count == 2)
            #expect(results.allSatisfy { $0.playerId == "player1" })
        }
        
        @Test("fetchResultsForTournament filters by tournament ID")
        func fetchResultsForTournamentFilters() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let result1 = TestFixtures.gameResult(tournamentId: "tournament1", playerId: "p1", placement: 1)
            let result2 = TestFixtures.gameResult(tournamentId: "tournament2", playerId: "p1", placement: 2)
            let result3 = TestFixtures.gameResult(tournamentId: "tournament1", playerId: "p2", placement: 3)
            
            context.insert(result1)
            context.insert(result2)
            context.insert(result3)
            try context.save()
            
            let results = StatsEngine.fetchResultsForTournament("tournament1", context: context)
            
            #expect(results.count == 2)
            #expect(results.allSatisfy { $0.tournamentId == "tournament1" })
        }
        
        @Test("fetchAllResults returns all results sorted by timestamp")
        func fetchAllResultsReturnsAll() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let result1 = TestFixtures.gameResult(tournamentId: "t1", playerId: "p1", placement: 1)
            let result2 = TestFixtures.gameResult(tournamentId: "t2", playerId: "p2", placement: 2)
            let result3 = TestFixtures.gameResult(tournamentId: "t3", playerId: "p3", placement: 3)
            
            context.insert(result1)
            context.insert(result2)
            context.insert(result3)
            try context.save()
            
            let results = StatsEngine.fetchAllResults(context: context)
            
            #expect(results.count == 3)
        }
        
        @Test("fetchAllResults returns empty array when no results")
        func fetchAllResultsReturnsEmptyArray() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let results = StatsEngine.fetchAllResults(context: context)
            
            #expect(results.isEmpty)
        }
    }
}
