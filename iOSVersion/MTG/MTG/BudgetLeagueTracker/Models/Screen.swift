import Foundation

/// Represents the current screen/view in the app navigation flow.
/// Persisted in LeagueState for state restoration.
enum Screen: String, Codable, CaseIterable {
    case tournaments          // Main tournaments list (was dashboard)
    case newTournament        // Create new tournament (was confirmNewTournament)
    case addPlayers           // Add players to tournament
    case attendance           // Mark weekly attendance
    case pods                 // Active pod/round management (legacy - now handled in TournamentDetailView)
    case tournamentStandings  // Final tournament standings
    case tournamentDetail     // Tournament landing page (new)
    
    // Legacy cases for backwards compatibility during transition
    case dashboard            // Maps to .tournaments
    case confirmNewTournament // Maps to .newTournament
}
