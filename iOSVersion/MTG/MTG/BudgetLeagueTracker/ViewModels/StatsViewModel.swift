import Foundation
import SwiftData

/// ViewModel for the Stats view.
/// Provides read-only access to player stats, weekly standings, tournament standings, and chart data.
@Observable
final class StatsViewModel {
    private let context: ModelContext
    
    // MARK: - Published State
    
    var players: [Player] = []
    var achievements: [Achievement] = []
    var gameResults: [GameResult] = []
    var currentWeek: Int = 0
    var isLeagueStarted: Bool = false
    var tournamentName: String = ""
    var totalWeeks: Int = 0
    
    /// Selected player for single-player charts (nil means "All Players")
    var selectedPlayerId: String? = nil
    
    var hasPlayers: Bool {
        !players.isEmpty
    }
    
    var hasGameResults: Bool {
        !gameResults.isEmpty
    }
    
    // MARK: - Basic Computed Properties
    
    /// Weekly standings for the current week, sorted by weekly points descending.
    var weeklyStandings: [(player: Player, points: WeeklyPlayerPoints)] {
        guard let tournament = LeagueEngine.fetchActiveTournament(context: context) else { return [] }
        let weeklyPoints = tournament.weeklyPointsByPlayer
        let presentIds = tournament.presentPlayerIds
        
        let presentPlayers = players.filter { presentIds.contains($0.id) }
        
        return presentPlayers
            .map { player in
                (player: player, points: weeklyPoints[player.id] ?? WeeklyPlayerPoints())
            }
            .sorted { $0.points.total > $1.points.total }
    }
    
    /// Tournament standings showing all players sorted by total points descending.
    var tournamentStandings: [(player: Player, totalPoints: Int)] {
        players
            .map { player in
                (player: player, totalPoints: player.placementPoints + player.achievementPoints)
            }
            .sorted { $0.totalPoints > $1.totalPoints }
    }
    
    var hasWeeklyStandings: Bool {
        isLeagueStarted && !weeklyStandings.isEmpty
    }
    
    // MARK: - Chart Data: Points Comparison
    
    /// Player points comparison data for grouped bar chart.
    var playerPointsComparison: [PlayerPointsData] {
        players
            .sorted { $0.totalPoints > $1.totalPoints }
            .map { PlayerPointsData(player: $0) }
    }
    
    // MARK: - Chart Data: Achievement Leaderboard
    
    /// Achievement leaderboard showing most earned achievements.
    var achievementLeaderboard: [AchievementEarnData] {
        AchievementStatsEngine.achievementLeaderboard(achievements: achievements, results: gameResults)
            .map { AchievementEarnData(achievement: $0.achievement, timesEarned: $0.totalEarned) }
    }
    
    /// Top achievement earners (players ranked by achievement points).
    var topAchievementEarners: [PlayerPointsData] {
        AchievementStatsEngine.topAchievementEarners(players: players)
            .map { PlayerPointsData(
                id: $0.player.id,
                name: $0.player.name,
                placementPoints: $0.player.placementPoints,
                achievementPoints: $0.achievementPoints
            )}
    }
    
    // MARK: - Chart Data: Placement Distribution
    
    /// Gets placement distribution data for a specific player.
    func placementDistribution(for player: Player) -> [PlacementData] {
        let distribution = StatsEngine.placementDistribution(playerId: player.id, results: gameResults)
        return PlacementData.from(distribution: distribution)
    }
    
    /// Placement distribution for selected player (or first player if none selected).
    var selectedPlayerPlacementDistribution: [PlacementData] {
        guard let player = selectedPlayer else { return [] }
        return placementDistribution(for: player)
    }
    
    /// The currently selected player, or first player if none selected.
    var selectedPlayer: Player? {
        if let selectedId = selectedPlayerId {
            return players.first { $0.id == selectedId }
        }
        return players.first
    }
    
    // MARK: - Chart Data: Performance Trends
    
    /// Gets performance trend data for a specific player.
    func performanceTrend(for player: Player) -> [PerformanceTrendData] {
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
    
    /// Performance trend for selected player.
    var selectedPlayerPerformanceTrend: [PerformanceTrendData] {
        guard let player = selectedPlayer else { return [] }
        return performanceTrend(for: player)
    }
    
    /// Multi-player performance trend data for line chart.
    var allPlayersPerformanceTrend: [PerformanceTrendData] {
        players.flatMap { performanceTrend(for: $0) }
    }
    
    // MARK: - Chart Data: Wins Comparison
    
    /// Wins comparison data for bar chart.
    var winsComparison: [WinsComparisonData] {
        players
            .sorted { $0.wins > $1.wins }
            .map { WinsComparisonData(player: $0) }
    }
    
    // MARK: - Chart Data: Points Breakdown
    
    /// Points breakdown for selected player (placement vs achievement).
    var selectedPlayerPointsBreakdown: [PointsBreakdownData] {
        guard let player = selectedPlayer else { return [] }
        return PointsBreakdownData.from(
            placementPoints: player.placementPoints,
            achievementPoints: player.achievementPoints
        )
    }
    
    // MARK: - Achievement Stats for Cards
    
    /// Gets detailed stats for a specific achievement.
    func achievementStats(for achievement: Achievement) -> (total: Int, topEarners: [(playerName: String, count: Int)]) {
        let total = AchievementStatsEngine.totalTimesEarned(achievementId: achievement.id, results: gameResults)
        let topEarners = AchievementStatsEngine.topEarners(
            achievementId: achievement.id,
            results: gameResults,
            players: players,
            limit: 5
        )
        return (total: total, topEarners: topEarners)
    }
    
    // MARK: - Initialization
    
    init(context: ModelContext) {
        self.context = context
        refresh()
    }
    
    // MARK: - Actions
    
    /// Refreshes state from SwiftData.
    func refresh() {
        // Fetch players
        let playerDescriptor = FetchDescriptor<Player>(sortBy: [SortDescriptor(\.name)])
        players = (try? context.fetch(playerDescriptor)) ?? []
        
        // Fetch achievements
        let achievementDescriptor = FetchDescriptor<Achievement>(sortBy: [SortDescriptor(\.name)])
        achievements = (try? context.fetch(achievementDescriptor)) ?? []
        
        // Fetch game results
        gameResults = StatsEngine.fetchAllResults(context: context)
        
        // Fetch tournament info
        if let tournament = LeagueEngine.fetchActiveTournament(context: context) {
            currentWeek = tournament.currentWeek
            totalWeeks = tournament.totalWeeks
            isLeagueStarted = true
            tournamentName = tournament.name
        } else {
            isLeagueStarted = false
            tournamentName = ""
            currentWeek = 0
            totalWeeks = 0
        }
    }
    
    /// Selects a player for single-player charts.
    func selectPlayer(_ player: Player?) {
        selectedPlayerId = player?.id
    }
    
    /// Returns a formatted stats subtitle for a player.
    func statsSubtitle(for player: Player) -> String {
        let total = player.placementPoints + player.achievementPoints
        return "\(total) pts • \(player.wins) wins • \(player.gamesPlayed) games • \(player.tournamentsPlayed) tournaments"
    }
}
