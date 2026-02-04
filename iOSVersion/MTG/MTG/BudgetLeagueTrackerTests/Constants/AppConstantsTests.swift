import Testing
import Foundation
@testable import BudgetLeagueTracker

/// Tests for AppConstants — constants and scoring function
@Suite("AppConstants Tests", .serialized)
struct AppConstantsTests {

    @Suite("League")
    struct LeagueTests {

        @Test("weeksRange is 1...99")
        func weeksRange() {
            #expect(AppConstants.League.weeksRange == 1...99)
            #expect(AppConstants.League.weeksRange.contains(1))
            #expect(AppConstants.League.weeksRange.contains(99))
            #expect(!AppConstants.League.weeksRange.contains(0))
            #expect(!AppConstants.League.weeksRange.contains(100))
        }

        @Test("randomAchievementsPerWeekRange is 0...99")
        func randomAchievementsPerWeekRange() {
            #expect(AppConstants.League.randomAchievementsPerWeekRange == 0...99)
            #expect(AppConstants.League.randomAchievementsPerWeekRange.contains(0))
            #expect(AppConstants.League.randomAchievementsPerWeekRange.contains(99))
        }

        @Test("Default and fixed League values")
        func defaultAndFixedValues() {
            #expect(AppConstants.League.defaultTotalWeeks == 6)
            #expect(AppConstants.League.defaultRandomAchievementsPerWeek == 2)
            #expect(AppConstants.League.roundsPerWeek == 3)
            #expect(AppConstants.League.podSize == 4)
            #expect(AppConstants.League.defaultCurrentWeek == 1)
            #expect(AppConstants.League.defaultCurrentRound == 1)
            #expect(AppConstants.League.defaultAchievementsOnThisWeek == true)
        }
    }

    @Suite("Scoring.placementPoints")
    struct PlacementPointsTests {

        @Test("Returns correct points for places 1-4", arguments: [
            (1, 4),
            (2, 3),
            (3, 2),
            (4, 1)
        ])
        func placementPoints(place: Int, expected: Int) {
            #expect(AppConstants.Scoring.placementPoints(forPlace: place) == expected)
        }

        @Test("Returns 0 for invalid place")
        func invalidPlaceReturnsZero() {
            #expect(AppConstants.Scoring.placementPoints(forPlace: 0) == 0)
            #expect(AppConstants.Scoring.placementPoints(forPlace: 5) == 0)
            #expect(AppConstants.Scoring.placementPoints(forPlace: -1) == 0)
        }
    }

    @Suite("Scoring.placementToPoints")
    struct PlacementToPointsTests {

        @Test("Maps 1-4 to correct points")
        func placementToPoints() {
            #expect(AppConstants.Scoring.placementToPoints[1] == 4)
            #expect(AppConstants.Scoring.placementToPoints[2] == 3)
            #expect(AppConstants.Scoring.placementToPoints[3] == 2)
            #expect(AppConstants.Scoring.placementToPoints[4] == 1)
            #expect(AppConstants.Scoring.placementToPoints.count == 4)
        }
    }

    @Suite("Scoring initial values")
    struct ScoringInitialTests {

        @Test("Initial stats are zero")
        func initialStatsZero() {
            #expect(AppConstants.Scoring.initialPlacementPoints == 0)
            #expect(AppConstants.Scoring.initialAchievementPoints == 0)
            #expect(AppConstants.Scoring.initialWins == 0)
            #expect(AppConstants.Scoring.initialGamesPlayed == 0)
        }
    }

    @Suite("DefaultAchievement")
    struct DefaultAchievementTests {

        @Test("Name points and alwaysOn")
        func defaultAchievementValues() {
            #expect(AppConstants.DefaultAchievement.name == "First Blood")
            #expect(AppConstants.DefaultAchievement.points == 1)
            #expect(AppConstants.DefaultAchievement.alwaysOn == false)
        }
    }
}
