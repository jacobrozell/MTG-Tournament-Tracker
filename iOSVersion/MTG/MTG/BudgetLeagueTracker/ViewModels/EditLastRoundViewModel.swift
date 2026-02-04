import Foundation
import SwiftData

/// ViewModel for editing the last completed round.
/// Loads data from the last PodSnapshot and allows modification of placements and achievements.
@Observable
final class EditLastRoundViewModel {
    private let context: ModelContext
    let tournamentId: String
    
    // MARK: - State
    
    /// Players in the last round
    var players: [Player] = []
    
    /// Active achievements for that round
    var achievements: [Achievement] = []
    
    /// Whether achievements were enabled for that round
    var achievementsEnabled: Bool = false
    
    /// Editable placements (playerId -> place 1-4)
    private(set) var placements: [String: Int] = [:]
    
    /// Editable achievement checks ("playerId:achievementId" -> checked)
    private(set) var achievementChecks: Set<String> = []
    
    /// The original snapshot being edited
    private var originalSnapshot: PodSnapshot?
    
    /// Week number of the round being edited
    private(set) var weekNumber: Int = 1
    
    /// Round number being edited
    private(set) var roundNumber: Int = 1
    
    // MARK: - Computed Properties
    
    /// Whether there is a round to edit
    var hasRoundToEdit: Bool {
        originalSnapshot != nil
    }
    
    /// Title for the edit view
    var title: String {
        "Edit Round \(roundNumber)"
    }
    
    /// Subtitle showing week info
    var subtitle: String {
        "Week \(weekNumber)"
    }
    
    // MARK: - Initialization
    
    init(context: ModelContext, tournamentId: String) {
        self.context = context
        self.tournamentId = tournamentId
        loadSnapshot()
    }
    
    // MARK: - Loading
    
    /// Loads the last snapshot and reconstructs editable state.
    private func loadSnapshot() {
        guard let tournament = fetchTournament() else { return }
        guard let snapshot = tournament.podHistorySnapshots.last else { return }
        
        originalSnapshot = snapshot
        weekNumber = tournament.currentWeek
        roundNumber = tournament.currentRound
        achievementsEnabled = tournament.achievementsOnThisWeek
        
        // Load placements from snapshot
        placements = snapshot.placements
        
        // Load achievement checks from snapshot
        achievementChecks = Set(snapshot.achievementChecks.map { "\($0.playerId):\($0.achievementId)" })
        
        // Load players by ID
        let playerDescriptor = FetchDescriptor<Player>()
        if let allPlayers = try? context.fetch(playerDescriptor) {
            players = allPlayers.filter { snapshot.playerIds.contains($0.id) }
            // Sort by placement for consistent display
            players.sort { (placements[$0.id] ?? 4) < (placements[$1.id] ?? 4) }
        }
        
        // Load achievements
        let achievementDescriptor = FetchDescriptor<Achievement>()
        if let allAchievements = try? context.fetch(achievementDescriptor) {
            achievements = allAchievements.filter { tournament.activeAchievementIds.contains($0.id) }
        }
    }
    
    // MARK: - Placement Methods
    
    /// Returns the current placement for a player.
    func placement(for playerId: String) -> Int {
        placements[playerId] ?? 4
    }
    
    /// Sets the placement for a player.
    func setPlacement(for playerId: String, place: Int) {
        placements[playerId] = place
    }
    
    // MARK: - Achievement Methods
    
    /// Returns whether an achievement is checked for a player.
    func isAchievementChecked(playerId: String, achievementId: String) -> Bool {
        achievementChecks.contains("\(playerId):\(achievementId)")
    }
    
    /// Toggles an achievement check for a player.
    func toggleAchievementCheck(playerId: String, achievementId: String) {
        let key = "\(playerId):\(achievementId)"
        if achievementChecks.contains(key) {
            achievementChecks.remove(key)
        } else {
            achievementChecks.insert(key)
        }
    }
    
    // MARK: - Actions
    
    /// Saves the edited round, applying changes to stats and GameResults.
    func save() {
        LeagueEngine.applyEditedRound(
            context: context,
            newPlacements: placements,
            newAchievementChecks: achievementChecks
        )
    }
    
    // MARK: - Helpers
    
    private func fetchTournament() -> Tournament? {
        let descriptor = FetchDescriptor<Tournament>()
        let tournaments = (try? context.fetch(descriptor)) ?? []
        return tournaments.first { $0.id == tournamentId }
    }
}
