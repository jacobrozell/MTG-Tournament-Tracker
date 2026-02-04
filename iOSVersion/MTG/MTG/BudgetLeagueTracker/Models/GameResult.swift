import Foundation
import SwiftData

/// Represents a single game result for a player.
/// Each player in a pod gets their own GameResult record.
/// This enables historical tracking and detailed statistics.
@Model
final class GameResult {
    /// Unique identifier for this game result
    var id: String
    
    /// ID of the tournament this game belongs to
    var tournamentId: String
    
    /// Week number within the tournament (1-based)
    var week: Int
    
    /// Round number within the week (1-3)
    var round: Int
    
    /// ID of the player who achieved this result
    var playerId: String
    
    /// Placement in the pod (1-4, where 1 is first place)
    var placement: Int
    
    /// Points earned from placement
    var placementPoints: Int
    
    /// Points earned from achievements in this game
    var achievementPoints: Int
    
    /// JSON-encoded array of achievement IDs earned in this game
    var achievementIdsData: Data?
    
    /// When this game was recorded
    var timestamp: Date
    
    /// Pod identifier - all players in the same game share this ID
    /// Used for head-to-head statistics
    var podId: String
    
    // MARK: - Initialization
    
    /// Creates a new game result.
    init(
        id: String = UUID().uuidString,
        tournamentId: String,
        week: Int,
        round: Int,
        playerId: String,
        placement: Int,
        placementPoints: Int,
        achievementPoints: Int,
        achievementIds: [String] = [],
        timestamp: Date = Date(),
        podId: String
    ) {
        self.id = id
        self.tournamentId = tournamentId
        self.week = week
        self.round = round
        self.playerId = playerId
        self.placement = placement
        self.placementPoints = placementPoints
        self.achievementPoints = achievementPoints
        self.achievementIdsData = try? JSONEncoder().encode(achievementIds)
        self.timestamp = timestamp
        self.podId = podId
    }
    
    // MARK: - Achievement IDs
    
    /// Decodes and returns the list of achievement IDs earned in this game
    var achievementIds: [String] {
        get {
            guard let data = achievementIdsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            achievementIdsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Total points earned in this game (placement + achievement)
    var totalPoints: Int {
        placementPoints + achievementPoints
    }
    
    /// Whether this was a win (first place)
    var isWin: Bool {
        placement == 1
    }
}
