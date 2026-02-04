import SwiftUI
import SwiftData

/// Legacy Dashboard view - redirects to TournamentsView.
/// Kept for backwards compatibility.
struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel
    
    var body: some View {
        TournamentsView(viewModel: TournamentsViewModel(context: viewModel.context))
    }
}

#Preview {
    NavigationStack {
        DashboardView(viewModel: DashboardViewModel(context: PreviewContainer.shared.mainContext))
    }
}

// MARK: - Preview Helper

/// A shared preview container for SwiftUI previews.
@MainActor
enum PreviewContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            Player.self,
            Achievement.self,
            LeagueState.self,
            Tournament.self,
            GameResult.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        
        // Bootstrap default data
        let context = container.mainContext
        context.insert(LeagueState())
        context.insert(Achievement(
            name: AppConstants.DefaultAchievement.name,
            points: AppConstants.DefaultAchievement.points,
            alwaysOn: AppConstants.DefaultAchievement.alwaysOn
        ))
        
        return container
    }()
}
