import Foundation
import SwiftData

/// ViewModel for the New Achievement view.
/// Handles achievement creation with name, points, and always-on setting.
@Observable
final class NewAchievementViewModel {
    private let context: ModelContext
    
    // MARK: - Published State
    
    /// Achievement name (required)
    var name: String = ""
    
    /// Points for the achievement
    var points: Int = 1
    
    /// Whether the achievement is always on
    var alwaysOn: Bool = false
    
    /// Callback when achievement is added successfully
    var onAdd: (() -> Void)?
    
    /// Callback when cancelled
    var onCancel: (() -> Void)?
    
    // MARK: - Computed Properties
    
    /// Whether the achievement can be added
    var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Initialization
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - Actions
    
    /// Adds the achievement and calls the onAdd callback.
    func addAchievement() {
        guard canAdd else { return }
        
        LeagueEngine.addAchievement(
            context: context,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            points: points,
            alwaysOn: alwaysOn
        )
        
        onAdd?()
    }
    
    /// Cancels and calls the onCancel callback.
    func cancel() {
        onCancel?()
    }
    
    /// Resets the form to default values.
    func reset() {
        name = ""
        points = 1
        alwaysOn = false
    }
}
