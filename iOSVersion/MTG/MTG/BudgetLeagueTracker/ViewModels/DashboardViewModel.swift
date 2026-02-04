import Foundation
import SwiftData

/// ViewModel for the Dashboard view.
/// Legacy ViewModel - redirects to TournamentsViewModel.
@Observable
final class DashboardViewModel {
    let context: ModelContext
    
    // MARK: - Published State
    
    var isLeagueStarted: Bool = false
    var currentWeek: Int = 0
    
    // MARK: - Initialization
    
    init(context: ModelContext) {
        self.context = context
        refresh()
    }
    
    // MARK: - Actions
    
    /// Refreshes state from SwiftData.
    func refresh() {
        if let tournament = LeagueEngine.fetchActiveTournament(context: context) {
            isLeagueStarted = true
            currentWeek = tournament.currentWeek
        } else {
            isLeagueStarted = false
            currentWeek = 0
        }
    }
    
    /// Navigates to the new tournament screen.
    func startNewTournament() {
        LeagueEngine.setScreen(context: context, screen: .newTournament)
    }
}
