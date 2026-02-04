import Foundation
import SwiftData

/// ViewModel for the Tournaments view.
/// Manages tournament list display and navigation.
@Observable
final class TournamentsViewModel {
    private let context: ModelContext
    
    // MARK: - Published State
    
    var ongoingTournaments: [Tournament] = []
    var completedTournaments: [Tournament] = []
    var players: [Player] = []
    
    // MARK: - Computed Properties
    
    var hasOngoingTournaments: Bool {
        !ongoingTournaments.isEmpty
    }
    
    var hasCompletedTournaments: Bool {
        !completedTournaments.isEmpty
    }
    
    var hasTournaments: Bool {
        hasOngoingTournaments || hasCompletedTournaments
    }
    
    // MARK: - Initialization
    
    init(context: ModelContext) {
        self.context = context
        refresh()
    }
    
    // MARK: - Actions
    
    /// Refreshes tournament data from SwiftData.
    func refresh() {
        // Fetch all tournaments
        let tournamentDescriptor = FetchDescriptor<Tournament>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        let allTournaments = (try? context.fetch(tournamentDescriptor)) ?? []
        
        // Split by status
        ongoingTournaments = allTournaments.filter { $0.status == .ongoing }
        completedTournaments = allTournaments.filter { $0.status == .completed }
        
        // Fetch all players for counts and winner lookup
        let playerDescriptor = FetchDescriptor<Player>(sortBy: [SortDescriptor(\.name)])
        players = (try? context.fetch(playerDescriptor)) ?? []
    }
    
    /// Returns the number of players who participated in a tournament.
    /// For ongoing tournaments, returns present player count.
    /// For completed tournaments, queries GameResults.
    func playerCount(for tournament: Tournament) -> Int {
        if tournament.status == .ongoing {
            return tournament.presentPlayerIds.count
        }
        
        // For completed tournaments, count unique players from GameResults
        let descriptor = FetchDescriptor<GameResult>()
        let allResults = (try? context.fetch(descriptor)) ?? []
        let results = allResults.filter { $0.tournamentId == tournament.id }
        let uniquePlayerIds = Set(results.map { $0.playerId })
        return uniquePlayerIds.count
    }
    
    /// Returns the winner's name for a completed tournament.
    /// The winner is the player with the most total points in that tournament's GameResults.
    func winnerName(for tournament: Tournament) -> String? {
        guard tournament.status == .completed else { return nil }
        
        let descriptor = FetchDescriptor<GameResult>()
        let allResults = (try? context.fetch(descriptor)) ?? []
        let results = allResults.filter { $0.tournamentId == tournament.id }
        
        guard !results.isEmpty else { return nil }
        
        // Sum points per player
        var pointsByPlayer: [String: Int] = [:]
        for result in results {
            pointsByPlayer[result.playerId, default: 0] += result.totalPoints
        }
        
        // Find player with most points
        guard let winnerId = pointsByPlayer.max(by: { $0.value < $1.value })?.key,
              let winner = players.first(where: { $0.id == winnerId }) else {
            return nil
        }
        
        return winner.name
    }
    
    /// Navigates to the new tournament screen.
    func createNewTournament() {
        LeagueEngine.setScreen(context: context, screen: .newTournament)
    }
    
    /// Sets a tournament as the active tournament (for context when navigating).
    /// Navigation is now handled by SwiftUI NavigationLink to TournamentDetailView.
    func setActiveTournament(_ tournament: Tournament) {
        guard let state = LeagueEngine.fetchLeagueState(context: context) else { return }
        state.activeTournamentId = tournament.id
        try? context.save()
    }
}
