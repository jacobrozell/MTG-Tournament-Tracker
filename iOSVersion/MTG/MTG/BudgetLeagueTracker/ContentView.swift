import SwiftUI
import SwiftData

/// Root content view with TabView navigation.
/// Manages screen-driven navigation for flows.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var leagueStates: [LeagueState]
    
    @State private var showTournamentStandings = false
    /// ViewModel for New Tournament screen; persisted so adding a player doesn't recreate it and lose form state.
    @State private var newTournamentViewModel: NewTournamentViewModel?
    
    private var currentScreen: Screen {
        leagueStates.first?.screen ?? .tournaments
    }
    
    private var shouldHideTabBar: Bool {
        switch currentScreen {
        case .newTournament, .confirmNewTournament, .addPlayers, .attendance:
            return true
        default:
            return false
        }
    }
    
    var body: some View {
        TabView {
            Tab("Tournaments", systemImage: "trophy.fill") {
                tournamentsStack
            }
            
            Tab("Players", systemImage: "person.crop.rectangle.stack") {
                playersStack
            }
            
            Tab("Stats", systemImage: "chart.bar") {
                statsStack
            }
            
            Tab("Achievements", systemImage: "star") {
                achievementsStack
            }
        }
        .onChange(of: currentScreen) { _, newScreen in
            switch newScreen {
            case .newTournament, .confirmNewTournament:
                if newTournamentViewModel == nil {
                    newTournamentViewModel = NewTournamentViewModel(context: modelContext)
                }
            default:
                newTournamentViewModel = nil
            }
            // Only show tournament standings modal at tournament end
            if newScreen == .tournamentStandings {
                showTournamentStandings = true
            }
        }
        .fullScreenCover(isPresented: $showTournamentStandings) {
            TournamentStandingsView(viewModel: TournamentStandingsViewModel(context: modelContext))
        }
    }
    
    // MARK: - Tab Stacks
    
    @ViewBuilder
    private var tournamentsStack: some View {
        NavigationStack {
            Group {
                switch currentScreen {
                case .tournaments, .dashboard, .tournamentStandings:
                    TournamentsView(viewModel: TournamentsViewModel(context: modelContext))
                case .newTournament, .confirmNewTournament:
                    if let vm = newTournamentViewModel {
                        NewTournamentView(viewModel: vm)
                    } else {
                        ProgressView()
                            .onAppear {
                                if newTournamentViewModel == nil {
                                    newTournamentViewModel = NewTournamentViewModel(context: modelContext)
                                }
                            }
                    }
                case .addPlayers:
                    AddPlayersView(viewModel: AddPlayersViewModel(context: modelContext))
                case .attendance:
                    AttendanceView(viewModel: AttendanceViewModel(context: modelContext))
                default:
                    TournamentsView(viewModel: TournamentsViewModel(context: modelContext))
                }
            }
            .navigationDestination(for: Tournament.self) { tournament in
                TournamentDetailView(viewModel: TournamentDetailViewModel(context: modelContext, tournamentId: tournament.id))
            }
        }
        .toolbar(shouldHideTabBar ? .hidden : .visible, for: .tabBar)
    }
    
    @ViewBuilder
    private var playersStack: some View {
        NavigationStack {
            PlayersView(viewModel: PlayersViewModel(context: modelContext))
                .navigationDestination(for: Player.self) { player in
                    PlayerDetailView(viewModel: PlayerDetailViewModel(context: modelContext, player: player))
                }
        }
        .toolbar(shouldHideTabBar ? .hidden : .visible, for: .tabBar)
    }
    
    @ViewBuilder
    private var statsStack: some View {
        NavigationStack {
            StatsView(viewModel: StatsViewModel(context: modelContext))
        }
        .toolbar(shouldHideTabBar ? .hidden : .visible, for: .tabBar)
    }
    
    @ViewBuilder
    private var achievementsStack: some View {
        NavigationStack {
            AchievementsView(viewModel: AchievementsViewModel(context: modelContext))
        }
        .toolbar(shouldHideTabBar ? .hidden : .visible, for: .tabBar)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Player.self, Achievement.self, LeagueState.self, Tournament.self, GameResult.self], inMemory: true)
}
