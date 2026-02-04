import SwiftUI
import Charts

/// Stats view - displays weekly standings, tournament standings, player statistics, and charts.
struct StatsView: View {
    @Bindable var viewModel: StatsViewModel
    
    var body: some View {
        Group {
            if viewModel.hasPlayers {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Standings Sections
                        standingsSections
                        
                        // Charts Section (only show if there's game data)
                        if viewModel.hasGameResults {
                            chartsSections
                        }
                        
                        // Player Stats Section
                        playerStatsSection
                    }
                }
                .background(Color(.systemGroupedBackground))
            } else {
                EmptyStateView(
                    message: "No stats yet",
                    hint: "Create a tournament and play some games to see stats."
                )
            }
        }
        .navigationTitle("Stats")
        .onAppear {
            viewModel.refresh()
        }
    }
    
    // MARK: - Standings Sections
    
    @ViewBuilder
    private var standingsSections: some View {
        // Active tournament weekly standings
        if viewModel.isLeagueStarted && viewModel.hasWeeklyStandings {
            sectionContainer {
                VStack(alignment: .leading, spacing: 2) {
                    if !viewModel.tournamentName.isEmpty {
                        Text(viewModel.tournamentName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("Week \(viewModel.currentWeek) Standings")
                        .font(.headline)
                }
                .padding(.horizontal)
                .padding(.top)
                
                ForEach(Array(viewModel.weeklyStandings.enumerated()), id: \.element.player.id) { index, item in
                    StandingsRow(
                        rank: index + 1,
                        name: item.player.name,
                        totalPoints: item.points.total,
                        placementPoints: item.points.placementPoints,
                        achievementPoints: item.points.achievementPoints,
                        mode: .weekly
                    )
                    .padding(.horizontal)
                    
                    if index < viewModel.weeklyStandings.count - 1 {
                        Divider()
                            .padding(.leading)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        
        // All-time standings
        sectionContainer {
            Text("All-Time Standings")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            ForEach(Array(viewModel.tournamentStandings.enumerated()), id: \.element.player.id) { index, item in
                StandingsRow(
                    rank: index + 1,
                    name: item.player.name,
                    totalPoints: item.totalPoints,
                    placementPoints: item.player.placementPoints,
                    achievementPoints: item.player.achievementPoints,
                    wins: item.player.wins,
                    mode: .tournament
                )
                .padding(.horizontal)
                
                if index < viewModel.tournamentStandings.count - 1 {
                    Divider()
                        .padding(.leading)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Charts Sections
    
    @ViewBuilder
    private var chartsSections: some View {
        // Points Comparison Chart
        sectionContainer {
            BarChartView.playerPoints(
                title: "Points Comparison",
                data: viewModel.playerPointsComparison,
                height: 220
            )
        }
        
        // Performance Trends Chart
        sectionContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Performance Trends")
                    .font(.headline)
                
                // Player Picker
                Picker("Player", selection: Binding(
                    get: { viewModel.selectedPlayerId ?? viewModel.players.first?.id ?? "" },
                    set: { viewModel.selectedPlayerId = $0 }
                )) {
                    ForEach(viewModel.players, id: \.id) { player in
                        Text(player.name).tag(player.id)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 4)
                
                if !viewModel.selectedPlayerPerformanceTrend.isEmpty {
                    LineChartView.performanceTrend(
                        title: "",
                        data: viewModel.selectedPlayerPerformanceTrend,
                        showArea: true,
                        height: 180
                    )
                } else {
                    noDataPlaceholder(height: 180)
                }
            }
            .padding()
        }
        
        // Placement Distribution Chart
        sectionContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Placement Distribution")
                    .font(.headline)
                
                // Player Picker
                Picker("Player", selection: Binding(
                    get: { viewModel.selectedPlayerId ?? viewModel.players.first?.id ?? "" },
                    set: { viewModel.selectedPlayerId = $0 }
                )) {
                    ForEach(viewModel.players, id: \.id) { player in
                        Text(player.name).tag(player.id)
                    }
                }
                .pickerStyle(.menu)
                
                let distribution = viewModel.selectedPlayerPlacementDistribution
                if distribution.contains(where: { $0.count > 0 }) {
                    PieChartView.placementDistribution(
                        title: "",
                        data: distribution,
                        style: .donut,
                        height: 160
                    )
                } else {
                    noDataPlaceholder(height: 160)
                }
            }
            .padding()
        }
        
        // Achievement Leaderboard Chart
        if !viewModel.achievementLeaderboard.isEmpty {
            sectionContainer {
                BarChartView.achievementLeaderboard(
                    title: "Most Earned Achievements",
                    data: Array(viewModel.achievementLeaderboard.prefix(5)),
                    height: 200
                )
            }
        }
        
        // Wins Comparison Chart
        sectionContainer {
            BarChartView.winsComparison(
                title: "Wins by Player",
                data: viewModel.winsComparison,
                height: 180
            )
        }
        
        // Top Achievement Earners Chart
        if viewModel.topAchievementEarners.contains(where: { $0.achievementPoints > 0 }) {
            sectionContainer {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top Achievement Earners")
                        .font(.headline)
                    
                    let data = viewModel.topAchievementEarners
                        .filter { $0.achievementPoints > 0 }
                        .prefix(5)
                        .map { BarChartData(id: $0.id, label: $0.name, value: $0.achievementPoints) }
                    
                    Chart(data) { item in
                        BarMark(
                            x: .value("Player", item.label),
                            y: .value("Achievement Points", item.primaryValue)
                        )
                        .foregroundStyle(Color.green.gradient)
                        .annotation(position: .top) {
                            if item.primaryValue > 0 {
                                Text("\(item.primaryValue)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(height: 180)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Player Stats Section
    
    @ViewBuilder
    private var playerStatsSection: some View {
        sectionContainer {
            Text("Player Stats")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            ForEach(viewModel.players, id: \.id) { player in
                PlayerRow(
                    name: player.name,
                    mode: .display(subtitle: viewModel.statsSubtitle(for: player))
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                if player.id != viewModel.players.last?.id {
                    Divider()
                        .padding(.leading)
                }
            }
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Helpers
    
    @ViewBuilder
    private func sectionContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    @ViewBuilder
    private func noDataPlaceholder(height: CGFloat) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.title)
                .foregroundStyle(.tertiary)
            Text("No data yet")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        StatsView(viewModel: StatsViewModel(context: PreviewContainer.shared.mainContext))
    }
}
