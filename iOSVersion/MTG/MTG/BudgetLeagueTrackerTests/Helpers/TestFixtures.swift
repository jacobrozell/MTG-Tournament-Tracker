import Foundation
import SwiftData
@testable import BudgetLeagueTracker

/// Factory methods for creating test data
@MainActor
enum TestFixtures {
    
    // MARK: - Player Fixtures
    
    /// Creates a test player with customizable properties
    /// - Parameters:
    ///   - name: Player name (default: "Test Player")
    ///   - placementPoints: Total placement points (default: 0)
    ///   - achievementPoints: Total achievement points (default: 0)
    ///   - wins: Total wins (default: 0)
    ///   - gamesPlayed: Total games played (default: 0)
    ///   - tournamentsPlayed: Total tournaments participated in (default: 0)
    /// - Returns: A configured Player instance
    static func player(
        name: String = "Test Player",
        placementPoints: Int = 0,
        achievementPoints: Int = 0,
        wins: Int = 0,
        gamesPlayed: Int = 0,
        tournamentsPlayed: Int = 0
    ) -> Player {
        let player = Player(name: name)
        player.placementPoints = placementPoints
        player.achievementPoints = achievementPoints
        player.wins = wins
        player.gamesPlayed = gamesPlayed
        player.tournamentsPlayed = tournamentsPlayed
        return player
    }
    
    /// Creates multiple players with the given names
    /// - Parameter names: Variable list of player names
    /// - Returns: Array of Player instances
    static func players(_ names: String...) -> [Player] {
        names.map { Player(name: $0) }
    }
    
    /// Creates a standard pod of 4 players
    /// - Returns: Array of 4 Player instances
    static func standardPod() -> [Player] {
        players("Alice", "Bob", "Charlie", "Diana")
    }
    
    /// Creates a player with existing stats (for testing cumulative updates)
    /// - Returns: A Player with non-zero stats
    static func playerWithStats() -> Player {
        player(
            name: "Experienced Player",
            placementPoints: 20,
            achievementPoints: 5,
            wins: 3,
            gamesPlayed: 8,
            tournamentsPlayed: 2
        )
    }
    
    // MARK: - Achievement Fixtures
    
    /// Creates a test achievement with customizable properties
    /// - Parameters:
    ///   - name: Achievement name (default: "Test Achievement")
    ///   - points: Points value (default: 1)
    ///   - alwaysOn: Whether always active (default: false)
    /// - Returns: A configured Achievement instance
    static func achievement(
        name: String = "Test Achievement",
        points: Int = 1,
        alwaysOn: Bool = false
    ) -> Achievement {
        Achievement(name: name, points: points, alwaysOn: alwaysOn)
    }
    
    /// Creates the default "First Blood" achievement
    /// - Returns: The default seeded Achievement
    static func defaultAchievement() -> Achievement {
        Achievement(
            name: AppConstants.DefaultAchievement.name,
            points: AppConstants.DefaultAchievement.points,
            alwaysOn: AppConstants.DefaultAchievement.alwaysOn
        )
    }
    
    /// Creates multiple achievements with varying properties
    /// - Returns: Array of Achievement instances for testing
    static func sampleAchievements() -> [Achievement] {
        [
            achievement(name: "First Blood", points: 1, alwaysOn: true),
            achievement(name: "Combo Master", points: 2, alwaysOn: false),
            achievement(name: "Control Freak", points: 1, alwaysOn: false),
            achievement(name: "Aggro King", points: 1, alwaysOn: false),
            achievement(name: "Mill Victory", points: 3, alwaysOn: false)
        ]
    }
    
    /// Creates achievements split between alwaysOn and random
    /// - Parameters:
    ///   - alwaysOnCount: Number of alwaysOn achievements
    ///   - randomCount: Number of random achievements
    /// - Returns: Array of Achievement instances
    static func achievements(alwaysOnCount: Int, randomCount: Int) -> [Achievement] {
        var achievements: [Achievement] = []
        
        for i in 0..<alwaysOnCount {
            achievements.append(achievement(name: "Always On \(i + 1)", points: 1, alwaysOn: true))
        }
        
        for i in 0..<randomCount {
            achievements.append(achievement(name: "Random \(i + 1)", points: 1, alwaysOn: false))
        }
        
        return achievements
    }
    
    // MARK: - Tournament Fixtures
    
    /// Creates a test tournament with customizable properties
    /// - Parameters:
    ///   - name: Tournament name (default: "Test Tournament")
    ///   - totalWeeks: Number of weeks (default: 6)
    ///   - randomAchievementsPerWeek: Random achievements per week (default: 2)
    ///   - currentWeek: Current week (default: 1)
    ///   - currentRound: Current round (default: 1)
    /// - Returns: A configured Tournament instance
    static func tournament(
        name: String = "Test Tournament",
        totalWeeks: Int = 6,
        randomAchievementsPerWeek: Int = 2,
        currentWeek: Int = 1,
        currentRound: Int = 1
    ) -> Tournament {
        let tournament = Tournament(
            name: name,
            totalWeeks: totalWeeks,
            randomAchievementsPerWeek: randomAchievementsPerWeek
        )
        tournament.currentWeek = currentWeek
        tournament.currentRound = currentRound
        return tournament
    }
    
    /// Creates a tournament at the final week
    /// - Returns: A Tournament configured for the final week
    static func finalWeekTournament() -> Tournament {
        let t = tournament(totalWeeks: 6)
        t.currentWeek = 6
        t.currentRound = 3
        return t
    }
    
    /// Creates a completed tournament
    /// - Returns: A completed Tournament
    static func completedTournament() -> Tournament {
        let t = tournament(name: "Completed Tournament")
        t.statusRaw = TournamentStatus.completed.rawValue
        t.endDate = Date()
        return t
    }
    
    // MARK: - GameResult Fixtures
    
    /// Creates a test game result
    /// - Parameters:
    ///   - tournamentId: Tournament ID
    ///   - week: Week number (default: 1)
    ///   - round: Round number (default: 1)
    ///   - playerId: Player ID
    ///   - placement: Placement (1-4, default: 1)
    ///   - achievementPoints: Achievement points (default: 0)
    ///   - podId: Pod ID (default: new UUID)
    /// - Returns: A configured GameResult instance
    static func gameResult(
        tournamentId: String,
        week: Int = 1,
        round: Int = 1,
        playerId: String,
        placement: Int = 1,
        achievementPoints: Int = 0,
        podId: String = UUID().uuidString
    ) -> GameResult {
        GameResult(
            tournamentId: tournamentId,
            week: week,
            round: round,
            playerId: playerId,
            placement: placement,
            placementPoints: AppConstants.Scoring.placementPoints(forPlace: placement),
            achievementPoints: achievementPoints,
            podId: podId
        )
    }
    
    /// Creates game results for a complete pod (4 players)
    /// - Parameters:
    ///   - tournamentId: Tournament ID
    ///   - week: Week number
    ///   - round: Round number
    ///   - playerIds: Array of 4 player IDs (in placement order: 1st, 2nd, 3rd, 4th)
    /// - Returns: Array of 4 GameResult instances
    static func podGameResults(
        tournamentId: String,
        week: Int = 1,
        round: Int = 1,
        playerIds: [String]
    ) -> [GameResult] {
        let podId = UUID().uuidString
        return playerIds.enumerated().map { index, playerId in
            gameResult(
                tournamentId: tournamentId,
                week: week,
                round: round,
                playerId: playerId,
                placement: index + 1,
                podId: podId
            )
        }
    }
    
    // MARK: - LeagueState Fixtures
    
    /// Creates a default LeagueState
    /// - Returns: A LeagueState with default values
    static func leagueState() -> LeagueState {
        LeagueState()
    }
    
    /// Creates a LeagueState with an active tournament
    /// - Parameter tournamentId: The active tournament ID
    /// - Returns: A LeagueState configured with an active tournament
    static func leagueStateWithActiveTournament(tournamentId: String) -> LeagueState {
        let state = LeagueState()
        state.activeTournamentId = tournamentId
        state.currentScreen = Screen.pods.rawValue
        return state
    }
    
    // MARK: - Weekly Points Fixtures
    
    /// Creates weekly player points
    /// - Parameters:
    ///   - placementPoints: Placement points (default: 0)
    ///   - achievementPoints: Achievement points (default: 0)
    /// - Returns: A WeeklyPlayerPoints instance
    static func weeklyPoints(
        placementPoints: Int = 0,
        achievementPoints: Int = 0
    ) -> WeeklyPlayerPoints {
        WeeklyPlayerPoints(placementPoints: placementPoints, achievementPoints: achievementPoints)
    }
    
    // MARK: - Placement Data Fixtures
    
    /// Creates a standard placement dictionary for a 4-player pod
    /// - Parameter playerIds: Array of player IDs (in placement order)
    /// - Returns: Dictionary mapping player IDs to placements
    static func placements(for playerIds: [String]) -> [String: Int] {
        var result: [String: Int] = [:]
        for (index, playerId) in playerIds.enumerated() {
            result[playerId] = index + 1
        }
        return result
    }
    
    /// Creates achievement checks for specified players and achievements
    /// - Parameters:
    ///   - playerIds: Player IDs who earned achievements
    ///   - achievementIds: Achievement IDs earned
    /// - Returns: Set of composite keys "playerId:achievementId"
    static func achievementChecks(playerIds: [String], achievementIds: [String]) -> Set<String> {
        var checks: Set<String> = []
        for playerId in playerIds {
            for achievementId in achievementIds {
                checks.insert("\(playerId):\(achievementId)")
            }
        }
        return checks
    }
}

// MARK: - Context-Aware Fixtures

extension TestFixtures {
    
    /// Inserts standard test players into a context
    /// - Parameter context: The ModelContext to insert into
    /// - Returns: Array of inserted Player instances
    @discardableResult
    static func insertStandardPlayers(into context: ModelContext) -> [Player] {
        let players = standardPod()
        players.forEach { context.insert($0) }
        return players
    }
    
    /// Inserts sample achievements into a context
    /// - Parameter context: The ModelContext to insert into
    /// - Returns: Array of inserted Achievement instances
    @discardableResult
    static func insertSampleAchievements(into context: ModelContext) -> [Achievement] {
        let achievements = sampleAchievements()
        achievements.forEach { context.insert($0) }
        return achievements
    }
    
    /// Sets up a complete test scenario with tournament, players, and achievements
    /// - Parameter context: The ModelContext to set up
    /// - Returns: Tuple containing the created entities
    @discardableResult
    static func setupCompleteTournamentScenario(
        in context: ModelContext
    ) throws -> (tournament: Tournament, players: [Player], achievements: [Achievement], leagueState: LeagueState) {
        let players = insertStandardPlayers(into: context)
        let achievements = insertSampleAchievements(into: context)
        
        let tournament = tournament()
        tournament.presentPlayerIds = players.map { $0.id }
        
        var weeklyPoints: [String: WeeklyPlayerPoints] = [:]
        for player in players {
            weeklyPoints[player.id] = WeeklyPlayerPoints(placementPoints: 0, achievementPoints: 0)
        }
        tournament.weeklyPointsByPlayer = weeklyPoints
        tournament.activeAchievementIds = achievements.filter { $0.alwaysOn }.map { $0.id }
        
        context.insert(tournament)
        
        let state = LeagueState()
        state.activeTournamentId = tournament.id
        state.currentScreen = Screen.pods.rawValue
        context.insert(state)
        
        try context.save()
        
        return (tournament, players, achievements, state)
    }
}
