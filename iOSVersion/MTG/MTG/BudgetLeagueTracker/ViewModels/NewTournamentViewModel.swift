import Foundation
import SwiftData

// #region agent log
enum AgentLog {
    static func write(location: String, message: String, data: [String: Any] = [:], hypothesisId: String) {
        let payload: [String: Any] = ["location": location, "message": message, "data": data, "hypothesisId": hypothesisId, "timestamp": Int(Date().timeIntervalSince1970 * 1000), "sessionId": "debug-session"]
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload) else { return }
        let path = "/Users/jrozell/Desktop/MTG/.cursor/debug.log"
        var dataToWrite = payloadData
        dataToWrite.append("\n".data(using: .utf8)!)
        if !FileManager.default.fileExists(atPath: path) { FileManager.default.createFile(atPath: path, contents: nil) }
        if let fh = FileHandle(forWritingAtPath: path) { fh.seekToEndOfFile(); fh.write(dataToWrite); try? fh.close() }
    }
}
// #endregion

/// ViewModel for the New Tournament view.
/// Handles tournament creation with name, settings, and player selection.
@Observable
final class NewTournamentViewModel {
    private let context: ModelContext
    private let instanceId = UUID().uuidString

    // MARK: - Published State
    
    /// Tournament name (required)
    var tournamentName: String = ""
    
    /// Total weeks in the tournament
    var totalWeeks: Int = AppConstants.League.defaultTotalWeeks
    
    /// Random achievements per week
    var randomAchievementsPerWeek: Int = AppConstants.League.defaultRandomAchievementsPerWeek
    
    /// All existing players
    var allPlayers: [Player] = []
    
    /// IDs of selected players for this tournament
    var selectedPlayerIds: Set<String> = []
    
    /// Name for adding a new player
    var newPlayerName: String = ""
    
    // MARK: - Computed Properties
    
    /// Whether the tournament can be created (has name and at least one player)
    var canCreateTournament: Bool {
        !tournamentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedPlayerIds.isEmpty
    }
    
    /// Whether a new player can be added
    var canAddPlayer: Bool {
        !newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Number of selected players
    var selectedPlayerCount: Int {
        selectedPlayerIds.count
    }
    
    // MARK: - Initialization
    
    init(context: ModelContext) {
        self.context = context
        // #region agent log
        AgentLog.write(location: "NewTournamentViewModel.swift:init", message: "ViewModel init", data: ["instanceId": instanceId], hypothesisId: "A")
        // #endregion
        refresh()
    }
    
    // MARK: - Actions
    
    /// Refreshes player list from SwiftData. Does not change selection (preserves user toggles).
    func refresh() {
        // #region agent log
        AgentLog.write(location: "NewTournamentViewModel.swift:refresh", message: "refresh entry", data: ["selectedCountBefore": selectedPlayerIds.count], hypothesisId: "B")
        // #endregion
        let descriptor = FetchDescriptor<Player>(sortBy: [SortDescriptor(\.name)])
        allPlayers = (try? context.fetch(descriptor)) ?? []
        // #region agent log
        AgentLog.write(location: "NewTournamentViewModel.swift:refresh", message: "refresh exit", data: ["selectedCountAfter": selectedPlayerIds.count, "allPlayersCount": allPlayers.count], hypothesisId: "B")
        // #endregion
    }
    
    /// Toggles player selection.
    func togglePlayer(_ player: Player) {
        if selectedPlayerIds.contains(player.id) {
            selectedPlayerIds.remove(player.id)
        } else {
            selectedPlayerIds.insert(player.id)
        }
    }
    
    /// Returns whether a player is selected.
    func isSelected(_ player: Player) -> Bool {
        selectedPlayerIds.contains(player.id)
    }
    
    /// Selects all players.
    func selectAll() {
        selectedPlayerIds = Set(allPlayers.map { $0.id })
    }
    
    /// Deselects all players.
    func deselectAll() {
        selectedPlayerIds.removeAll()
    }
    
    /// Adds a new player and selects them.
    func addPlayer() {
        // #region agent log
        AgentLog.write(location: "NewTournamentViewModel.swift:addPlayer", message: "addPlayer entry", data: ["tournamentName": tournamentName, "selectedCount": selectedPlayerIds.count, "instanceId": instanceId], hypothesisId: "A,B,E")
        // #endregion
        guard canAddPlayer else { return }
        
        if let player = LeagueEngine.addPlayer(context: context, name: newPlayerName) {
            selectedPlayerIds.insert(player.id)
            newPlayerName = ""
            refresh()
            // #region agent log
            AgentLog.write(location: "NewTournamentViewModel.swift:addPlayer", message: "addPlayer after refresh", data: ["selectedCount": selectedPlayerIds.count], hypothesisId: "B")
            // #endregion
        }
    }
    
    /// Creates the tournament and navigates to attendance.
    func createTournament() {
        guard canCreateTournament else { return }
        
        let trimmedName = tournamentName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Create tournament
        LeagueEngine.createTournament(
            context: context,
            name: trimmedName,
            totalWeeks: totalWeeks,
            randomPerWeek: randomAchievementsPerWeek,
            playerIds: Array(selectedPlayerIds)
        )
    }
    
    /// Cancels and returns to tournaments list.
    func cancel() {
        LeagueEngine.setScreen(context: context, screen: .tournaments)
    }
}
