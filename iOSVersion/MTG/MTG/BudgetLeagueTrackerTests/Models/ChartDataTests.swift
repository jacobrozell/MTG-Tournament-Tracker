import Testing
import Foundation
@testable import BudgetLeagueTracker

/// Tests for ChartData structs — pure data types, no SwiftData
@Suite("ChartData Tests", .serialized)
@MainActor
struct ChartDataTests {

    @Suite("PlayerPointsData")
    @MainActor
    struct PlayerPointsDataTests {

        @Test("Init from player")
        func initFromPlayer() {
            let player = TestFixtures.player(
                name: "Alice",
                placementPoints: 25,
                achievementPoints: 10
            )
            let data = PlayerPointsData(player: player)

            #expect(data.id == player.id)
            #expect(data.name == "Alice")
            #expect(data.placementPoints == 25)
            #expect(data.achievementPoints == 10)
        }

        @Test("totalPoints computed property")
        func totalPoints() {
            let data = PlayerPointsData(
                name: "Test",
                placementPoints: 15,
                achievementPoints: 5
            )

            #expect(data.totalPoints == 20)
        }
    }

    @Suite("AchievementEarnData")
    @MainActor
    struct AchievementEarnDataTests {

        @Test("Init from achievement and timesEarned")
        func initFromAchievement() {
            let achievement = TestFixtures.achievement(name: "First Blood", points: 2)
            let data = AchievementEarnData(achievement: achievement, timesEarned: 5)

            #expect(data.id == achievement.id)
            #expect(data.achievementName == "First Blood")
            #expect(data.timesEarned == 5)
            #expect(data.points == 2)
        }
    }

    @Suite("PlacementData")
    struct PlacementDataTests {

        @Test("Init and label for 1st through 4th")
        func labelForPlacements() {
            #expect(PlacementData(placement: 1, count: 10).label == "1st")
            #expect(PlacementData(placement: 2, count: 5).label == "2nd")
            #expect(PlacementData(placement: 3, count: 3).label == "3rd")
            #expect(PlacementData(placement: 4, count: 1).label == "4th")
        }

        @Test("Label for default case")
        func labelForDefault() {
            #expect(PlacementData(placement: 5, count: 0).label == "5th")
        }

        @Test("from distribution produces correct counts for keys 1-4")
        func fromDistribution() {
            let distribution: [Int: Int] = [1: 5, 2: 3, 3: 2, 4: 1]
            let result = PlacementData.from(distribution: distribution)

            #expect(result.count == 4)
            #expect(result.first { $0.placement == 1 }?.count == 5)
            #expect(result.first { $0.placement == 2 }?.count == 3)
            #expect(result.first { $0.placement == 3 }?.count == 2)
            #expect(result.first { $0.placement == 4 }?.count == 1)
        }

        @Test("from distribution uses 0 for missing keys")
        func fromDistributionMissingKeys() {
            let distribution: [Int: Int] = [1: 1]
            let result = PlacementData.from(distribution: distribution)

            #expect(result.count == 4)
            #expect(result.first { $0.placement == 1 }?.count == 1)
            #expect(result.first { $0.placement == 2 }?.count == 0)
            #expect(result.first { $0.placement == 3 }?.count == 0)
            #expect(result.first { $0.placement == 4 }?.count == 0)
        }
    }

    @Suite("PerformanceTrendData")
    struct PerformanceTrendDataTests {

        @Test("Init and property values")
        func initAndProperties() {
            let data = PerformanceTrendData(
                playerName: "Bob",
                week: 2,
                cumulativePoints: 12,
                placementPoints: 8,
                achievementPoints: 4
            )

            #expect(!data.id.isEmpty)
            #expect(data.playerName == "Bob")
            #expect(data.week == 2)
            #expect(data.cumulativePoints == 12)
            #expect(data.placementPoints == 8)
            #expect(data.achievementPoints == 4)
        }
    }

    @Suite("PointsBreakdownData")
    struct PointsBreakdownDataTests {

        @Test("from placementPoints achievementPoints returns two items")
        func fromPlacementAndAchievement() {
            let result = PointsBreakdownData.from(placementPoints: 30, achievementPoints: 10)

            #expect(result.count == 2)
            let placement = result.first { $0.id == "placement" }
            let achievement = result.first { $0.id == "achievement" }
            #expect(placement?.category == "Placement")
            #expect(placement?.points == 30)
            #expect(achievement?.category == "Achievement")
            #expect(achievement?.points == 10)
        }
    }

    @Suite("WinsComparisonData")
    @MainActor
    struct WinsComparisonDataTests {

        @Test("Init from player")
        func initFromPlayer() {
            let player = TestFixtures.player(name: "Charlie", wins: 3, gamesPlayed: 8)
            let data = WinsComparisonData(player: player)

            #expect(data.id == player.id)
            #expect(data.playerName == "Charlie")
            #expect(data.wins == 3)
            #expect(data.gamesPlayed == 8)
        }

        @Test("winRate returns 0 when gamesPlayed 0")
        func winRateZeroWhenNoGames() {
            let data = WinsComparisonData(playerName: "D", wins: 0, gamesPlayed: 0)

            #expect(data.winRate == 0)
        }

        @Test("winRate returns correct ratio")
        func winRateCorrectRatio() {
            let data = WinsComparisonData(playerName: "E", wins: 2, gamesPlayed: 4)

            #expect(abs(data.winRate - 0.5) < 0.001)
        }
    }

    @Suite("AchievementStatsSummary")
    struct AchievementStatsSummaryTests {

        @Test("Init and all properties")
        func initAndProperties() {
            let summary = AchievementStatsSummary(
                totalEarned: 50,
                mostPopularName: "First Blood",
                mostPopularCount: 20,
                rarestName: "Mill Victory",
                rarestCount: 1,
                uniqueAchievementsEarned: 5
            )

            #expect(summary.totalEarned == 50)
            #expect(summary.mostPopularName == "First Blood")
            #expect(summary.mostPopularCount == 20)
            #expect(summary.rarestName == "Mill Victory")
            #expect(summary.rarestCount == 1)
            #expect(summary.uniqueAchievementsEarned == 5)
        }

        @Test("Default init")
        func defaultInit() {
            let summary = AchievementStatsSummary()

            #expect(summary.totalEarned == 0)
            #expect(summary.mostPopularName == nil)
            #expect(summary.mostPopularCount == 0)
            #expect(summary.rarestName == nil)
            #expect(summary.rarestCount == 0)
            #expect(summary.uniqueAchievementsEarned == 0)
        }
    }

    @Suite("ChartSeriesData")
    struct ChartSeriesDataTests {

        @Test("Init and properties")
        func initAndProperties() {
            let data = ChartSeriesData(series: "Player A", xValue: 1, yValue: 10)

            #expect(!data.id.isEmpty)
            #expect(data.series == "Player A")
            #expect(data.xValue == 1)
            #expect(data.yValue == 10)
        }
    }

    @Suite("AchievementPlayerBreakdown")
    struct AchievementPlayerBreakdownTests {

        @Test("Init and properties")
        func initAndProperties() {
            let data = AchievementPlayerBreakdown(playerName: "Alice", count: 3)

            #expect(!data.id.isEmpty)
            #expect(data.playerName == "Alice")
            #expect(data.count == 3)
        }
    }
}
