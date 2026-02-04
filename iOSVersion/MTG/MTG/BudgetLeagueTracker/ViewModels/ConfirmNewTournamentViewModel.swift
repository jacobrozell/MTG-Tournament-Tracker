import Foundation
import SwiftData

/// ViewModel for the Confirm New Tournament view.
/// Legacy ViewModel - redirects to NewTournamentViewModel.
@Observable
final class ConfirmNewTournamentViewModel {
    let context: ModelContext
    
    // MARK: - Initialization
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - Actions
    
    /// Navigates to new tournament screen.
    func confirmStart() {
        LeagueEngine.setScreen(context: context, screen: .newTournament)
    }
    
    /// Cancels and returns to tournaments list.
    func cancel() {
        LeagueEngine.setScreen(context: context, screen: .tournaments)
    }
}
