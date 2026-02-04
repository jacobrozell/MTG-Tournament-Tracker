import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Tests for LeagueState model
@Suite("LeagueState Model Tests", .serialized)
@MainActor
struct LeagueStateTests {
    
    @Suite("Initialization")
    @MainActor
    struct InitializationTests {
        
        @Test("Default initialization")
        func defaultInitialization() {
            let state = LeagueState()
            
            #expect(state.activeTournamentId == nil)
            #expect(state.currentScreen == Screen.tournaments.rawValue)
        }
        
        @Test("Custom initialization")
        func customInitialization() {
            let state = LeagueState(
                activeTournamentId: "tournament-123",
                currentScreen: Screen.pods.rawValue
            )
            
            #expect(state.activeTournamentId == "tournament-123")
            #expect(state.currentScreen == Screen.pods.rawValue)
        }
    }
    
    @Suite("Screen Computed Property")
    @MainActor
    struct ScreenTests {
        
        @Test("Screen getter from currentScreen string")
        func screenGetter() {
            let state = LeagueState()
            
            state.currentScreen = "tournaments"
            #expect(state.screen == .tournaments)
            
            state.currentScreen = "pods"
            #expect(state.screen == .pods)
            
            state.currentScreen = "attendance"
            #expect(state.screen == .attendance)
            
            state.currentScreen = "tournamentDetail"
            #expect(state.screen == .tournamentDetail)
        }
        
        @Test("Screen setter updates currentScreen string")
        func screenSetter() {
            let state = LeagueState()
            
            state.screen = .pods
            #expect(state.currentScreen == "pods")
            
            state.screen = .attendance
            #expect(state.currentScreen == "attendance")
            
            state.screen = .tournamentStandings
            #expect(state.currentScreen == "tournamentStandings")
            
            state.screen = .tournamentDetail
            #expect(state.currentScreen == "tournamentDetail")
        }
        
        @Test("Invalid screen value defaults to tournaments")
        func invalidScreenDefaultsToTournaments() {
            let state = LeagueState()
            state.currentScreen = "invalid_screen"
            
            #expect(state.screen == .tournaments)
        }
    }
    
    @Suite("hasActiveTournament Computed Property")
    @MainActor
    struct HasActiveTournamentTests {
        
        @Test("Returns true when tournament ID is set")
        func returnsTrueWhenSet() {
            let state = LeagueState(activeTournamentId: "some-id")
            
            #expect(state.hasActiveTournament == true)
        }
        
        @Test("Returns false when tournament ID is nil")
        func returnsFalseWhenNil() {
            let state = LeagueState(activeTournamentId: nil)
            
            #expect(state.hasActiveTournament == false)
        }
    }
    
    @Suite("Singleton Behavior")
    @MainActor
    struct SingletonTests {
        
        @Test("Only one LeagueState should exist per context")
        func singletonPattern() throws {
            let context = try TestHelpers.bootstrappedContext()
            
            let states = try TestHelpers.fetchAll(LeagueState.self, from: context)
            
            #expect(states.count == 1)
        }
    }
    
    @Suite("SwiftData Persistence")
    @MainActor
    struct PersistenceTests {
        
        @Test("LeagueState persists to context")
        func persistsToContext() throws {
            let context = try TestHelpers.cleanContext()
            let state = LeagueState(
                activeTournamentId: "test-tournament",
                currentScreen: Screen.pods.rawValue
            )
            
            context.insert(state)
            try context.save()
            
            let fetched = try TestHelpers.fetchAll(LeagueState.self, from: context).first!
            #expect(fetched.activeTournamentId == "test-tournament")
            #expect(fetched.screen == .pods)
        }
        
        @Test("LeagueState updates persist")
        func updatesPersist() throws {
            let context = try TestHelpers.bootstrappedContext()
            let state = try TestHelpers.fetchLeagueState(from: context)!
            
            state.activeTournamentId = "new-tournament"
            state.screen = .attendance
            try context.save()
            
            let fetched = try TestHelpers.fetchLeagueState(from: context)!
            #expect(fetched.activeTournamentId == "new-tournament")
            #expect(fetched.screen == .attendance)
        }
    }
}

/// Tests for supporting types in LeagueState
@Suite("LeagueState Supporting Types Tests")
@MainActor
struct LeagueStateSupportingTypesTests {
    
    @Suite("WeeklyPlayerPoints")
    @MainActor
    struct WeeklyPlayerPointsTests {
        
        @Test("Default initialization")
        func defaultInit() {
            let points = WeeklyPlayerPoints()
            
            #expect(points.placementPoints == 0)
            #expect(points.achievementPoints == 0)
        }
        
        @Test("Custom initialization")
        func customInit() {
            let points = WeeklyPlayerPoints(placementPoints: 10, achievementPoints: 5)
            
            #expect(points.placementPoints == 10)
            #expect(points.achievementPoints == 5)
        }
        
        @Test("Total computed property")
        func totalComputed() {
            let points = WeeklyPlayerPoints(placementPoints: 8, achievementPoints: 3)
            
            #expect(points.total == 11)
        }
        
        @Test("Equatable conformance")
        func equatable() {
            let points1 = WeeklyPlayerPoints(placementPoints: 5, achievementPoints: 2)
            let points2 = WeeklyPlayerPoints(placementPoints: 5, achievementPoints: 2)
            let points3 = WeeklyPlayerPoints(placementPoints: 5, achievementPoints: 3)
            
            #expect(points1 == points2)
            #expect(points1 != points3)
        }
        
        @Test("Codable conformance")
        func codable() throws {
            let original = WeeklyPlayerPoints(placementPoints: 7, achievementPoints: 4)
            
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(WeeklyPlayerPoints.self, from: encoded)
            
            #expect(decoded == original)
        }
    }
    
    @Suite("PodSnapshot")
    @MainActor
    struct PodSnapshotTests {
        
        @Test("Initialization and properties")
        func initialization() {
            let snapshot = PodSnapshot(
                playerIds: ["p1", "p2", "p3", "p4"],
                placements: ["p1": 1, "p2": 2, "p3": 3, "p4": 4],
                achievementChecks: [AchievementCheck(playerId: "p1", achievementId: "a1", points: 1)],
                playerDeltas: ["p1": PlayerDelta(placementPoints: 4, achievementPoints: 1, wins: 1, gamesPlayed: 1)],
                weeklyDeltas: ["p1": WeeklyPlayerPoints(placementPoints: 4, achievementPoints: 1)]
            )
            
            #expect(snapshot.playerIds.count == 4)
            #expect(snapshot.placements["p1"] == 1)
            #expect(snapshot.achievementChecks.count == 1)
            #expect(snapshot.playerDeltas["p1"]?.wins == 1)
            #expect(snapshot.weeklyDeltas["p1"]?.total == 5)
        }
        
        @Test("Codable conformance")
        func codable() throws {
            let original = PodSnapshot(
                playerIds: ["p1"],
                placements: ["p1": 1],
                achievementChecks: [],
                playerDeltas: [:],
                weeklyDeltas: [:]
            )
            
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(PodSnapshot.self, from: encoded)
            
            #expect(decoded == original)
        }
    }
    
    @Suite("AchievementCheck")
    @MainActor
    struct AchievementCheckTests {
        
        @Test("Initialization")
        func initialization() {
            let check = AchievementCheck(playerId: "player1", achievementId: "ach1", points: 2)
            
            #expect(check.playerId == "player1")
            #expect(check.achievementId == "ach1")
            #expect(check.points == 2)
        }
        
        @Test("Codable conformance")
        func codable() throws {
            let original = AchievementCheck(playerId: "p", achievementId: "a", points: 5)
            
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(AchievementCheck.self, from: encoded)
            
            #expect(decoded == original)
        }
    }
    
    @Suite("PlayerDelta")
    @MainActor
    struct PlayerDeltaTests {
        
        @Test("Initialization")
        func initialization() {
            let delta = PlayerDelta(
                placementPoints: 4,
                achievementPoints: 2,
                wins: 1,
                gamesPlayed: 1
            )
            
            #expect(delta.placementPoints == 4)
            #expect(delta.achievementPoints == 2)
            #expect(delta.wins == 1)
            #expect(delta.gamesPlayed == 1)
        }
        
        @Test("Codable conformance")
        func codable() throws {
            let original = PlayerDelta(placementPoints: 3, achievementPoints: 1, wins: 0, gamesPlayed: 1)
            
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(PlayerDelta.self, from: encoded)
            
            #expect(decoded == original)
        }
    }
}
