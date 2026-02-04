import Foundation

// MARK: - Player Points Data

/// Data structure for player points comparison charts.
/// Used in grouped bar charts showing placement vs achievement points.
struct PlayerPointsData: Identifiable {
    let id: String
    let name: String
    let placementPoints: Int
    let achievementPoints: Int
    
    var totalPoints: Int {
        placementPoints + achievementPoints
    }
    
    init(id: String = UUID().uuidString, name: String, placementPoints: Int, achievementPoints: Int) {
        self.id = id
        self.name = name
        self.placementPoints = placementPoints
        self.achievementPoints = achievementPoints
    }
    
    init(player: Player) {
        self.id = player.id
        self.name = player.name
        self.placementPoints = player.placementPoints
        self.achievementPoints = player.achievementPoints
    }
}

// MARK: - Achievement Earn Data

/// Data structure for achievement leaderboard charts.
/// Shows how many times each achievement has been earned.
struct AchievementEarnData: Identifiable {
    let id: String
    let achievementName: String
    let timesEarned: Int
    let points: Int
    
    init(id: String = UUID().uuidString, achievementName: String, timesEarned: Int, points: Int = 0) {
        self.id = id
        self.achievementName = achievementName
        self.timesEarned = timesEarned
        self.points = points
    }
    
    init(achievement: Achievement, timesEarned: Int) {
        self.id = achievement.id
        self.achievementName = achievement.name
        self.timesEarned = timesEarned
        self.points = achievement.points
    }
}

// MARK: - Placement Data

/// Data structure for placement distribution charts.
/// Used in pie/donut charts showing 1st, 2nd, 3rd, 4th place distributions.
struct PlacementData: Identifiable {
    var id: String { "\(placement)" }
    let placement: Int
    let count: Int
    
    var label: String {
        switch placement {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        case 4: return "4th"
        default: return "\(placement)th"
        }
    }
    
    var percentage: Double {
        0 // Will be calculated by the view based on total
    }
    
    init(placement: Int, count: Int) {
        self.placement = placement
        self.count = count
    }
    
    /// Creates placement data array from a distribution dictionary.
    static func from(distribution: [Int: Int]) -> [PlacementData] {
        [1, 2, 3, 4].map { placement in
            PlacementData(placement: placement, count: distribution[placement] ?? 0)
        }
    }
}

// MARK: - Performance Trend Data

/// Data structure for performance trend line charts.
/// Shows cumulative points over time/weeks.
struct PerformanceTrendData: Identifiable {
    let id: String
    let playerName: String
    let week: Int
    let cumulativePoints: Int
    let placementPoints: Int
    let achievementPoints: Int
    
    init(
        id: String = UUID().uuidString,
        playerName: String,
        week: Int,
        cumulativePoints: Int,
        placementPoints: Int = 0,
        achievementPoints: Int = 0
    ) {
        self.id = id
        self.playerName = playerName
        self.week = week
        self.cumulativePoints = cumulativePoints
        self.placementPoints = placementPoints
        self.achievementPoints = achievementPoints
    }
}

// MARK: - Achievement Player Breakdown

/// Data structure for per-player achievement breakdown.
/// Shows which players earned a specific achievement and how many times.
struct AchievementPlayerBreakdown: Identifiable {
    let id: String
    let playerName: String
    let count: Int
    
    init(id: String = UUID().uuidString, playerName: String, count: Int) {
        self.id = id
        self.playerName = playerName
        self.count = count
    }
}

// MARK: - Points Breakdown Data

/// Data structure for points breakdown pie/donut charts.
/// Shows placement vs achievement points ratio.
struct PointsBreakdownData: Identifiable {
    let id: String
    let category: String
    let points: Int
    
    init(id: String = UUID().uuidString, category: String, points: Int) {
        self.id = id
        self.category = category
        self.points = points
    }
    
    /// Creates points breakdown for placement vs achievement points.
    static func from(placementPoints: Int, achievementPoints: Int) -> [PointsBreakdownData] {
        [
            PointsBreakdownData(id: "placement", category: "Placement", points: placementPoints),
            PointsBreakdownData(id: "achievement", category: "Achievement", points: achievementPoints)
        ]
    }
}

// MARK: - Wins Comparison Data

/// Data structure for wins comparison bar charts.
struct WinsComparisonData: Identifiable {
    let id: String
    let playerName: String
    let wins: Int
    let gamesPlayed: Int
    
    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(wins) / Double(gamesPlayed)
    }
    
    init(id: String = UUID().uuidString, playerName: String, wins: Int, gamesPlayed: Int) {
        self.id = id
        self.playerName = playerName
        self.wins = wins
        self.gamesPlayed = gamesPlayed
    }
    
    init(player: Player) {
        self.id = player.id
        self.playerName = player.name
        self.wins = player.wins
        self.gamesPlayed = player.gamesPlayed
    }
}

// MARK: - Chart Series Data

/// Generic data point for multi-series charts.
struct ChartSeriesData: Identifiable {
    let id: String
    let series: String
    let xValue: Int
    let yValue: Int
    
    init(id: String = UUID().uuidString, series: String, xValue: Int, yValue: Int) {
        self.id = id
        self.series = series
        self.xValue = xValue
        self.yValue = yValue
    }
}

// MARK: - Achievement Stats Summary

/// Summary statistics for the achievements view header.
struct AchievementStatsSummary {
    let totalEarned: Int
    let mostPopularName: String?
    let mostPopularCount: Int
    let rarestName: String?
    let rarestCount: Int
    let uniqueAchievementsEarned: Int
    
    init(
        totalEarned: Int = 0,
        mostPopularName: String? = nil,
        mostPopularCount: Int = 0,
        rarestName: String? = nil,
        rarestCount: Int = 0,
        uniqueAchievementsEarned: Int = 0
    ) {
        self.totalEarned = totalEarned
        self.mostPopularName = mostPopularName
        self.mostPopularCount = mostPopularCount
        self.rarestName = rarestName
        self.rarestCount = rarestCount
        self.uniqueAchievementsEarned = uniqueAchievementsEarned
    }
}
