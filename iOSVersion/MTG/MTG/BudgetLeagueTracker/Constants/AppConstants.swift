import Foundation
import SwiftUI

/// Centralized constants for the Budget League Tracker app.
/// All magic numbers and literal strings are defined here for consistency and testability.
enum AppConstants {
    
    // MARK: - UI / Accessibility
    
    enum UI {
        /// Minimum touch target height per iOS HIG (44pt)
        static let minTouchTargetHeight: CGFloat = 44
    }
    
    // MARK: - Accessible Colors
    
    /// Colors that meet WCAG 2.1 AA contrast requirements
    enum AccessibleColors {
        /// Secondary text color with improved contrast (4.5:1 ratio minimum)
        static let secondaryText = Color(uiColor: .secondaryLabel)
        
        /// Caption text color with improved contrast
        static let captionText = Color(uiColor: .secondaryLabel)
        
        /// Hint text color - uses secondary label for accessibility
        static let hintText = Color(uiColor: .secondaryLabel)
        
        /// Active/green status color with sufficient contrast
        static let activeStatus = Color(uiColor: .systemGreen)
    }
    
    // MARK: - League / Tournament
    
    enum League {
        /// Valid range for total weeks in a tournament
        static let weeksRange = 1...99
        
        /// Valid range for random achievements per week
        static let randomAchievementsPerWeekRange = 0...99
        
        /// Default number of weeks when creating a new league
        static let defaultTotalWeeks = 6
        
        /// Default number of random achievements per week
        static let defaultRandomAchievementsPerWeek = 2
        
        /// Number of rounds per week
        static let roundsPerWeek = 3
        
        /// Number of players per pod
        static let podSize = 4
        
        /// Default current week when starting
        static let defaultCurrentWeek = 1
        
        /// Default current round when starting
        static let defaultCurrentRound = 1
        
        /// Default value for achievements on this week
        static let defaultAchievementsOnThisWeek = true
    }
    
    // MARK: - Scoring
    
    enum Scoring {
        /// Returns placement points for a given place (1st through 4th)
        /// - Parameter place: The finishing place (1-4)
        /// - Returns: Points awarded (1st=4, 2nd=3, 3rd=2, 4th=1)
        static func placementPoints(forPlace place: Int) -> Int {
            switch place {
            case 1: return 4
            case 2: return 3
            case 3: return 2
            case 4: return 1
            default: return 0
            }
        }
        
        /// Dictionary mapping placement to points
        static let placementToPoints: [Int: Int] = [
            1: 4,
            2: 3,
            3: 2,
            4: 1
        ]
        
        /// Initial placement points for a new player
        static let initialPlacementPoints = 0
        
        /// Initial achievement points for a new player
        static let initialAchievementPoints = 0
        
        /// Initial wins for a new player
        static let initialWins = 0
        
        /// Initial games played for a new player
        static let initialGamesPlayed = 0
    }
    
    // MARK: - Default Achievement
    
    enum DefaultAchievement {
        /// Name of the default seeded achievement
        static let name = "First Blood"
        
        /// Points for the default achievement
        static let points = 1
        
        /// Whether the default achievement is always on
        static let alwaysOn = false
    }
}
