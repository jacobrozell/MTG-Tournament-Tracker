import SwiftUI

/// Tournament Standings view - shows all players sorted by total points.
/// Presented as a fullScreenCover when final.
struct TournamentStandingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: TournamentStandingsViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.sortedPlayers.isEmpty {
                    EmptyStateView(message: "No standings to display")
                } else {
                    List {
                        ForEach(Array(viewModel.sortedPlayers.enumerated()), id: \.element.id) { index, player in
                            StandingsRow(
                                rank: index + 1,
                                name: player.name,
                                totalPoints: player.totalPoints,
                                placementPoints: player.placementPoints,
                                achievementPoints: player.achievementPoints,
                                wins: player.wins,
                                mode: .tournament
                            )
                        }
                    }
                    .listStyle(.insetGrouped)
                }
                
                ModalActionBar(
                    primaryTitle: "Close",
                    primaryAction: {
                        viewModel.close()
                        dismiss()
                    }
                )
            }
            .navigationTitle(viewModel.isFinal ? "Final Rankings" : "Tournament Rankings")
            .onAppear {
                viewModel.refresh()
            }
        }
    }
}

#Preview {
    TournamentStandingsView(viewModel: TournamentStandingsViewModel(context: PreviewContainer.shared.mainContext))
}
