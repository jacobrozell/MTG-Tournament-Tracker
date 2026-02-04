import SwiftUI
import SwiftData

/// Main entry point for the Budget League Tracker iOS app.
@main
struct BudgetLeagueTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Player.self,
            Achievement.self,
            LeagueState.self,
            Tournament.self,
            GameResult.self
        ]) { result in
            switch result {
            case .success(let container):
                bootstrapData(in: container)
            case .failure(let error):
                print("Failed to create model container: \(error)")
            }
        }
    }
    
    /// Bootstrap initial data if needed.
    /// Creates default LeagueState, seeds the default achievement, and validates state.
    private func bootstrapData(in container: ModelContainer) {
        let context = container.mainContext
        
        // Ensure exactly one LeagueState exists
        let leagueStateDescriptor = FetchDescriptor<LeagueState>()
        let existingStates = (try? context.fetch(leagueStateDescriptor)) ?? []
        
        if existingStates.isEmpty {
            let defaultState = LeagueState()
            context.insert(defaultState)
        }
        
        // Seed default achievement if none exist
        let achievementDescriptor = FetchDescriptor<Achievement>()
        let existingAchievements = (try? context.fetch(achievementDescriptor)) ?? []
        
        if existingAchievements.isEmpty {
            let defaultAchievement = Achievement(
                name: AppConstants.DefaultAchievement.name,
                points: AppConstants.DefaultAchievement.points,
                alwaysOn: AppConstants.DefaultAchievement.alwaysOn
            )
            context.insert(defaultAchievement)
        }
        
        // Save changes
        try? context.save()
        
        // Validate and sanitize state to fix any inconsistencies
        LeagueEngine.validateAndSanitizeState(context: context)
    }
}
