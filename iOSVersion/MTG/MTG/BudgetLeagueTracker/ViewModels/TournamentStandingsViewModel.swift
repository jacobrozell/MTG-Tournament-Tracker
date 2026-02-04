import Foundation
import SwiftData

/// ViewModel for the Tournament Standings view.
/// Shows all players sorted by total tournament points.
@Observable
final class TournamentStandingsViewModel {
    private let context: ModelContext
    
    // MARK: - Published State
    
    var sortedPlayers: [Player] = []
    var isFinal: Bool = false
    var tournamentName: String = ""
    
    // MARK: - Initialization
    
    init(context: ModelContext) {
        self.context = context
        refresh()
    }
    
    // MARK: - Actions
    
    /// Refreshes state from SwiftData.
    func refresh() {
        let descriptor = FetchDescriptor<Player>()
        let allPlayers = (try? context.fetch(descriptor)) ?? []
        
        // Sort by total points descending
        sortedPlayers = allPlayers.sorted { $0.totalPoints > $1.totalPoints }
        
        if let tournament = LeagueEngine.fetchActiveTournament(context: context) {
            isFinal = tournament.isFinalWeek || tournament.status == .completed
            tournamentName = tournament.name
        } else if let state = LeagueEngine.fetchLeagueState(context: context),
                  let tournamentId = state.activeTournamentId,
                  let tournament = LeagueEngine.fetchTournament(context: context, id: tournamentId) {
            isFinal = tournament.status == .completed
            tournamentName = tournament.name
        }
    }
    
    /// Closes tournament standings and returns to tournaments list.
    func close() {
        LeagueEngine.closeTournamentStandings(context: context)
    }
}
