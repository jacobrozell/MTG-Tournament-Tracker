import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Tests for GameResult model
@Suite("GameResult Model Tests", .serialized)
@MainActor
struct GameResultTests {
    
    @Suite("Initialization")
    @MainActor
    struct InitializationTests {
        
        @Test("Default initialization")
        func defaultInitialization() {
            let result = GameResult(
                tournamentId: "t1",
                week: 1,
                round: 1,
                playerId: "p1",
                placement: 1,
                placementPoints: 4,
                achievementPoints: 2,
                podId: "pod1"
            )
            
            #expect(!result.id.isEmpty)
            #expect(result.tournamentId == "t1")
            #expect(result.week == 1)
            #expect(result.round == 1)
            #expect(result.playerId == "p1")
            #expect(result.placement == 1)
            #expect(result.placementPoints == 4)
            #expect(result.achievementPoints == 2)
            #expect(result.podId == "pod1")
            #expect(result.timestamp != nil)
        }
        
        @Test("Initialization with achievement IDs")
        func initWithAchievementIds() {
            let achievementIds = ["ach1", "ach2", "ach3"]
            let result = GameResult(
                tournamentId: "t1",
                week: 1,
                round: 1,
                playerId: "p1",
                placement: 1,
                placementPoints: 4,
                achievementPoints: 3,
                achievementIds: achievementIds,
                podId: "pod1"
            )
            
            #expect(result.achievementIds == achievementIds)
        }
        
        @Test("Custom ID initialization")
        func customIdInitialization() {
            let customId = "custom-result-id"
            let result = GameResult(
                id: customId,
                tournamentId: "t1",
                week: 1,
                round: 1,
                playerId: "p1",
                placement: 1,
                placementPoints: 4,
                achievementPoints: 0,
                podId: "pod1"
            )
            
            #expect(result.id == customId)
        }
    }
    
    @Suite("totalPoints Computed Property")
    @MainActor
    struct TotalPointsTests {
        
        @Test("totalPoints sums placement and achievement", arguments: [
            (placement: 4, achievement: 0, expected: 4),
            (placement: 3, achievement: 2, expected: 5),
            (placement: 1, achievement: 5, expected: 6),
            (placement: 0, achievement: 0, expected: 0)
        ])
        func totalPointsCalculation(placement: Int, achievement: Int, expected: Int) {
            let result = GameResult(
                tournamentId: "t1",
                week: 1,
                round: 1,
                playerId: "p1",
                placement: 1,
                placementPoints: placement,
                achievementPoints: achievement,
                podId: "pod1"
            )
            
            #expect(result.totalPoints == expected)
        }
    }
    
    @Suite("isWin Computed Property")
    @MainActor
    struct IsWinTests {
        
        @Test("isWin returns true only for first place", arguments: [
            (placement: 1, expected: true),
            (placement: 2, expected: false),
            (placement: 3, expected: false),
            (placement: 4, expected: false)
        ])
        func isWinCalculation(placement: Int, expected: Bool) {
            let result = GameResult(
                tournamentId: "t1",
                week: 1,
                round: 1,
                playerId: "p1",
                placement: placement,
                placementPoints: AppConstants.Scoring.placementPoints(forPlace: placement),
                achievementPoints: 0,
                podId: "pod1"
            )
            
            #expect(result.isWin == expected)
        }
    }
    
    @Suite("achievementIds JSON Encoding/Decoding")
    @MainActor
    struct AchievementIdsTests {
        
        @Test("Set and get achievement IDs")
        func setAndGet() {
            let result = GameResult(
                tournamentId: "t1",
                week: 1,
                round: 1,
                playerId: "p1",
                placement: 1,
                placementPoints: 4,
                achievementPoints: 2,
                podId: "pod1"
            )
            
            result.achievementIds = ["a1", "a2", "a3"]
            
            #expect(result.achievementIds == ["a1", "a2", "a3"])
        }
        
        @Test("Empty array when no data")
        func emptyWhenNoData() {
            let result = GameResult(
                tournamentId: "t1",
                week: 1,
                round: 1,
                playerId: "p1",
                placement: 1,
                placementPoints: 4,
                achievementPoints: 0,
                podId: "pod1"
            )
            result.achievementIdsData = nil
            
            #expect(result.achievementIds.isEmpty)
        }
        
        @Test("Preserves order of achievement IDs")
        func preservesOrder() {
            let result = GameResult(
                tournamentId: "t1",
                week: 1,
                round: 1,
                playerId: "p1",
                placement: 1,
                placementPoints: 4,
                achievementPoints: 0,
                achievementIds: ["first", "second", "third"],
                podId: "pod1"
            )
            
            #expect(result.achievementIds[0] == "first")
            #expect(result.achievementIds[1] == "second")
            #expect(result.achievementIds[2] == "third")
        }
    }
    
    @Suite("SwiftData Persistence")
    @MainActor
    struct PersistenceTests {
        
        @Test("GameResult persists to context")
        func persistsToContext() throws {
            let context = try TestHelpers.cleanContext()
            let result = GameResult(
                tournamentId: "tournament-1",
                week: 2,
                round: 3,
                playerId: "player-1",
                placement: 2,
                placementPoints: 3,
                achievementPoints: 1,
                achievementIds: ["ach-1"],
                podId: "pod-1"
            )
            
            context.insert(result)
            try context.save()
            
            let fetched = try TestHelpers.fetchAll(GameResult.self, from: context).first!
            #expect(fetched.tournamentId == "tournament-1")
            #expect(fetched.week == 2)
            #expect(fetched.round == 3)
            #expect(fetched.playerId == "player-1")
            #expect(fetched.placement == 2)
            #expect(fetched.achievementIds == ["ach-1"])
        }
        
        @Test("Multiple results can share same podId")
        func sharedPodId() throws {
            let context = try TestHelpers.cleanContext()
            let sharedPodId = UUID().uuidString
            
            let results = [
                GameResult(tournamentId: "t1", week: 1, round: 1, playerId: "p1", placement: 1, placementPoints: 4, achievementPoints: 0, podId: sharedPodId),
                GameResult(tournamentId: "t1", week: 1, round: 1, playerId: "p2", placement: 2, placementPoints: 3, achievementPoints: 0, podId: sharedPodId),
                GameResult(tournamentId: "t1", week: 1, round: 1, playerId: "p3", placement: 3, placementPoints: 2, achievementPoints: 0, podId: sharedPodId),
                GameResult(tournamentId: "t1", week: 1, round: 1, playerId: "p4", placement: 4, placementPoints: 1, achievementPoints: 0, podId: sharedPodId)
            ]
            
            results.forEach { context.insert($0) }
            try context.save()
            
            let fetched = try TestHelpers.fetchAll(GameResult.self, from: context)
            let podResults = fetched.filter { $0.podId == sharedPodId }
            
            #expect(podResults.count == 4)
        }
    }
}
