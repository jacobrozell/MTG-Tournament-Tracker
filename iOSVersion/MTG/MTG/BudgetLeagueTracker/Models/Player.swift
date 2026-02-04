import Foundation
import SwiftData

/// Represents a player in the league.
/// Players persist across tournaments. Stats are all-time cumulative totals.
@Model
final class Player {
    /// Unique identifier for the player
    var id: String
    
    /// Player's display name
    var name: String
    
    /// Cumulative placement points earned across all games (all-time)
    var placementPoints: Int
    
    /// Cumulative achievement points earned across all games (all-time)
    var achievementPoints: Int
    
    /// Total number of first-place finishes (all-time)
    var wins: Int
    
    /// Total number of games played (all-time)
    var gamesPlayed: Int
    
    /// Number of tournaments this player has participated in
    var tournamentsPlayed: Int
    
    /// Creates a new player with the given name and zeroed stats.
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - name: Player's display name
    ///   - placementPoints: Initial placement points (default 0)
    ///   - achievementPoints: Initial achievement points (default 0)
    ///   - wins: Initial wins count (default 0)
    ///   - gamesPlayed: Initial games played count (default 0)
    ///   - tournamentsPlayed: Initial tournaments count (default 0)
    init(
        id: String = UUID().uuidString,
        name: String,
        placementPoints: Int = AppConstants.Scoring.initialPlacementPoints,
        achievementPoints: Int = AppConstants.Scoring.initialAchievementPoints,
        wins: Int = AppConstants.Scoring.initialWins,
        gamesPlayed: Int = AppConstants.Scoring.initialGamesPlayed,
        tournamentsPlayed: Int = 0
    ) {
        self.id = id
        self.name = name
        self.placementPoints = placementPoints
        self.achievementPoints = achievementPoints
        self.wins = wins
        self.gamesPlayed = gamesPlayed
        self.tournamentsPlayed = tournamentsPlayed
    }
    
    /// Total points (placement + achievement) - all-time
    var totalPoints: Int {
        placementPoints + achievementPoints
    }
}
