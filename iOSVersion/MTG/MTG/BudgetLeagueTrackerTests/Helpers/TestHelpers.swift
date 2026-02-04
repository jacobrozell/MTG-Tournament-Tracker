import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Holds the container and context together to ensure proper lifetime management
@MainActor
final class TestModelContext {
    let container: ModelContainer
    let modelContext: ModelContext
    
    init(bootstrapped: Bool = true) throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        self.container = try ModelContainer(
            for: Player.self, Achievement.self, LeagueState.self,
                Tournament.self, GameResult.self,
            configurations: config
        )
        self.modelContext = container.mainContext
        
        if bootstrapped {
            // Bootstrap LeagueState singleton
            let state = LeagueState()
            modelContext.insert(state)
            
            // Bootstrap default achievement
            let achievement = Achievement(
                name: AppConstants.DefaultAchievement.name,
                points: AppConstants.DefaultAchievement.points,
                alwaysOn: AppConstants.DefaultAchievement.alwaysOn
            )
            modelContext.insert(achievement)
            
            try modelContext.save()
        }
    }
}

/// Test helpers for creating isolated test environments
@MainActor
enum TestHelpers {
    
    /// Holds the current test's model context wrapper to prevent deallocation
    /// Tests should assign this before using the context
    nonisolated(unsafe) static var currentTestContext: TestModelContext?
    
    /// Creates an in-memory ModelContainer for testing
    /// - Returns: A ModelContainer configured for in-memory storage
    static func inMemoryContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Player.self, Achievement.self, LeagueState.self,
                Tournament.self, GameResult.self,
            configurations: config
        )
    }
    
    /// Creates a test context with bootstrapped state (LeagueState + default achievement)
    /// - Returns: A ModelContext ready for testing with initial data
    static func bootstrappedContext() throws -> ModelContext {
        let testContext = try TestModelContext(bootstrapped: true)
        currentTestContext = testContext
        return testContext.modelContext
    }
    
    /// Creates a clean context without any bootstrapped data
    /// - Returns: An empty ModelContext for testing
    static func cleanContext() throws -> ModelContext {
        let testContext = try TestModelContext(bootstrapped: false)
        currentTestContext = testContext
        return testContext.modelContext
    }
    
    /// Creates a context with a tournament in progress at a specific state
    /// - Parameters:
    ///   - week: Current week number
    ///   - round: Current round number
    ///   - playerNames: Names of players to create
    ///   - presentPlayerNames: Names of players who are present (subset of playerNames)
    /// - Returns: A context with tournament state set up
    static func contextWithTournament(
        week: Int = 1,
        round: Int = 1,
        playerNames: [String] = ["Player 1", "Player 2", "Player 3", "Player 4"],
        presentPlayerNames: [String]? = nil
    ) throws -> ModelContext {
        let context = try bootstrappedContext()
        
        // Create players
        var players: [Player] = []
        for name in playerNames {
            let player = Player(name: name)
            context.insert(player)
            players.append(player)
        }
        
        // Create tournament
        let tournament = Tournament(
            name: "Test Tournament",
            totalWeeks: 6,
            randomAchievementsPerWeek: 2
        )
        tournament.currentWeek = week
        tournament.currentRound = round
        
        // Set present players
        let presentNames = presentPlayerNames ?? playerNames
        let presentIds = players.filter { presentNames.contains($0.name) }.map { $0.id }
        tournament.presentPlayerIds = presentIds
        
        // Initialize weekly points for present players
        var weeklyPoints: [String: WeeklyPlayerPoints] = [:]
        for id in presentIds {
            weeklyPoints[id] = WeeklyPlayerPoints(placementPoints: 0, achievementPoints: 0)
        }
        tournament.weeklyPointsByPlayer = weeklyPoints
        
        context.insert(tournament)
        
        // Update LeagueState
        let descriptor = FetchDescriptor<LeagueState>()
        if let state = try context.fetch(descriptor).first {
            state.activeTournamentId = tournament.id
            state.currentScreen = Screen.pods.rawValue
        }
        
        try context.save()
        return context
    }
    
    /// Fetches all entities of a given type from the context
    /// - Parameters:
    ///   - type: The model type to fetch
    ///   - context: The ModelContext to fetch from
    /// - Returns: Array of all entities of the given type
    static func fetchAll<T: PersistentModel>(_ type: T.Type, from context: ModelContext) throws -> [T] {
        let descriptor = FetchDescriptor<T>()
        return try context.fetch(descriptor)
    }
    
    /// Fetches the LeagueState singleton from the context
    /// - Parameter context: The ModelContext to fetch from
    /// - Returns: The LeagueState, or nil if not found
    static func fetchLeagueState(from context: ModelContext) throws -> LeagueState? {
        let descriptor = FetchDescriptor<LeagueState>()
        return try context.fetch(descriptor).first
    }
    
    /// Fetches the active tournament from the context
    /// - Parameter context: The ModelContext to fetch from
    /// - Returns: The active Tournament, or nil if none
    static func fetchActiveTournament(from context: ModelContext) throws -> Tournament? {
        guard let state = try fetchLeagueState(from: context),
              let tournamentId = state.activeTournamentId else {
            return nil
        }
        
        let descriptor = FetchDescriptor<Tournament>(
            predicate: #Predicate { $0.id == tournamentId }
        )
        return try context.fetch(descriptor).first
    }
}

// MARK: - Assertion Helpers

extension TestHelpers {
    
    /// Asserts that two players have equal stats
    static func assertPlayerStatsEqual(
        _ player: Player,
        placementPoints: Int,
        achievementPoints: Int,
        wins: Int,
        gamesPlayed: Int,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(player.placementPoints == placementPoints, sourceLocation: sourceLocation)
        #expect(player.achievementPoints == achievementPoints, sourceLocation: sourceLocation)
        #expect(player.wins == wins, sourceLocation: sourceLocation)
        #expect(player.gamesPlayed == gamesPlayed, sourceLocation: sourceLocation)
    }
    
    /// Asserts that weekly points match expected values
    static func assertWeeklyPointsEqual(
        _ points: WeeklyPlayerPoints?,
        placementPoints: Int,
        achievementPoints: Int,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(points != nil, sourceLocation: sourceLocation)
        #expect(points?.placementPoints == placementPoints, sourceLocation: sourceLocation)
        #expect(points?.achievementPoints == achievementPoints, sourceLocation: sourceLocation)
    }
}
