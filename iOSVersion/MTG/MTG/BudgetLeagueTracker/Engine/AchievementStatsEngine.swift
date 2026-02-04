import Foundation
import SwiftData

/// Time grouping options for trend analysis
enum TimeGrouping {
    case daily
    case weekly
    case monthly
}

/// Statistics computation engine for achievement analytics.
/// Provides functions to analyze achievement earning patterns across players and time.
enum AchievementStatsEngine {
    
    // MARK: - Total Earned Stats
    
    /// Calculates the total number of times an achievement has been earned across all players.
    /// - Parameters:
    ///   - achievementId: The achievement's ID
    ///   - results: All GameResult records to analyze
    /// - Returns: Total count of times this achievement was earned
    static func totalTimesEarned(achievementId: String, results: [GameResult]) -> Int {
        results.reduce(0) { total, result in
            total + (result.achievementIds.contains(achievementId) ? 1 : 0)
        }
    }
    
    /// Calculates the total number of achievements earned across all players and games.
    /// - Parameter results: All GameResult records to analyze
    /// - Returns: Total count of all achievement earnings
    static func totalAchievementsEarned(results: [GameResult]) -> Int {
        results.reduce(0) { $0 + $1.achievementIds.count }
    }
    
    // MARK: - Per-Player Breakdown
    
    /// Calculates how many times each player has earned a specific achievement.
    /// - Parameters:
    ///   - achievementId: The achievement's ID
    ///   - results: All GameResult records to analyze
    /// - Returns: Dictionary mapping playerId to earn count
    static func earnedByPlayer(achievementId: String, results: [GameResult]) -> [String: Int] {
        var playerCounts: [String: Int] = [:]
        
        for result in results {
            if result.achievementIds.contains(achievementId) {
                playerCounts[result.playerId, default: 0] += 1
            }
        }
        
        return playerCounts
    }
    
    /// Gets the top earners for a specific achievement.
    /// - Parameters:
    ///   - achievementId: The achievement's ID
    ///   - results: All GameResult records to analyze
    ///   - players: All players (for name lookup)
    ///   - limit: Maximum number of earners to return (default: 3)
    /// - Returns: Array of tuples with player name and count, sorted by count descending
    static func topEarners(
        achievementId: String,
        results: [GameResult],
        players: [Player],
        limit: Int = 3
    ) -> [(playerName: String, count: Int)] {
        let playerCounts = earnedByPlayer(achievementId: achievementId, results: results)
        let playerNameMap = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0.name) })
        
        return playerCounts
            .map { (playerName: playerNameMap[$0.key] ?? "Unknown", count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Achievement Leaderboard
    
    /// Generates a leaderboard of achievements ranked by how many times they've been earned.
    /// - Parameters:
    ///   - achievements: All achievements to analyze
    ///   - results: All GameResult records to analyze
    /// - Returns: Array of tuples with achievement and total earned, sorted by earned count descending
    static func achievementLeaderboard(
        achievements: [Achievement],
        results: [GameResult]
    ) -> [(achievement: Achievement, totalEarned: Int)] {
        achievements
            .map { achievement in
                (achievement: achievement, totalEarned: totalTimesEarned(achievementId: achievement.id, results: results))
            }
            .sorted { $0.totalEarned > $1.totalEarned }
    }
    
    /// Finds the most frequently earned achievement.
    /// - Parameters:
    ///   - achievements: All achievements to analyze
    ///   - results: All GameResult records to analyze
    /// - Returns: The most popular achievement and its count, or nil if no achievements earned
    static func mostPopularAchievement(
        achievements: [Achievement],
        results: [GameResult]
    ) -> (achievement: Achievement, count: Int)? {
        let leaderboard = achievementLeaderboard(achievements: achievements, results: results)
        guard let top = leaderboard.first, top.totalEarned > 0 else { return nil }
        return (achievement: top.achievement, count: top.totalEarned)
    }
    
    /// Finds the least frequently earned achievement (that has been earned at least once).
    /// - Parameters:
    ///   - achievements: All achievements to analyze
    ///   - results: All GameResult records to analyze
    /// - Returns: The rarest achievement and its count, or nil if no achievements earned
    static func rarestAchievement(
        achievements: [Achievement],
        results: [GameResult]
    ) -> (achievement: Achievement, count: Int)? {
        let leaderboard = achievementLeaderboard(achievements: achievements, results: results)
            .filter { $0.totalEarned > 0 }
        guard let rarest = leaderboard.last else { return nil }
        return (achievement: rarest.achievement, count: rarest.totalEarned)
    }
    
    // MARK: - Player Achievement History
    
    /// Gets a player's achievement history showing which achievements they've earned and how many times.
    /// - Parameters:
    ///   - playerId: The player's ID
    ///   - achievements: All achievements
    ///   - results: All GameResult records to analyze
    /// - Returns: Array of tuples with achievement and times earned, sorted by times earned descending
    static func playerAchievementHistory(
        playerId: String,
        achievements: [Achievement],
        results: [GameResult]
    ) -> [(achievement: Achievement, timesEarned: Int)] {
        let playerResults = results.filter { $0.playerId == playerId }
        
        // Count each achievement
        var achievementCounts: [String: Int] = [:]
        for result in playerResults {
            for achievementId in result.achievementIds {
                achievementCounts[achievementId, default: 0] += 1
            }
        }
        
        // Map to achievements and sort
        return achievements
            .compactMap { achievement -> (achievement: Achievement, timesEarned: Int)? in
                let count = achievementCounts[achievement.id] ?? 0
                return (achievement: achievement, timesEarned: count)
            }
            .sorted { $0.timesEarned > $1.timesEarned }
    }
    
    // MARK: - Achievement Trends
    
    /// Calculates achievement earning trends over time.
    /// - Parameters:
    ///   - achievementId: The achievement's ID
    ///   - results: All GameResult records to analyze
    ///   - groupBy: How to group the results (daily, weekly, monthly)
    /// - Returns: Array of tuples with date and count, sorted by date ascending
    static func achievementTrend(
        achievementId: String,
        results: [GameResult],
        groupBy: TimeGrouping
    ) -> [(date: Date, count: Int)] {
        let relevantResults = results.filter { $0.achievementIds.contains(achievementId) }
        
        let calendar = Calendar.current
        var groupedCounts: [Date: Int] = [:]
        
        for result in relevantResults {
            let groupDate: Date
            switch groupBy {
            case .daily:
                groupDate = calendar.startOfDay(for: result.timestamp)
            case .weekly:
                groupDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: result.timestamp)) ?? result.timestamp
            case .monthly:
                groupDate = calendar.date(from: calendar.dateComponents([.year, .month], from: result.timestamp)) ?? result.timestamp
            }
            
            groupedCounts[groupDate, default: 0] += 1
        }
        
        return groupedCounts
            .map { (date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    /// Calculates achievement earning trends by tournament week.
    /// - Parameters:
    ///   - achievementId: The achievement's ID
    ///   - results: All GameResult records to analyze
    /// - Returns: Array of tuples with week number and count, sorted by week ascending
    static func achievementTrendByWeek(
        achievementId: String,
        results: [GameResult]
    ) -> [(week: Int, count: Int)] {
        let relevantResults = results.filter { $0.achievementIds.contains(achievementId) }
        
        var weekCounts: [Int: Int] = [:]
        for result in relevantResults {
            weekCounts[result.week, default: 0] += 1
        }
        
        return weekCounts
            .map { (week: $0.key, count: $0.value) }
            .sorted { $0.week < $1.week }
    }
    
    // MARK: - Top Achievement Earners
    
    /// Ranks players by their total achievement points.
    /// - Parameter players: All players to analyze
    /// - Returns: Array of tuples with player and achievement points, sorted by points descending
    static func topAchievementEarners(players: [Player]) -> [(player: Player, achievementPoints: Int)] {
        players
            .map { (player: $0, achievementPoints: $0.achievementPoints) }
            .sorted { $0.achievementPoints > $1.achievementPoints }
    }
    
    /// Calculates achievement stats for all achievements at once.
    /// - Parameters:
    ///   - achievements: All achievements
    ///   - results: All GameResult records
    /// - Returns: Dictionary mapping achievement ID to stats tuple
    static func allAchievementStats(
        achievements: [Achievement],
        results: [GameResult]
    ) -> [String: (total: Int, byPlayer: [String: Int])] {
        var stats: [String: (total: Int, byPlayer: [String: Int])] = [:]
        
        for achievement in achievements {
            let total = totalTimesEarned(achievementId: achievement.id, results: results)
            let byPlayer = earnedByPlayer(achievementId: achievement.id, results: results)
            stats[achievement.id] = (total: total, byPlayer: byPlayer)
        }
        
        return stats
    }
    
    // MARK: - Fetch Helpers
    
    /// Fetches all achievements from the context.
    static func fetchAllAchievements(context: ModelContext) -> [Achievement] {
        let descriptor = FetchDescriptor<Achievement>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }
}
