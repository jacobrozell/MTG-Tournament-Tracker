import Foundation
import SwiftData

/// Status of a tournament
enum TournamentStatus: String, Codable {
    case ongoing    // Tournament in progress
    case completed  // Tournament finished
}

/// Represents a tournament/league season.
/// Stores tournament metadata and transient weekly state during active play.
@Model
final class Tournament {
    // MARK: - Tournament Metadata
    
    /// Unique identifier for the tournament
    var id: String
    
    /// Display name for the tournament (e.g., "Spring 2026 League")
    var name: String
    
    /// Total number of weeks in the tournament
    var totalWeeks: Int
    
    /// Number of random achievements to roll each week
    var randomAchievementsPerWeek: Int
    
    /// When the tournament was started
    var startDate: Date
    
    /// When the tournament was completed (nil if ongoing)
    var endDate: Date?
    
    /// Raw status value for SwiftData storage
    var statusRaw: String
    
    // MARK: - Weekly State (transient, for active tournaments)
    
    /// Current week number (1-based)
    var currentWeek: Int
    
    /// Current round within the week (1-3)
    var currentRound: Int
    
    /// Whether achievements count for the current week
    var achievementsOnThisWeek: Bool
    
    /// JSON-encoded array of present player IDs for the current week
    var presentPlayerIdsData: Data?
    
    /// JSON-encoded dictionary of player ID to weekly points [String: WeeklyPlayerPoints]
    var weeklyPointsJSON: Data?
    
    /// JSON-encoded array of active achievement IDs for the current week
    var activeAchievementIdsData: Data?
    
    /// JSON-encoded array of pod history snapshots for undo functionality
    var podHistoryData: Data?
    
    /// JSON-encoded dictionary of current round placements (playerId -> place 1-4)
    var roundPlacementsData: Data?
    
    /// JSON-encoded set of current round achievement checks ("playerId:achievementId")
    var roundAchievementChecksData: Data?
    
    // MARK: - Initialization
    
    /// Creates a new tournament with the given settings.
    init(
        id: String = UUID().uuidString,
        name: String,
        totalWeeks: Int = AppConstants.League.defaultTotalWeeks,
        randomAchievementsPerWeek: Int = AppConstants.League.defaultRandomAchievementsPerWeek,
        startDate: Date = Date(),
        endDate: Date? = nil,
        status: TournamentStatus = .ongoing,
        currentWeek: Int = AppConstants.League.defaultCurrentWeek,
        currentRound: Int = AppConstants.League.defaultCurrentRound,
        achievementsOnThisWeek: Bool = AppConstants.League.defaultAchievementsOnThisWeek
    ) {
        self.id = id
        self.name = name
        self.totalWeeks = totalWeeks
        self.randomAchievementsPerWeek = randomAchievementsPerWeek
        self.startDate = startDate
        self.endDate = endDate
        self.statusRaw = status.rawValue
        self.currentWeek = currentWeek
        self.currentRound = currentRound
        self.achievementsOnThisWeek = achievementsOnThisWeek
    }
    
    // MARK: - Status Convenience
    
    /// Returns the tournament status as a TournamentStatus enum value
    var status: TournamentStatus {
        get {
            TournamentStatus(rawValue: statusRaw) ?? .ongoing
        }
        set {
            statusRaw = newValue.rawValue
        }
    }
    
    // MARK: - Present Players
    
    /// Decodes and returns the list of present player IDs
    var presentPlayerIds: [String] {
        get {
            guard let data = presentPlayerIdsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            presentPlayerIdsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // MARK: - Weekly Points
    
    /// Decodes and returns the weekly points dictionary
    var weeklyPointsByPlayer: [String: WeeklyPlayerPoints] {
        get {
            guard let data = weeklyPointsJSON else { return [:] }
            return (try? JSONDecoder().decode([String: WeeklyPlayerPoints].self, from: data)) ?? [:]
        }
        set {
            weeklyPointsJSON = try? JSONEncoder().encode(newValue)
        }
    }
    
    // MARK: - Active Achievements
    
    /// Decodes and returns the list of active achievement IDs for this week
    var activeAchievementIds: [String] {
        get {
            guard let data = activeAchievementIdsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            activeAchievementIdsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // MARK: - Pod History
    
    /// Decodes and returns the pod history snapshots for undo
    var podHistorySnapshots: [PodSnapshot] {
        get {
            guard let data = podHistoryData else { return [] }
            return (try? JSONDecoder().decode([PodSnapshot].self, from: data)) ?? []
        }
        set {
            podHistoryData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // MARK: - Current Round Data (for auto-save)
    
    /// Decodes and returns the current round placements (playerId -> place)
    var roundPlacements: [String: Int] {
        get {
            guard let data = roundPlacementsData else { return [:] }
            return (try? JSONDecoder().decode([String: Int].self, from: data)) ?? [:]
        }
        set {
            roundPlacementsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// Decodes and returns the current round achievement checks
    var roundAchievementChecks: Set<String> {
        get {
            guard let data = roundAchievementChecksData else { return [] }
            return (try? JSONDecoder().decode(Set<String>.self, from: data)) ?? []
        }
        set {
            roundAchievementChecksData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Whether this is the final week
    var isFinalWeek: Bool {
        currentWeek >= totalWeeks
    }
    
    /// Formatted date range string
    var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        let start = formatter.string(from: startDate)
        if let end = endDate {
            return "\(start) - \(formatter.string(from: end))"
        } else {
            return "Started \(start)"
        }
    }
}
