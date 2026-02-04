import SwiftUI

/// Tournaments view - displays list of ongoing and completed tournaments.
/// This is the main entry point of the app (renamed from Dashboard).
struct TournamentsView: View {
    @Bindable var viewModel: TournamentsViewModel
    
    var body: some View {
        Group {
            if viewModel.hasTournaments {
                tournamentsList
            } else {
                emptyState
            }
        }
        .navigationTitle("Tournaments")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.createNewTournament()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add tournament")
                .accessibilityIdentifier("Add")
            }
        }
        .onAppear {
            viewModel.refresh()
        }
    }
    
    // MARK: - Tournament List
    
    @ViewBuilder
    private var tournamentsList: some View {
        List {
            // Ongoing tournaments section
            if viewModel.hasOngoingTournaments {
                Section("Ongoing") {
                    ForEach(viewModel.ongoingTournaments, id: \.id) { tournament in
                        NavigationLink(value: tournament) {
                            TournamentCell(
                                tournament: tournament,
                                playerCount: viewModel.playerCount(for: tournament),
                                winnerName: nil
                            )
                        }
                    }
                }
            }
            
            // Completed tournaments section
            if viewModel.hasCompletedTournaments {
                Section("Completed") {
                    ForEach(viewModel.completedTournaments, id: \.id) { tournament in
                        NavigationLink(value: tournament) {
                            TournamentCell(
                                tournament: tournament,
                                playerCount: viewModel.playerCount(for: tournament),
                                winnerName: viewModel.winnerName(for: tournament)
                            )
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Empty State
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            EmptyStateView(
                message: "No tournaments yet",
                hint: "Tap the + button to create your first tournament."
            )
            
            Spacer()
            
            PrimaryActionButton(
                title: "Create Tournament",
                action: { viewModel.createNewTournament() },
                accessibilityLabel: "Create Tournament"
            )
            .accessibilityIdentifier("Create Tournament")
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    NavigationStack {
        TournamentsView(viewModel: TournamentsViewModel(context: PreviewContainer.shared.mainContext))
    }
}
