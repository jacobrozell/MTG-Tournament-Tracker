import Testing
import SwiftData
import Foundation
@testable import BudgetLeagueTracker

/// Tests for Tournament model
@Suite("Tournament Model Tests", .serialized)
@MainActor
struct TournamentTests {
    
    @Suite("Initialization")
    @MainActor
    struct InitializationTests {
        
        @Test("Default initialization")
        func defaultInitialization() {
            let tournament = Tournament(name: "Test Tournament")
            
            #expect(tournament.name == "Test Tournament")
            #expect(!tournament.id.isEmpty)
            #expect(tournament.totalWeeks == AppConstants.League.defaultTotalWeeks)
            #expect(tournament.randomAchievementsPerWeek == AppConstants.League.defaultRandomAchievementsPerWeek)
            #expect(tournament.status == .ongoing)
            #expect(tournament.currentWeek == AppConstants.League.defaultCurrentWeek)
            #expect(tournament.currentRound == AppConstants.League.defaultCurrentRound)
            #expect(tournament.achievementsOnThisWeek == AppConstants.League.defaultAchievementsOnThisWeek)
            #expect(tournament.endDate == nil)
        }
        
        @Test("Custom initialization")
        func customInitialization() {
            let tournament = Tournament(
                name: "Custom Tournament",
                totalWeeks: 8,
                randomAchievementsPerWeek: 3,
                status: .completed,
                currentWeek: 5,
                currentRound: 2,
                achievementsOnThisWeek: false
            )
            
            #expect(tournament.name == "Custom Tournament")
            #expect(tournament.totalWeeks == 8)
            #expect(tournament.randomAchievementsPerWeek == 3)
            #expect(tournament.status == .completed)
            #expect(tournament.currentWeek == 5)
            #expect(tournament.currentRound == 2)
            #expect(tournament.achievementsOnThisWeek == false)
        }
    }
    
    @Suite("Status Property")
    @MainActor
    struct StatusTests {
        
        @Test("Status computed property from raw value")
        func statusFromRawValue() {
            let tournament = Tournament(name: "Test")
            
            tournament.statusRaw = "ongoing"
            #expect(tournament.status == .ongoing)
            
            tournament.statusRaw = "completed"
            #expect(tournament.status == .completed)
        }
        
        @Test("Status setter updates raw value")
        func statusSetter() {
            let tournament = Tournament(name: "Test")
            
            tournament.status = .completed
            #expect(tournament.statusRaw == "completed")
            
            tournament.status = .ongoing
            #expect(tournament.statusRaw == "ongoing")
        }
        
        @Test("Invalid raw value defaults to ongoing")
        func invalidRawValueDefaultsToOngoing() {
            let tournament = Tournament(name: "Test")
            tournament.statusRaw = "invalid_status"
            
            #expect(tournament.status == .ongoing)
        }
    }
    
    @Suite("isFinalWeek Computed Property")
    @MainActor
    struct IsFinalWeekTests {
        
        @Test("isFinalWeek returns true when current week equals total weeks")
        func equalsFinalWeek() {
            let tournament = Tournament(name: "Test", totalWeeks: 6)
            tournament.currentWeek = 6
            
            #expect(tournament.isFinalWeek == true)
        }
        
        @Test("isFinalWeek returns true when current week exceeds total weeks")
        func exceedsFinalWeek() {
            let tournament = Tournament(name: "Test", totalWeeks: 6)
            tournament.currentWeek = 7
            
            #expect(tournament.isFinalWeek == true)
        }
        
        @Test("isFinalWeek returns false when before final week")
        func beforeFinalWeek() {
            let tournament = Tournament(name: "Test", totalWeeks: 6)
            tournament.currentWeek = 5
            
            #expect(tournament.isFinalWeek == false)
        }
    }
    
    @Suite("Present Player IDs JSON Encoding/Decoding")
    @MainActor
    struct PresentPlayerIdsTests {
        
        @Test("Set and get present player IDs")
        func setAndGet() {
            let tournament = Tournament(name: "Test")
            let ids = ["player1", "player2", "player3"]
            
            tournament.presentPlayerIds = ids
            
            #expect(tournament.presentPlayerIds == ids)
        }
        
        @Test("Empty array when no data")
        func emptyArrayWhenNoData() {
            let tournament = Tournament(name: "Test")
            
            #expect(tournament.presentPlayerIds.isEmpty)
        }
        
        @Test("Persists through encoding cycle")
        func persistsThroughEncodingCycle() {
            let tournament = Tournament(name: "Test")
            let ids = ["a", "b", "c", "d"]
            
            tournament.presentPlayerIds = ids
            let retrieved = tournament.presentPlayerIds
            
            #expect(retrieved == ids)
        }
    }
    
    @Suite("Weekly Points JSON Encoding/Decoding")
    @MainActor
    struct WeeklyPointsTests {
        
        @Test("Set and get weekly points by player")
        func setAndGet() {
            let tournament = Tournament(name: "Test")
            let points: [String: WeeklyPlayerPoints] = [
                "p1": WeeklyPlayerPoints(placementPoints: 10, achievementPoints: 5),
                "p2": WeeklyPlayerPoints(placementPoints: 8, achievementPoints: 3)
            ]
            
            tournament.weeklyPointsByPlayer = points
            let retrieved = tournament.weeklyPointsByPlayer
            
            #expect(retrieved["p1"]?.placementPoints == 10)
            #expect(retrieved["p1"]?.achievementPoints == 5)
            #expect(retrieved["p2"]?.placementPoints == 8)
            #expect(retrieved["p2"]?.achievementPoints == 3)
        }
        
        @Test("Empty dictionary when no data")
        func emptyWhenNoData() {
            let tournament = Tournament(name: "Test")
            
            #expect(tournament.weeklyPointsByPlayer.isEmpty)
        }
    }
    
    @Suite("Active Achievement IDs JSON Encoding/Decoding")
    @MainActor
    struct ActiveAchievementIdsTests {
        
        @Test("Set and get active achievement IDs")
        func setAndGet() {
            let tournament = Tournament(name: "Test")
            let ids = ["ach1", "ach2", "ach3"]
            
            tournament.activeAchievementIds = ids
            
            #expect(tournament.activeAchievementIds == ids)
        }
        
        @Test("Empty array when no data")
        func emptyWhenNoData() {
            let tournament = Tournament(name: "Test")
            
            #expect(tournament.activeAchievementIds.isEmpty)
        }
    }
    
    @Suite("Pod History Snapshots JSON Encoding/Decoding")
    @MainActor
    struct PodHistorySnapshotsTests {
        
        @Test("Set and get pod history snapshots")
        func setAndGet() {
            let tournament = Tournament(name: "Test")
            let snapshot = PodSnapshot(
                playerIds: ["p1", "p2"],
                placements: ["p1": 1, "p2": 2],
                achievementChecks: [AchievementCheck(playerId: "p1", achievementId: "a1", points: 1)],
                playerDeltas: ["p1": PlayerDelta(placementPoints: 4, achievementPoints: 1, wins: 1, gamesPlayed: 1)],
                weeklyDeltas: ["p1": WeeklyPlayerPoints(placementPoints: 4, achievementPoints: 1)]
            )
            
            tournament.podHistorySnapshots = [snapshot]
            let retrieved = tournament.podHistorySnapshots
            
            #expect(retrieved.count == 1)
            #expect(retrieved.first?.playerIds == ["p1", "p2"])
            #expect(retrieved.first?.placements["p1"] == 1)
        }
        
        @Test("Empty array when no data")
        func emptyWhenNoData() {
            let tournament = Tournament(name: "Test")
            
            #expect(tournament.podHistorySnapshots.isEmpty)
        }
    }
    
    @Suite("Round Placements JSON Encoding/Decoding")
    @MainActor
    struct RoundPlacementsTests {
        
        @Test("Set and get round placements")
        func setAndGet() {
            let tournament = Tournament(name: "Test")
            let placements = ["p1": 1, "p2": 2, "p3": 3, "p4": 4]
            
            tournament.roundPlacements = placements
            
            #expect(tournament.roundPlacements == placements)
        }
        
        @Test("Empty dictionary when no data")
        func emptyWhenNoData() {
            let tournament = Tournament(name: "Test")
            
            #expect(tournament.roundPlacements.isEmpty)
        }
    }
    
    @Suite("Round Achievement Checks JSON Encoding/Decoding")
    @MainActor
    struct RoundAchievementChecksTests {
        
        @Test("Set and get round achievement checks")
        func setAndGet() {
            let tournament = Tournament(name: "Test")
            let checks: Set<String> = ["p1:a1", "p1:a2", "p2:a1"]
            
            tournament.roundAchievementChecks = checks
            
            #expect(tournament.roundAchievementChecks == checks)
        }
        
        @Test("Empty set when no data")
        func emptyWhenNoData() {
            let tournament = Tournament(name: "Test")
            
            #expect(tournament.roundAchievementChecks.isEmpty)
        }
    }
    
    @Suite("SwiftData Persistence")
    @MainActor
    struct PersistenceTests {
        
        @Test("Tournament persists with all properties")
        func persistsWithAllProperties() throws {
            let context = try TestHelpers.cleanContext()
            let tournament = Tournament(
                name: "Persistent Tournament",
                totalWeeks: 8,
                randomAchievementsPerWeek: 3
            )
            tournament.presentPlayerIds = ["p1", "p2"]
            tournament.weeklyPointsByPlayer = ["p1": WeeklyPlayerPoints(placementPoints: 5, achievementPoints: 2)]
            
            context.insert(tournament)
            try context.save()
            
            let fetched = try TestHelpers.fetchAll(Tournament.self, from: context).first!
            #expect(fetched.name == "Persistent Tournament")
            #expect(fetched.totalWeeks == 8)
            #expect(fetched.presentPlayerIds == ["p1", "p2"])
            #expect(fetched.weeklyPointsByPlayer["p1"]?.placementPoints == 5)
        }
    }
}
