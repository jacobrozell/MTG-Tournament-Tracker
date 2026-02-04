import SwiftUI
import Charts

/// Achievements view - manage achievements (add, remove, toggle always-on) with stats.
struct AchievementsView: View {
    @Bindable var viewModel: AchievementsViewModel
    
    var body: some View {
        Group {
            if viewModel.hasAchievements {
                achievementsContent
            } else {
                emptyState
            }
        }
        .navigationTitle("Achievements")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showNewAchievement()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingNewAchievement) {
            NewAchievementView(viewModel: viewModel.makeNewAchievementViewModel())
        }
        .onAppear {
            viewModel.refresh()
        }
    }
    
    // MARK: - Achievements Content
    
    @ViewBuilder
    private var achievementsContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Stats Summary Section
                if viewModel.hasGameResults {
                    statsSummarySection
                    
                    // Achievement Distribution Chart
                    if !viewModel.achievementDistribution.isEmpty {
                        distributionChartSection
                    }
                }
                
                // Achievements List with Stats
                achievementsListSection
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Stats Summary Section
    
    @ViewBuilder
    private var statsSummarySection: some View {
        let summary = viewModel.statsSummary
        
        sectionContainer {
            VStack(alignment: .leading, spacing: 12) {
                Label("Stats Summary", systemImage: "chart.bar.fill")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    // Total Earned
                    statCard(
                        title: "Total Earned",
                        value: "\(summary.totalEarned)",
                        icon: "trophy.fill",
                        color: .orange
                    )
                    
                    // Unique Achievements
                    statCard(
                        title: "Unique Earned",
                        value: "\(summary.uniqueAchievementsEarned)/\(viewModel.achievements.count)",
                        icon: "star.fill",
                        color: .yellow
                    )
                }
                
                // Most Popular & Rarest
                if summary.mostPopularName != nil || summary.rarestName != nil {
                    Divider()
                    
                    HStack(spacing: 16) {
                        if let popular = summary.mostPopularName {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Most Popular")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(popular)
                                    .font(.subheadline.bold())
                                Text("\(summary.mostPopularCount) times")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if let rarest = summary.rarestName, summary.rarestCount > 0 {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Rarest")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(rarest)
                                    .font(.subheadline.bold())
                                Text("\(summary.rarestCount) times")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.caption)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Distribution Chart Section
    
    @ViewBuilder
    private var distributionChartSection: some View {
        sectionContainer {
            PieChartView.achievementDistribution(
                title: "Achievement Distribution",
                data: viewModel.achievementDistribution,
                style: .pie,
                height: 180
            )
        }
    }
    
    // MARK: - Achievements List Section
    
    @ViewBuilder
    private var achievementsListSection: some View {
        sectionContainer {
            VStack(alignment: .leading, spacing: 0) {
                Text("Achievements")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 8)
                
                ForEach(viewModel.achievements, id: \.id) { achievement in
                    achievementRow(for: achievement)
                    
                    if achievement.id != viewModel.achievements.last?.id {
                        Divider()
                            .padding(.leading)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func achievementRow(for achievement: Achievement) -> some View {
        let totalEarned = viewModel.totalTimesEarned(for: achievement)
        let topEarners = viewModel.topEarners(for: achievement, limit: 3)
        
        VStack(alignment: .leading, spacing: 8) {
            // Header Row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(achievement.name)
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        Label("\(achievement.points) pts", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if achievement.alwaysOn {
                            Text("Always On")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
                
                // Actions Menu
                Menu {
                    Button {
                        viewModel.toggleAlwaysOn(achievement)
                    } label: {
                        Label(
                            achievement.alwaysOn ? "Disable Always On" : "Enable Always On",
                            systemImage: achievement.alwaysOn ? "toggle.off" : "toggle.on"
                        )
                    }
                    
                    Button(role: .destructive) {
                        viewModel.removeAchievement(achievement)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("Options for \(achievement.name)")
            }
            
            // Stats Row (only if there are game results)
            if viewModel.hasGameResults {
                HStack {
                    Label("Earned \(totalEarned) times", systemImage: "trophy")
                        .font(.caption)
                        .foregroundStyle(totalEarned > 0 ? .secondary : .tertiary)
                    
                    Spacer()
                }
                
                // Top Earners (if any)
                if !topEarners.isEmpty {
                    HStack(spacing: 4) {
                        Text("Top:")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        
                        ForEach(Array(topEarners.enumerated()), id: \.offset) { index, earner in
                            HStack(spacing: 2) {
                                Circle()
                                    .fill(earnerColor(for: index))
                                    .frame(width: 6, height: 6)
                                Text("\(earner.playerName) (\(earner.count))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if index < topEarners.count - 1 {
                                Text("·")
                                    .font(.caption2)
                                    .foregroundStyle(.quaternary)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .contentShape(Rectangle())
    }
    
    private func earnerColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .orange
        default: return .secondary
        }
    }
    
    // MARK: - Empty State
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            EmptyStateView(
                message: "No achievements yet",
                hint: "Tap the + button to create your first achievement."
            )
            
            Spacer()
            
            PrimaryActionButton(title: "Add Achievement") {
                viewModel.showNewAchievement()
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
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
}

#Preview {
    NavigationStack {
        AchievementsView(viewModel: AchievementsViewModel(context: PreviewContainer.shared.mainContext))
    }
}
