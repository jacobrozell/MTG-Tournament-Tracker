import Testing
import Foundation
@testable import BudgetLeagueTracker

/// Tests for AchievementStatsEngine — achievement analytics data flow (results → stats)
@Suite("AchievementStatsEngine Tests", .serialized)
@MainActor
struct AchievementStatsEngineTests {

    // MARK: - Helpers

    static func result(
        playerId: String,
        achievementIds: [String] = [],
        week: Int = 1,
        timestamp: Date = Date()
    ) -> GameResult {
        GameResult(
            tournamentId: "t1",
            week: week,
            round: 1,
            playerId: playerId,
            placement: 1,
            placementPoints: 4,
            achievementPoints: achievementIds.count,
            achievementIds: achievementIds,
            timestamp: timestamp,
            podId: "pod1"
        )
    }

    // MARK: - totalTimesEarned

    @Suite("totalTimesEarned")
    @MainActor
    struct TotalTimesEarnedTests {

        @Test("Correct count for one achievement across multiple results")
        func correctCountForOneAchievement() {
            let achId = "ach1"
            let results: [GameResult] = [
                result(playerId: "p1", achievementIds: [achId]),
                result(playerId: "p2", achievementIds: []),
                result(playerId: "p3", achievementIds: [achId]),
                result(playerId: "p4", achievementIds: [achId])
            ]

            let count = AchievementStatsEngine.totalTimesEarned(achievementId: achId, results: results)

            #expect(count == 3)
        }

        @Test("Returns zero when achievement never earned")
        func returnsZeroWhenNeverEarned() {
            let results: [GameResult] = [
                result(playerId: "p1", achievementIds: ["other"]),
                result(playerId: "p2", achievementIds: [])
            ]

            let count = AchievementStatsEngine.totalTimesEarned(achievementId: "ach1", results: results)

            #expect(count == 0)
        }

        @Test("Returns zero for empty results")
        func returnsZeroForEmptyResults() {
            let count = AchievementStatsEngine.totalTimesEarned(achievementId: "ach1", results: [])

            #expect(count == 0)
        }
    }

    // MARK: - totalAchievementsEarned

    @Suite("totalAchievementsEarned")
    @MainActor
    struct TotalAchievementsEarnedTests {

        @Test("Sums all achievement IDs across results")
        func sumsAllAchievementIds() {
            let results: [GameResult] = [
                result(playerId: "p1", achievementIds: ["a1", "a2"]),
                result(playerId: "p2", achievementIds: ["a1"]),
                result(playerId: "p3", achievementIds: [])
            ]

            let total = AchievementStatsEngine.totalAchievementsEarned(results: results)

            #expect(total == 3)
        }

        @Test("Returns zero for empty results")
        func returnsZeroForEmptyResults() {
            let total = AchievementStatsEngine.totalAchievementsEarned(results: [])

            #expect(total == 0)
        }
    }

    // MARK: - earnedByPlayer

    @Suite("earnedByPlayer")
    @MainActor
    struct EarnedByPlayerTests {

        @Test("Per-player counts for one achievement")
        func perPlayerCounts() {
            let achId = "ach1"
            let results: [GameResult] = [
                result(playerId: "p1", achievementIds: [achId]),
                result(playerId: "p1", achievementIds: [achId]),
                result(playerId: "p2", achievementIds: [achId]),
                result(playerId: "p3", achievementIds: [])
            ]

            let byPlayer = AchievementStatsEngine.earnedByPlayer(achievementId: achId, results: results)

            #expect(byPlayer["p1"] == 2)
            #expect(byPlayer["p2"] == 1)
            #expect(byPlayer["p3"] == nil)
        }

        @Test("Returns empty dictionary for empty results")
        func emptyForEmptyResults() {
            let byPlayer = AchievementStatsEngine.earnedByPlayer(achievementId: "ach1", results: [])

            #expect(byPlayer.isEmpty)
        }
    }

    // MARK: - topEarners

    @Suite("topEarners")
    @MainActor
    struct TopEarnersTests {

        @Test("Ordering by count descending and limit")
        func orderingAndLimit() {
            let achId = "ach1"
            let results: [GameResult] = [
                result(playerId: "alice", achievementIds: [achId]),
                result(playerId: "alice", achievementIds: [achId]),
                result(playerId: "alice", achievementIds: [achId]),
                result(playerId: "bob", achievementIds: [achId]),
                result(playerId: "bob", achievementIds: [achId]),
                result(playerId: "charlie", achievementIds: [achId])
            ]
            let players = TestFixtures.players("alice", "bob", "charlie", "diana")
            // Use same names as playerId for lookup (TestFixtures.players gives names; we need id to match)
            let alice = players[0]
            let bob = players[1]
            let charlie = players[2]
            let resultsWithIds: [GameResult] = [
                result(playerId: alice.id, achievementIds: [achId]),
                result(playerId: alice.id, achievementIds: [achId]),
                result(playerId: alice.id, achievementIds: [achId]),
                result(playerId: bob.id, achievementIds: [achId]),
                result(playerId: bob.id, achievementIds: [achId]),
                result(playerId: charlie.id, achievementIds: [achId])
            ]

            let top = AchievementStatsEngine.topEarners(
                achievementId: achId,
                results: resultsWithIds,
                players: players,
                limit: 2
            )

            #expect(top.count == 2)
            #expect(top[0].playerName == "alice")
            #expect(top[0].count == 3)
            #expect(top[1].playerName == "bob")
            #expect(top[1].count == 2)
        }

        @Test("Unknown player name when player not in list")
        func unknownWhenPlayerNotInList() {
            let achId = "ach1"
            let r = result(playerId: "missing-id", achievementIds: [achId])
            let players: [Player] = []

            let top = AchievementStatsEngine.topEarners(
                achievementId: achId,
                results: [r],
                players: players,
                limit: 3
            )

            #expect(top.count == 1)
            #expect(top[0].playerName == "Unknown")
            #expect(top[0].count == 1)
        }
    }

    // MARK: - achievementLeaderboard

    @Suite("achievementLeaderboard")
    @MainActor
    struct AchievementLeaderboardTests {

        @Test("Ordering by totalEarned descending")
        func orderingByTotalEarned() {
            let a1 = TestFixtures.achievement(name: "A", points: 1)
            let a2 = TestFixtures.achievement(name: "B", points: 2)
            let a3 = TestFixtures.achievement(name: "C", points: 3)
            let achievements = [a1, a2, a3]
            let results: [GameResult] = [
                result(playerId: "p1", achievementIds: [a1.id]),
                result(playerId: "p2", achievementIds: [a1.id]),
                result(playerId: "p3", achievementIds: [a2.id]),
                result(playerId: "p4", achievementIds: [a2.id]),
                result(playerId: "p5", achievementIds: [a2.id]),
                result(playerId: "p6", achievementIds: [a3.id])
            ]

            let leaderboard = AchievementStatsEngine.achievementLeaderboard(
                achievements: achievements,
                results: results
            )

            #expect(leaderboard.count == 3)
            #expect(leaderboard[0].achievement.id == a2.id)
            #expect(leaderboard[0].totalEarned == 3)
            #expect(leaderboard[1].achievement.id == a1.id)
            #expect(leaderboard[1].totalEarned == 2)
            #expect(leaderboard[2].achievement.id == a3.id)
            #expect(leaderboard[2].totalEarned == 1)
        }
    }

    // MARK: - mostPopularAchievement

    @Suite("mostPopularAchievement")
    @MainActor
    struct MostPopularAchievementTests {

        @Test("Returns top when earned")
        func returnsTopWhenEarned() {
            let a1 = TestFixtures.achievement(name: "Popular", points: 1)
            let a2 = TestFixtures.achievement(name: "Rare", points: 2)
            let results: [GameResult] = [
                result(playerId: "p1", achievementIds: [a1.id]),
                result(playerId: "p2", achievementIds: [a1.id]),
                result(playerId: "p3", achievementIds: [a2.id])
            ]

            let popular = AchievementStatsEngine.mostPopularAchievement(
                achievements: [a1, a2],
                results: results
            )

            #expect(popular != nil)
            #expect(popular?.achievement.id == a1.id)
            #expect(popular?.count == 2)
        }

        @Test("Returns nil when no achievements earned")
        func returnsNilWhenNoneEarned() {
            let a1 = TestFixtures.achievement(name: "A", points: 1)
            let results: [GameResult] = [
                result(playerId: "p1", achievementIds: [])
            ]

            let popular = AchievementStatsEngine.mostPopularAchievement(
                achievements: [a1],
                results: results
            )

            #expect(popular == nil)
        }
    }

    // MARK: - rarestAchievement

    @Suite("rarestAchievement")
    @MainActor
    struct RarestAchievementTests {

        @Test("Returns lowest-earned that has been earned at least once")
        func returnsRarestEarned() {
            let a1 = TestFixtures.achievement(name: "Popular", points: 1)
            let a2 = TestFixtures.achievement(name: "Rare", points: 2)
            let results: [GameResult] = [
                result(playerId: "p1", achievementIds: [a1.id]),
                result(playerId: "p2", achievementIds: [a1.id]),
                result(playerId: "p3", achievementIds: [a2.id])
            ]

            let rarest = AchievementStatsEngine.rarestAchievement(
                achievements: [a1, a2],
                results: results
            )

            #expect(rarest != nil)
            #expect(rarest?.achievement.id == a2.id)
            #expect(rarest?.count == 1)
        }

        @Test("Returns nil when no achievements earned")
        func returnsNilWhenNoneEarned() {
            let a1 = TestFixtures.achievement(name: "A", points: 1)
            let results: [GameResult] = [result(playerId: "p1", achievementIds: [])]

            let rarest = AchievementStatsEngine.rarestAchievement(
                achievements: [a1],
                results: results
            )

            #expect(rarest == nil)
        }
    }

    // MARK: - playerAchievementHistory

    @Suite("playerAchievementHistory")
    @MainActor
    struct PlayerAchievementHistoryTests {

        @Test("Correct counts and order by times earned descending")
        func correctCountsAndOrder() {
            let a1 = TestFixtures.achievement(name: "A", points: 1)
            let a2 = TestFixtures.achievement(name: "B", points: 2)
            let results: [GameResult] = [
                result(playerId: "p1", achievementIds: [a1.id]),
                result(playerId: "p1", achievementIds: [a1.id]),
                result(playerId: "p1", achievementIds: [a2.id]),
                result(playerId: "p2", achievementIds: [a2.id])
            ]

            let history = AchievementStatsEngine.playerAchievementHistory(
                playerId: "p1",
                achievements: [a1, a2],
                results: results
            )

            #expect(history.count == 2)
            #expect(history[0].achievement.id == a1.id)
            #expect(history[0].timesEarned == 2)
            #expect(history[1].achievement.id == a2.id)
            #expect(history[1].timesEarned == 1)
        }

        @Test("Returns empty when player has no results")
        func emptyWhenPlayerHasNoResults() {
            let a1 = TestFixtures.achievement(name: "A", points: 1)
            let results: [GameResult] = [result(playerId: "other", achievementIds: [a1.id])]

            let history = AchievementStatsEngine.playerAchievementHistory(
                playerId: "p1",
                achievements: [a1],
                results: results
            )

            #expect(history.isEmpty)
        }
    }

    // MARK: - achievementTrend

    @Suite("achievementTrend")
    @MainActor
    struct AchievementTrendTests {

        @Test("Groups by week and sorts by date ascending")
        func groupsByWeek() {
            let achId = "ach1"
            let base = Date()
            let cal = Calendar.current
            let week1 = cal.date(byAdding: .day, value: 0, to: base)!
            let week2 = cal.date(byAdding: .day, value: 8, to: base)!
            let results: [GameResult] = [
                result(playerId: "p1", achievementIds: [achId], week: 1, timestamp: week1),
                result(playerId: "p2", achievementIds: [achId], week: 1, timestamp: week1),
                result(playerId: "p3", achievementIds: [achId], week: 2, timestamp: week2)
            ]

            let trend = AchievementStatsEngine.achievementTrend(
                achievementId: achId,
                results: results,
                groupBy: .weekly
            )

            #expect(trend.count >= 1)
            #expect(trend.allSatisfy { $0.count > 0 })
        }
    }

    // MARK: - achievementTrendByWeek

    @Suite("achievementTrendByWeek")
    @MainActor
    struct AchievementTrendByWeekTests {

        @Test("Aggregates by week number")
        func aggregatesByWeek() {
            let achId = "ach1"
            let results: [GameResult] = [
                result(playerId: "p1", achievementIds: [achId], week: 1),
                result(playerId: "p2", achievementIds: [achId], week: 1),
                result(playerId: "p3", achievementIds: [achId], week: 2)
            ]

            let trend = AchievementStatsEngine.achievementTrendByWeek(
                achievementId: achId,
                results: results
            )

            #expect(trend.count == 2)
            let week1 = trend.first { $0.week == 1 }
            let week2 = trend.first { $0.week == 2 }
            #expect(week1?.count == 2)
            #expect(week2?.count == 1)
        }
    }

    // MARK: - allAchievementStats

    @Suite("allAchievementStats")
    @MainActor
    struct AllAchievementStatsTests {

        @Test("Returns total and byPlayer for each achievement")
        func returnsTotalAndByPlayer() {
            let a1 = TestFixtures.achievement(name: "A", points: 1)
            let results: [GameResult] = [
                result(playerId: "p1", achievementIds: [a1.id]),
                result(playerId: "p1", achievementIds: [a1.id]),
                result(playerId: "p2", achievementIds: [a1.id])
            ]

            let stats = AchievementStatsEngine.allAchievementStats(
                achievements: [a1],
                results: results
            )

            #expect(stats[a1.id] != nil)
            #expect(stats[a1.id]?.total == 3)
            #expect(stats[a1.id]?.byPlayer["p1"] == 2)
            #expect(stats[a1.id]?.byPlayer["p2"] == 1)
        }
    }

    // MARK: - topAchievementEarners

    @Suite("topAchievementEarners")
    @MainActor
    struct TopAchievementEarnersTests {

        @Test("Ranks players by achievement points descending")
        func ranksByAchievementPoints() {
            let p1 = TestFixtures.player(achievementPoints: 10)
            let p2 = TestFixtures.player(achievementPoints: 25)
            let p3 = TestFixtures.player(achievementPoints: 5)
            let players = [p1, p2, p3]

            let top = AchievementStatsEngine.topAchievementEarners(players: players)

            #expect(top.count == 3)
            #expect(top[0].player.id == p2.id)
            #expect(top[0].achievementPoints == 25)
            #expect(top[1].player.id == p1.id)
            #expect(top[2].player.id == p3.id)
        }
    }
}
