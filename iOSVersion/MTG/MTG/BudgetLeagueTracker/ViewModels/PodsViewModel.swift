import Foundation
import SwiftData

/// ViewModel for the Pods view.
/// Manages pod generation, placements, achievements with auto-save.
///
/// - Note: DEPRECATED - This ViewModel has been replaced by TournamentDetailViewModel.
///   Pod management is now accessed through the tournament landing page.
///   This file is kept for backwards compatibility and can be removed in a future update.
@available(*, deprecated, message: "Use TournamentDetailViewModel instead. Pod management is now part of the tournament landing page.")
@Observable
final class PodsViewModel {
    private let context: ModelContext
    
    // MARK: - Published State
    
    var isLeagueStarted: Bool = false
    var currentWeek: Int = 1
    var currentRound: Int = 1
    var achievementsOnThisWeek: Bool = true
    var pods: [[Player]] = []
    var activeAchievements: [Achievement] = []
    
    private var allPlayers: [Player] = []
    private var presentPlayerIds: [String] = []
    private var podHistoryCount: Int = 0
    
    // MARK: - Computed Properties
    
    var canGeneratePods: Bool {
        !presentPlayerIds.isEmpty
    }
    
    var canEdit: Bool {
        podHistoryCount > 0
    }
    
    /// Weekly standings for inline display, sorted by total points descending.
    var weeklyStandings: [(player: Player, points: WeeklyPlayerPoints)] {
        guard let tournament = LeagueEngine.fetchActiveTournament(context: context) else { return [] }
        let weeklyPoints = tournament.weeklyPointsByPlayer
        
        let presentPlayers = allPlayers.filter { presentPlayerIds.contains($0.id) }
        
        return presentPlayers
            .map { player in
                (player: player, points: weeklyPoints[player.id] ?? WeeklyPlayerPoints())
            }
            .sorted { $0.points.total > $1.points.total }
    }
    
    // MARK: - Initialization
    
    init(context: ModelContext) {
        self.context = context
        refresh()
    }
    
    // MARK: - Actions
    
    /// Refreshes state from SwiftData.
    func refresh() {
        let playerDescriptor = FetchDescriptor<Player>()
        allPlayers = (try? context.fetch(playerDescriptor)) ?? []
        
        let achievementDescriptor = FetchDescriptor<Achievement>()
        let allAchievements = (try? context.fetch(achievementDescriptor)) ?? []
        
        if let tournament = LeagueEngine.fetchActiveTournament(context: context) {
            isLeagueStarted = true
            currentWeek = tournament.currentWeek
            currentRound = tournament.currentRound
            achievementsOnThisWeek = tournament.achievementsOnThisWeek
            presentPlayerIds = tournament.presentPlayerIds
            podHistoryCount = tournament.podHistorySnapshots.count
            
            // Filter to active achievements
            activeAchievements = allAchievements.filter { tournament.activeAchievementIds.contains($0.id) }
        } else {
            isLeagueStarted = false
        }
    }
    
    /// Generates pods for the current round.
    func generatePods() {
        guard let tournament = LeagueEngine.fetchActiveTournament(context: context) else { return }
        
        pods = LeagueEngine.generatePodsForRound(
            players: allPlayers,
            presentPlayerIds: presentPlayerIds,
            currentRound: currentRound,
            weeklyPointsByPlayer: tournament.weeklyPointsByPlayer
        )
        
        // Clear any previous round data first
        LeagueEngine.clearRoundData(context: context)
        
        // Initialize placements with defaults and auto-save
        for pod in pods {
            for (index, player) in pod.enumerated() {
                let defaultPlace = min(index + 1, 4)
                LeagueEngine.updatePlacement(context: context, playerId: player.id, placement: defaultPlace)
            }
        }
    }
    
    /// Sets placement for a player (auto-saves immediately).
    func setPlacement(for playerId: String, place: Int) {
        LeagueEngine.updatePlacement(context: context, playerId: playerId, placement: place)
    }
    
    /// Returns placement for a player (default 4).
    func placement(for playerId: String) -> Int {
        guard let tournament = LeagueEngine.fetchActiveTournament(context: context) else { return 4 }
        return tournament.roundPlacements[playerId] ?? 4
    }
    
    /// Toggles an achievement check for a player (auto-saves immediately).
    func toggleAchievementCheck(playerId: String, achievementId: String) {
        let currentlyChecked = isAchievementChecked(playerId: playerId, achievementId: achievementId)
        LeagueEngine.updateAchievementCheck(
            context: context,
            playerId: playerId,
            achievementId: achievementId,
            checked: !currentlyChecked
        )
    }
    
    /// Returns whether an achievement is checked for a player.
    func isAchievementChecked(playerId: String, achievementId: String) -> Bool {
        guard let tournament = LeagueEngine.fetchActiveTournament(context: context) else { return false }
        return tournament.roundAchievementChecks.contains("\(playerId):\(achievementId)")
    }
    
    /// Opens edit for the last completed round (simplified - just undoes in deprecated view).
    func editLastRound() {
        LeagueEngine.undoLastPod(context: context)
        pods = []
        refresh()
    }
    
    /// Advances to the next round or next week.
    func nextRound() {
        LeagueEngine.nextRound(context: context)
        pods = []
        refresh()
    }
}
