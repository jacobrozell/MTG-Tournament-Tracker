import SwiftUI
import Charts

/// Player detail view - displays comprehensive player statistics with charts.
/// Allows viewing all-time stats, placement distribution, performance trend, and deleting the player.
struct PlayerDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: PlayerDetailViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // All-Time Stats Section
                statsSection
                
                // Points Breakdown Section
                pointsBreakdownSection
                
                // Charts Section (only show if there's game data)
                if viewModel.hasGameResults {
                    chartsSection
                }
                
                // Delete Section
                deleteSection
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.player.name)
        .navigationBarTitleDisplayMode(.large)
        .alert("Delete Player", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if viewModel.deletePlayer() {
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(viewModel.player.name)? This action cannot be undone and will remove all their stats.")
        }
        .onAppear {
            viewModel.refresh()
        }
    }
    
    // MARK: - Stats Section
    
    @ViewBuilder
    private var statsSection: some View {
        sectionContainer {
            Text("All-Time Stats")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(title: "Total Points", value: "\(viewModel.player.totalPoints)")
                StatCard(title: "Games Played", value: "\(viewModel.player.gamesPlayed)")
                StatCard(title: "Wins", value: "\(viewModel.player.wins)")
                StatCard(title: "Tournaments", value: "\(viewModel.player.tournamentsPlayed)")
                StatCard(title: "Win Rate", value: viewModel.winRateString)
                StatCard(title: "Avg Placement", value: viewModel.averagePlacementString)
            }
            .padding()
        }
    }
    
    // MARK: - Points Breakdown Section
    
    @ViewBuilder
    private var pointsBreakdownSection: some View {
        sectionContainer {
            VStack(alignment: .leading, spacing: 12) {
                Text("Points Breakdown")
                    .font(.headline)
                
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                            Text("Placement")
                                .font(.subheadline)
                        }
                        Text("\(viewModel.player.placementPoints) pts")
                            .font(.title2.bold())
                            .foregroundStyle(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                            Text("Achievement")
                                .font(.subheadline)
                        }
                        Text("\(viewModel.player.achievementPoints) pts")
                            .font(.title2.bold())
                            .foregroundStyle(.green)
                    }
                    
                    Spacer()
                }
                
                // Points per game
                HStack {
                    Text("Points per Game")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel.pointsPerGameString)
                        .font(.subheadline.bold())
                }
            }
            .padding()
        }
    }
    
    // MARK: - Charts Section
    
    @ViewBuilder
    private var chartsSection: some View {
        // Placement Distribution
        sectionContainer {
            PieChartView.placementDistribution(
                title: "Placement Distribution",
                data: viewModel.placementDistribution,
                style: .donut,
                height: 160
            )
        }
        
        // Performance Trend
        if !viewModel.performanceTrend.isEmpty {
            sectionContainer {
                LineChartView.performanceTrend(
                    title: "Performance Over Time",
                    data: viewModel.performanceTrend,
                    showArea: true,
                    height: 180
                )
            }
        }
    }
    
    // MARK: - Delete Section
    
    @ViewBuilder
    private var deleteSection: some View {
        sectionContainer {
            Button(role: .destructive) {
                viewModel.confirmDelete()
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Player")
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .padding(.bottom, 32)
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
}

// MARK: - Stat Card Component

private struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        PlayerDetailView(
            viewModel: PlayerDetailViewModel(
                context: PreviewContainer.shared.mainContext,
                player: Player(name: "Test Player")
            )
        )
    }
}
