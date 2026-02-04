import Foundation
import SwiftData

/// ViewModel for the Player Detail view.
/// Provides comprehensive player statistics and handles player deletion.
@Observable
final class PlayerDetailViewModel {
    private let context: ModelContext
    
    // MARK: - Published State
    
    var player: Player
    var gameResults: [GameResult] = []
    var showDeleteConfirmation: Bool = false
    
    // MARK: - Computed Properties
    
    /// Win rate as a percentage (0-100)
    var winRatePercentage: Double {
        StatsEngine.winRate(for: player) * 100
    }
    
    /// Formatted win rate string
    var winRateString: String {
        String(format: "%.1f%%", winRatePercentage)
    }
    
    /// Average placement (1.0 - 4.0)
    var averagePlacement: Double {
        StatsEngine.averagePlacement(playerId: player.id, results: gameResults)
    }
    
    /// Formatted average placement string
    var averagePlacementString: String {
        averagePlacement > 0 ? String(format: "%.2f", averagePlacement) : "N/A"
    }
    
    /// Points per game average
    var pointsPerGame: Double {
        StatsEngine.pointsPerGame(for: player)
    }
    
    /// Formatted points per game string
    var pointsPerGameString: String {
        String(format: "%.1f", pointsPerGame)
    }
    
    /// Placement distribution for pie chart
    var placementDistribution: [PlacementData] {
        let distribution = StatsEngine.placementDistribution(playerId: player.id, results: gameResults)
        return PlacementData.from(distribution: distribution)
    }
    
    /// Performance trend data for line chart
    var performanceTrend: [PerformanceTrendData] {
        let playerResults = gameResults
            .filter { $0.playerId == player.id }
            .sorted { $0.week < $1.week || ($0.week == $1.week && $0.round < $1.round) }
        
        var cumulativePoints = 0
        var cumulativePlacement = 0
        var cumulativeAchievement = 0
        var weeklyData: [Int: PerformanceTrendData] = [:]
        
        for result in playerResults {
            cumulativePoints += result.totalPoints
            cumulativePlacement += result.placementPoints
            cumulativeAchievement += result.achievementPoints
            
            // Update or create entry for this week (keep latest cumulative)
            weeklyData[result.week] = PerformanceTrendData(
                id: "\(player.id)-\(result.week)",
                playerName: player.name,
                week: result.week,
                cumulativePoints: cumulativePoints,
                placementPoints: cumulativePlacement,
                achievementPoints: cumulativeAchievement
            )
        }
        
        return weeklyData.values.sorted { $0.week < $1.week }
    }
    
    /// Whether the player has any game results
    var hasGameResults: Bool {
        !gameResults.filter { $0.playerId == player.id }.isEmpty
    }
    
    // MARK: - Initialization
    
    init(context: ModelContext, player: Player) {
        self.context = context
        self.player = player
        refresh()
    }
    
    // MARK: - Actions
    
    /// Refreshes data from SwiftData.
    func refresh() {
        // Fetch the latest player data
        let descriptor = FetchDescriptor<Player>()
        if let players = try? context.fetch(descriptor),
           let updatedPlayer = players.first(where: { $0.id == player.id }) {
            player = updatedPlayer
        }
        
        // Fetch all game results for charts
        gameResults = StatsEngine.fetchAllResults(context: context)
    }
    
    /// Shows the delete confirmation dialog.
    func confirmDelete() {
        showDeleteConfirmation = true
    }
    
    /// Deletes the player from the database.
    /// Returns true if deletion was successful.
    func deletePlayer() -> Bool {
        LeagueEngine.removePlayer(context: context, id: player.id)
        return true
    }
}
