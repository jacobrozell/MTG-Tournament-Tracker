import Foundation
import SwiftData

/// ViewModel for the Players view.
/// Manages player list display and adding new players.
@Observable
final class PlayersViewModel {
    private let context: ModelContext
    
    // MARK: - Published State
    
    var players: [Player] = []
    var newPlayerName: String = ""
    
    // MARK: - Computed Properties
    
    var hasPlayers: Bool {
        !players.isEmpty
    }
    
    var canAddPlayer: Bool {
        !newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Initialization
    
    init(context: ModelContext) {
        self.context = context
        refresh()
    }
    
    // MARK: - Actions
    
    /// Refreshes player data from SwiftData.
    func refresh() {
        let descriptor = FetchDescriptor<Player>(
            sortBy: [SortDescriptor(\.name)]
        )
        players = (try? context.fetch(descriptor)) ?? []
    }
    
    /// Adds a new player with the current name.
    func addPlayer() {
        guard canAddPlayer else { return }
        LeagueEngine.addPlayer(context: context, name: newPlayerName)
        newPlayerName = ""
        refresh()
    }
    
    /// Returns a subtitle string for a player showing key stats.
    func subtitle(for player: Player) -> String {
        let parts: [String] = [
            "\(player.totalPoints) pts",
            "\(player.gamesPlayed) games",
            "\(player.wins) wins"
        ]
        return parts.joined(separator: " • ")
    }
}
