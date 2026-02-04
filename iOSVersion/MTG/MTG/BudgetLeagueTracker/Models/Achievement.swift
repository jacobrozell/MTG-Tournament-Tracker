import Foundation
import SwiftData

/// Represents an achievement that players can earn during games.
@Model
final class Achievement {
    /// Unique identifier for the achievement
    var id: String
    
    /// Achievement name/description
    var name: String
    
    /// Points awarded when this achievement is earned
    var points: Int
    
    /// If true, this achievement is always available every week.
    /// If false, it may be randomly selected for a given week.
    var alwaysOn: Bool
    
    /// Creates a new achievement.
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - name: Achievement name/description
    ///   - points: Points awarded when earned
    ///   - alwaysOn: Whether this achievement is always available
    init(
        id: String = UUID().uuidString,
        name: String,
        points: Int,
        alwaysOn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.points = points
        self.alwaysOn = alwaysOn
    }
}
