import Foundation
import SwiftData

/// ViewModel for the Tournament Detail view.
/// Manages tournament landing page including pods, standings, and navigation.
/// Absorbs functionality from PodsViewModel for ongoing tournaments.
@Observable
final class TournamentDetailViewModel {
    private let context: ModelContext
    let tournamentId: String
    
    // MARK: - Published State
    
    var tournament: Tournament?
    var pods: [[Player]] = []
    var activeAchievements: [Achievement] = []
    
    private var allPlayers: [Player] = []
    private var podHistoryCount: Int = 0
    
    // MARK: - Navigation State
    
    var showAttendance: Bool = false
    var showEditLastRound: Bool = false
    
    // MARK: - Computed Properties: Tournament Info
    
    var tournamentName: String {
        tournament?.name ?? "Tournament"
    }
    
    var isOngoing: Bool {
        tournament?.status == .ongoing
    }
    
    var isCompleted: Bool {
        tournament?.status == .completed
    }
    
    var currentWeek: Int {
        tournament?.currentWeek ?? 1
    }
    
    var totalWeeks: Int {
        tournament?.totalWeeks ?? 1
    }
    
    var currentRound: Int {
        tournament?.currentRound ?? 1
    }
    
    var achievementsOnThisWeek: Bool {
        tournament?.achievementsOnThisWeek ?? true
    }
    
    var dateRangeString: String {
        tournament?.dateRangeString ?? ""
    }
    
    var weekProgressString: String {
        "Week \(currentWeek) of \(totalWeeks)"
    }
    
    var roundString: String {
        "Round \(currentRound)"
    }
    
    var presentPlayerIds: [String] {
        tournament?.presentPlayerIds ?? []
    }
    
    var hasPresentPlayers: Bool {
        !presentPlayerIds.isEmpty
    }
    
    // MARK: - Computed Properties: Pod Management
    
    var canGeneratePods: Bool {
        hasPresentPlayers
    }
    
    var canEdit: Bool {
        podHistoryCount > 0
    }
    
    /// Weekly standings for inline display, sorted by total points descending.
    var weeklyStandings: [(player: Player, points: WeeklyPlayerPoints)] {
        guard let tournament = tournament else { return [] }
        let weeklyPoints = tournament.weeklyPointsByPlayer
        
        let presentPlayers = allPlayers.filter { presentPlayerIds.contains($0.id) }
        
        return presentPlayers
            .map { player in
                (player: player, points: weeklyPoints[player.id] ?? WeeklyPlayerPoints())
            }
            .sorted { $0.points.total > $1.points.total }
    }
    
    // MARK: - Computed Properties: Final Standings
    
    /// Final standings for completed tournaments, using tournament-specific game results.
    var finalStandings: [(player: Player, points: Int, placementPoints: Int, achievementPoints: Int, wins: Int)] {
        guard let tournament = tournament, tournament.status == .completed else { return [] }
        
        // Get all game results for this tournament
        let results = StatsEngine.fetchResultsForTournament(tournament.id, context: context)
        
        // Calculate tournament-specific stats per player
        var playerStats: [String: (points: Int, placementPoints: Int, achievementPoints: Int, wins: Int)] = [:]
        
        for result in results {
            let current = playerStats[result.playerId] ?? (0, 0, 0, 0)
            playerStats[result.playerId] = (
                points: current.points + result.totalPoints,
                placementPoints: current.placementPoints + result.placementPoints,
                achievementPoints: current.achievementPoints + result.achievementPoints,
                wins: current.wins + (result.isWin ? 1 : 0)
            )
        }
        
        // Map to players and sort by points
        return playerStats
            .compactMap { playerId, stats -> (player: Player, points: Int, placementPoints: Int, achievementPoints: Int, wins: Int)? in
                guard let player = allPlayers.first(where: { $0.id == playerId }) else { return nil }
                return (player: player, points: stats.points, placementPoints: stats.placementPoints, achievementPoints: stats.achievementPoints, wins: stats.wins)
            }
            .sorted { $0.points > $1.points }
    }
    
    /// Winner name for completed tournaments.
    var winnerName: String? {
        finalStandings.first?.player.name
    }
    
    // MARK: - Initialization
    
    init(context: ModelContext, tournamentId: String) {
        self.context = context
        self.tournamentId = tournamentId
        refresh()
    }
    
    // MARK: - Actions: Refresh
    
    /// Refreshes state from SwiftData.
    func refresh() {
        // Fetch tournament
        tournament = LeagueEngine.fetchTournament(context: context, id: tournamentId)
        
        // Fetch all players
        let playerDescriptor = FetchDescriptor<Player>()
        allPlayers = (try? context.fetch(playerDescriptor)) ?? []
        
        // Fetch achievements
        let achievementDescriptor = FetchDescriptor<Achievement>()
        let allAchievements = (try? context.fetch(achievementDescriptor)) ?? []
        
        if let tournament = tournament {
            podHistoryCount = tournament.podHistorySnapshots.count
            
            // Filter to active achievements
            activeAchievements = allAchievements.filter { tournament.activeAchievementIds.contains($0.id) }
        }
    }
    
    // MARK: - Actions: Pod Management
    
    /// Generates pods for the current round.
    func generatePods() {
        guard let tournament = tournament else { return }
        
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
        refresh()
    }
    
    /// Sets placement for a player (auto-saves immediately).
    func setPlacement(for playerId: String, place: Int) {
        LeagueEngine.updatePlacement(context: context, playerId: playerId, placement: place)
    }
    
    /// Returns placement for a player (default 4).
    func placement(for playerId: String) -> Int {
        guard let tournament = tournament else { return 4 }
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
        guard let tournament = tournament else { return false }
        return tournament.roundAchievementChecks.contains("\(playerId):\(achievementId)")
    }
    
    /// Opens the edit view for the last completed round.
    func editLastRound() {
        showEditLastRound = true
    }
    
    /// Called when the edit last round view saves changes.
    func onEditLastRoundSaved() {
        pods = []
        refresh()
    }
    
    /// Advances to the next round or next week.
    func nextRound() {
        LeagueEngine.nextRound(context: context)
        pods = []
        refresh()
    }
    
    // MARK: - Actions: Navigation
    
    /// Sets this tournament as the active tournament.
    func setAsActiveTournament() {
        guard let state = LeagueEngine.fetchLeagueState(context: context) else { return }
        state.activeTournamentId = tournamentId
        try? context.save()
    }
    
    /// Presents the attendance sheet (caller presents via .sheet(isPresented: $viewModel.showAttendance)).
    func goToAttendance() {
        setAsActiveTournament()
        showAttendance = true
    }
}
