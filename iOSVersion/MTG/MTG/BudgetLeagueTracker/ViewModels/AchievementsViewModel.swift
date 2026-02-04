import Foundation
import SwiftData

/// ViewModel for the Achievements view.
/// Manages achievement list display, statistics, and navigation to add new achievements.
@Observable
final class AchievementsViewModel {
    private let context: ModelContext
    
    // MARK: - Published State
    
    var achievements: [Achievement] = []
    var players: [Player] = []
    var gameResults: [GameResult] = []
    
    /// Whether the new achievement sheet is showing
    var isShowingNewAchievement: Bool = false
    
    /// Cached achievement stats: [achievementId: (total, byPlayer)]
    private var cachedStats: [String: (total: Int, byPlayer: [String: Int])] = [:]
    
    // MARK: - Basic Computed Properties
    
    var hasAchievements: Bool {
        !achievements.isEmpty
    }
    
    var hasGameResults: Bool {
        !gameResults.isEmpty
    }
    
    // MARK: - Achievement Stats Summary
    
    /// Total number of achievements earned across all players and games.
    var totalAchievementsEarned: Int {
        AchievementStatsEngine.totalAchievementsEarned(results: gameResults)
    }
    
    /// The most frequently earned achievement.
    var mostPopularAchievement: Achievement? {
        AchievementStatsEngine.mostPopularAchievement(achievements: achievements, results: gameResults)?.achievement
    }
    
    /// The least frequently earned achievement (that has been earned at least once).
    var rarestAchievement: Achievement? {
        AchievementStatsEngine.rarestAchievement(achievements: achievements, results: gameResults)?.achievement
    }
    
    /// Stats summary for the header.
    var statsSummary: AchievementStatsSummary {
        let mostPopular = AchievementStatsEngine.mostPopularAchievement(achievements: achievements, results: gameResults)
        let rarest = AchievementStatsEngine.rarestAchievement(achievements: achievements, results: gameResults)
        let leaderboard = AchievementStatsEngine.achievementLeaderboard(achievements: achievements, results: gameResults)
        let uniqueEarned = leaderboard.filter { $0.totalEarned > 0 }.count
        
        return AchievementStatsSummary(
            totalEarned: totalAchievementsEarned,
            mostPopularName: mostPopular?.achievement.name,
            mostPopularCount: mostPopular?.count ?? 0,
            rarestName: rarest?.achievement.name,
            rarestCount: rarest?.count ?? 0,
            uniqueAchievementsEarned: uniqueEarned
        )
    }
    
    // MARK: - Achievement Leaderboard
    
    /// Achievement leaderboard for pie chart (distribution of earned achievements).
    var achievementDistribution: [AchievementEarnData] {
        AchievementStatsEngine.achievementLeaderboard(achievements: achievements, results: gameResults)
            .filter { $0.totalEarned > 0 }
            .map { AchievementEarnData(achievement: $0.achievement, timesEarned: $0.totalEarned) }
    }
    
    // MARK: - Per-Achievement Stats
    
    /// Gets total times earned for an achievement.
    func totalTimesEarned(for achievement: Achievement) -> Int {
        if let cached = cachedStats[achievement.id] {
            return cached.total
        }
        return AchievementStatsEngine.totalTimesEarned(achievementId: achievement.id, results: gameResults)
    }
    
    /// Gets top earners for an achievement.
    func topEarners(for achievement: Achievement, limit: Int = 3) -> [(playerName: String, count: Int)] {
        AchievementStatsEngine.topEarners(
            achievementId: achievement.id,
            results: gameResults,
            players: players,
            limit: limit
        )
    }
    
    /// Gets full player breakdown for an achievement.
    func playerBreakdown(for achievement: Achievement) -> [AchievementPlayerBreakdown] {
        let byPlayer = AchievementStatsEngine.earnedByPlayer(achievementId: achievement.id, results: gameResults)
        let playerNameMap = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0.name) })
        
        return byPlayer
            .map { AchievementPlayerBreakdown(
                id: $0.key,
                playerName: playerNameMap[$0.key] ?? "Unknown",
                count: $0.value
            )}
            .sorted { $0.count > $1.count }
    }
    
    // MARK: - Achievements with Stats
    
    /// Achievements sorted by total times earned (most earned first).
    var achievementsByPopularity: [Achievement] {
        let leaderboard = AchievementStatsEngine.achievementLeaderboard(achievements: achievements, results: gameResults)
        return leaderboard.map { $0.achievement }
    }
    
    /// Achievements sorted by name (default).
    var achievementsByName: [Achievement] {
        achievements.sorted { $0.name < $1.name }
    }
    
    // MARK: - Initialization
    
    init(context: ModelContext) {
        self.context = context
        refresh()
    }
    
    // MARK: - Actions
    
    /// Refreshes state from SwiftData.
    func refresh() {
        // Fetch achievements
        let achievementDescriptor = FetchDescriptor<Achievement>(sortBy: [SortDescriptor(\.name)])
        achievements = (try? context.fetch(achievementDescriptor)) ?? []
        
        // Fetch players
        let playerDescriptor = FetchDescriptor<Player>(sortBy: [SortDescriptor(\.name)])
        players = (try? context.fetch(playerDescriptor)) ?? []
        
        // Fetch game results
        gameResults = StatsEngine.fetchAllResults(context: context)
        
        // Update cached stats
        cachedStats = AchievementStatsEngine.allAchievementStats(achievements: achievements, results: gameResults)
    }
    
    /// Shows the new achievement sheet.
    func showNewAchievement() {
        isShowingNewAchievement = true
    }
    
    /// Dismisses the new achievement sheet and refreshes.
    func dismissNewAchievement() {
        isShowingNewAchievement = false
        refresh()
    }
    
    /// Creates a view model for the new achievement sheet.
    func makeNewAchievementViewModel() -> NewAchievementViewModel {
        let vm = NewAchievementViewModel(context: context)
        vm.onAdd = { [weak self] in
            self?.dismissNewAchievement()
        }
        vm.onCancel = { [weak self] in
            self?.isShowingNewAchievement = false
        }
        return vm
    }
    
    /// Removes an achievement.
    func removeAchievement(_ achievement: Achievement) {
        LeagueEngine.removeAchievement(context: context, id: achievement.id)
        refresh()
    }
    
    /// Toggles the alwaysOn status of an achievement.
    func toggleAlwaysOn(_ achievement: Achievement) {
        LeagueEngine.setAchievementAlwaysOn(
            context: context,
            id: achievement.id,
            alwaysOn: !achievement.alwaysOn
        )
        refresh()
    }
}
