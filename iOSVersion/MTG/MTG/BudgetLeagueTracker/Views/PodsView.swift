import SwiftUI

/// Pods view - generate pods, set placements and achievements with auto-save.
/// Shows inline weekly standings at the top.
///
/// - Note: DEPRECATED - This view has been replaced by TournamentDetailView.
///   Pod management is now accessed through the tournament landing page.
///   This file is kept for backwards compatibility and can be removed in a future update.
@available(*, deprecated, message: "Use TournamentDetailView instead. Pod management is now part of the tournament landing page.")
struct PodsView: View {
    @Bindable var viewModel: PodsViewModel
    
    var body: some View {
        Group {
            if !viewModel.isLeagueStarted {
                notStartedState
            } else if viewModel.pods.isEmpty {
                emptyState
            } else {
                podsList
            }
        }
        .navigationTitle(viewModel.isLeagueStarted ? "Pods – Round \(viewModel.currentRound)" : "Pods")
        .onAppear {
            viewModel.refresh()
        }
    }
    
    @ViewBuilder
    private var actionsSection: some View {
        Section("Actions") {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    PrimaryActionButton(
                        title: "Generate",
                        action: { viewModel.generatePods() },
                        isDisabled: !viewModel.canGeneratePods
                    )
                    
                    SecondaryButton(
                        title: "Next Round",
                        action: { viewModel.nextRound() }
                    )
                }
                
                SecondaryButton(
                    title: "Edit Last Round",
                    action: { viewModel.editLastRound() },
                    isDisabled: !viewModel.canEdit
                )
                
                if !viewModel.canGeneratePods {
                    HintText(message: "No present players. Go to Attendance first.")
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private var notStartedState: some View {
        EmptyStateView(
            message: "No tournament in progress",
            hint: "Start a new tournament from the Dashboard tab."
        )
    }
    
    @ViewBuilder
    private var emptyState: some View {
        List {
            // Actions section at the top
            actionsSection
            
            // Empty state message
            Section {
                EmptyStateView(
                    message: "No pods generated",
                    hint: "Tap Generate to create pods for this round."
                )
            }
        }
        .listStyle(.insetGrouped)
    }
    
    @ViewBuilder
    private var podsList: some View {
        List {
            // Actions section at the top
            actionsSection
            
            // Inline weekly standings
            if !viewModel.weeklyStandings.isEmpty {
                Section("Week \(viewModel.currentWeek) Standings") {
                    ForEach(Array(viewModel.weeklyStandings.enumerated()), id: \.element.player.id) { index, item in
                        HStack {
                            Text("\(index + 1).")
                                .foregroundStyle(.secondary)
                                .frame(width: 24, alignment: .leading)
                            Text(item.player.name)
                            Spacer()
                            Text("\(item.points.total) pts")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            // Pod sections
            ForEach(Array(viewModel.pods.enumerated()), id: \.offset) { index, pod in
                Section("Pod \(index + 1)") {
                    podContent(pod: pod)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    @ViewBuilder
    private func podContent(pod: [Player]) -> some View {
        ForEach(pod, id: \.id) { player in
            VStack(alignment: .leading, spacing: 8) {
                Text(player.name)
                    .font(.headline)
                
                PlacementPicker(
                    playerName: player.name,
                    selection: Binding(
                        get: { viewModel.placement(for: player.id) },
                        set: { viewModel.setPlacement(for: player.id, place: $0) }
                    ),
                    isDisabled: false
                )
                
                if viewModel.achievementsOnThisWeek && !viewModel.activeAchievements.isEmpty {
                    ForEach(viewModel.activeAchievements, id: \.id) { achievement in
                        AchievementCheckItem(
                            name: achievement.name,
                            points: achievement.points,
                            isChecked: Binding(
                                get: { viewModel.isAchievementChecked(playerId: player.id, achievementId: achievement.id) },
                                set: { _ in viewModel.toggleAchievementCheck(playerId: player.id, achievementId: achievement.id) }
                            ),
                            isDisabled: false
                        )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    NavigationStack {
        PodsView(viewModel: PodsViewModel(context: PreviewContainer.shared.mainContext))
    }
}
