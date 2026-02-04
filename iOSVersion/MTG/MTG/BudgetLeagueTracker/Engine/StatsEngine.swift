import Foundation
import SwiftData

/// Statistics computation engine for the Budget League Tracker.
/// Provides all-time and per-tournament statistics calculations.
enum StatsEngine {
    
    // MARK: - All-Time Stats
    
    /// Calculates win rate for a player (wins / games played).
    /// - Parameter player: The player
    /// - Returns: Win rate as a decimal (0.0 to 1.0), or 0 if no games played
    static func winRate(for player: Player) -> Double {
        guard player.gamesPlayed > 0 else { return 0 }
        return Double(player.wins) / Double(player.gamesPlayed)
    }
    
    /// Calculates average placement for a player from GameResults.
    /// - Parameters:
    ///   - playerId: The player's ID
    ///   - results: GameResult records to analyze
    /// - Returns: Average placement (1.0 to 4.0), or 0 if no results
    static func averagePlacement(playerId: String, results: [GameResult]) -> Double {
        let playerResults = results.filter { $0.playerId == playerId }
        guard !playerResults.isEmpty else { return 0 }
        
        let totalPlacement = playerResults.reduce(0) { $0 + $1.placement }
        return Double(totalPlacement) / Double(playerResults.count)
    }
    
    /// Calculates placement distribution for a player.
    /// - Parameters:
    ///   - playerId: The player's ID
    ///   - results: GameResult records to analyze
    /// - Returns: Dictionary mapping placement (1-4) to count
    static func placementDistribution(playerId: String, results: [GameResult]) -> [Int: Int] {
        let playerResults = results.filter { $0.playerId == playerId }
        var distribution: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0]
        
        for result in playerResults {
            distribution[result.placement, default: 0] += 1
        }
        
        return distribution
    }
    
    /// Calculates points per game for a player.
    /// - Parameter player: The player
    /// - Returns: Average points per game, or 0 if no games played
    static func pointsPerGame(for player: Player) -> Double {
        guard player.gamesPlayed > 0 else { return 0 }
        return Double(player.totalPoints) / Double(player.gamesPlayed)
    }
    
    // MARK: - Per-Tournament Stats
    
    /// Calculates stats for a player within a specific tournament.
    /// - Parameters:
    ///   - playerId: The player's ID
    ///   - tournamentId: The tournament's ID
    ///   - results: All GameResult records
    /// - Returns: Tournament-specific stats
    static func tournamentStats(
        playerId: String,
        tournamentId: String,
        results: [GameResult]
    ) -> TournamentPlayerStats {
        let tournamentResults = results.filter {
            $0.playerId == playerId && $0.tournamentId == tournamentId
        }
        
        let gamesPlayed = tournamentResults.count
        let wins = tournamentResults.filter { $0.isWin }.count
        let totalPoints = tournamentResults.reduce(0) { $0 + $1.totalPoints }
        let placementPoints = tournamentResults.reduce(0) { $0 + $1.placementPoints }
        let achievementPoints = tournamentResults.reduce(0) { $0 + $1.achievementPoints }
        
        var distribution: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0]
        for result in tournamentResults {
            distribution[result.placement, default: 0] += 1
        }
        
        let avgPlacement = gamesPlayed > 0 
            ? Double(tournamentResults.reduce(0) { $0 + $1.placement }) / Double(gamesPlayed)
            : 0
        
        return TournamentPlayerStats(
            gamesPlayed: gamesPlayed,
            wins: wins,
            totalPoints: totalPoints,
            placementPoints: placementPoints,
            achievementPoints: achievementPoints,
            placementDistribution: distribution,
            averagePlacement: avgPlacement,
            winRate: gamesPlayed > 0 ? Double(wins) / Double(gamesPlayed) : 0
        )
    }
    
    // MARK: - Head-to-Head Stats
    
    /// Calculates head-to-head record between two players.
    /// A "win" is when player1 places higher than player2 in the same pod.
    /// - Parameters:
    ///   - player1Id: First player's ID
    ///   - player2Id: Second player's ID
    ///   - results: All GameResult records
    /// - Returns: Head-to-head record
    static func headToHeadRecord(
        player1Id: String,
        player2Id: String,
        results: [GameResult]
    ) -> HeadToHeadRecord {
        // Group results by podId
        var podResults: [String: [GameResult]] = [:]
        for result in results {
            podResults[result.podId, default: []].append(result)
        }
        
        var player1Wins = 0
        var player2Wins = 0
        var ties = 0
        
        for (_, podResultsList) in podResults {
            let p1Result = podResultsList.first { $0.playerId == player1Id }
            let p2Result = podResultsList.first { $0.playerId == player2Id }
            
            // Both players must have been in this pod
            guard let p1 = p1Result, let p2 = p2Result else { continue }
            
            if p1.placement < p2.placement {
                player1Wins += 1
            } else if p2.placement < p1.placement {
                player2Wins += 1
            } else {
                ties += 1
            }
        }
        
        return HeadToHeadRecord(
            player1Wins: player1Wins,
            player2Wins: player2Wins,
            ties: ties
        )
    }
    
    // MARK: - Tournament Summary
    
    /// Generates a summary for a tournament.
    /// - Parameters:
    ///   - tournamentId: The tournament's ID
    ///   - results: All GameResult records
    ///   - players: All players
    /// - Returns: Tournament summary
    static func tournamentSummary(
        tournamentId: String,
        results: [GameResult],
        players: [Player]
    ) -> TournamentSummary {
        let tournamentResults = results.filter { $0.tournamentId == tournamentId }
        
        // Get unique player IDs from results
        let participantIds = Set(tournamentResults.map { $0.playerId })
        let participantCount = participantIds.count
        
        // Calculate total games (unique podIds)
        let uniquePodIds = Set(tournamentResults.map { $0.podId })
        let totalGames = uniquePodIds.count
        
        // Find winner (highest total points)
        var pointsByPlayer: [String: Int] = [:]
        for result in tournamentResults {
            pointsByPlayer[result.playerId, default: 0] += result.totalPoints
        }
        
        let winnerId = pointsByPlayer.max(by: { $0.value < $1.value })?.key
        let winnerName = players.first { $0.id == winnerId }?.name
        let winnerPoints = winnerId != nil ? pointsByPlayer[winnerId!] ?? 0 : 0
        
        // Calculate standings
        let standings = pointsByPlayer
            .map { (playerId: $0.key, points: $0.value) }
            .sorted { $0.points > $1.points }
            .compactMap { standing -> (player: Player, points: Int)? in
                guard let player = players.first(where: { $0.id == standing.playerId }) else { return nil }
                return (player: player, points: standing.points)
            }
        
        return TournamentSummary(
            participantCount: participantCount,
            totalGames: totalGames,
            winnerName: winnerName,
            winnerPoints: winnerPoints,
            standings: standings
        )
    }
    
    // MARK: - Fetch Helpers
    
    /// Fetches all GameResults for a player.
    static func fetchResultsForPlayer(_ playerId: String, context: ModelContext) -> [GameResult] {
        let descriptor = FetchDescriptor<GameResult>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let allResults = (try? context.fetch(descriptor)) ?? []
        return allResults.filter { $0.playerId == playerId }
    }
    
    /// Fetches all GameResults for a tournament.
    static func fetchResultsForTournament(_ tournamentId: String, context: ModelContext) -> [GameResult] {
        let descriptor = FetchDescriptor<GameResult>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let allResults = (try? context.fetch(descriptor)) ?? []
        return allResults.filter { $0.tournamentId == tournamentId }
    }
    
    /// Fetches all GameResults.
    static func fetchAllResults(context: ModelContext) -> [GameResult] {
        let descriptor = FetchDescriptor<GameResult>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}

// MARK: - Supporting Types

/// Stats for a player within a specific tournament.
struct TournamentPlayerStats {
    let gamesPlayed: Int
    let wins: Int
    let totalPoints: Int
    let placementPoints: Int
    let achievementPoints: Int
    let placementDistribution: [Int: Int]
    let averagePlacement: Double
    let winRate: Double
}

/// Head-to-head record between two players.
struct HeadToHeadRecord {
    let player1Wins: Int
    let player2Wins: Int
    let ties: Int
    
    var totalGames: Int {
        player1Wins + player2Wins + ties
    }
}

/// Summary of a tournament.
struct TournamentSummary {
    let participantCount: Int
    let totalGames: Int
    let winnerName: String?
    let winnerPoints: Int
    let standings: [(player: Player, points: Int)]
}
