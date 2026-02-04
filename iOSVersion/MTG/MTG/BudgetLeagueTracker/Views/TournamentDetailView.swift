import SwiftUI

/// Tournament detail view - landing page for a tournament.
/// Shows different content based on tournament status (ongoing vs completed).
/// For ongoing: attendance, pods, weekly standings with full pod management.
/// For completed: final standings and tournament summary.
struct TournamentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: TournamentDetailViewModel
    
    var body: some View {
        Group {
            if viewModel.isOngoing {
                ongoingContent
            } else {
                completedContent
            }
        }
        .navigationTitle(viewModel.tournamentName)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.setAsActiveTournament()
            viewModel.refresh()
        }
        .sheet(isPresented: $viewModel.showEditLastRound) {
            EditLastRoundView(
                viewModel: EditLastRoundViewModel(
                    context: modelContext,
                    tournamentId: viewModel.tournamentId
                ),
                onSave: { viewModel.onEditLastRoundSaved() }
            )
        }
        .sheet(isPresented: $viewModel.showAttendance) {
            AttendanceView(
                viewModel: AttendanceViewModel(context: modelContext),
                onConfirm: {
                    viewModel.showAttendance = false
                    viewModel.refresh()
                }
            )
        }
    }
    
    // MARK: - Ongoing Tournament Content
    
    @ViewBuilder
    private var ongoingContent: some View {
        List {
            // Tournament Info Header
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.weekProgressString)
                        .font(.headline)
                    Text(viewModel.roundString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Attendance Section
            if !viewModel.hasPresentPlayers {
                Section("Attendance") {
                    Button {
                        viewModel.goToAttendance()
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Mark Attendance")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HintText(message: "Mark attendance before generating pods for this week.")
                }
            } else {
                // Actions Section
                actionsSection
                
                // Weekly Standings Section
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
                
                // Pods Section
                if !viewModel.pods.isEmpty {
                    ForEach(Array(viewModel.pods.enumerated()), id: \.offset) { index, pod in
                        Section("Pod \(index + 1)") {
                            podContent(pod: pod)
                        }
                    }
                } else {
                    Section {
                        EmptyStateView(
                            message: "No pods generated",
                            hint: "Tap Generate to create pods for this round."
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Actions Section
    
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
                
                // Option to change attendance
                Button {
                    viewModel.goToAttendance()
                } label: {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Edit Attendance")
                    }
                    .font(.subheadline)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Pod Content
    
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
    
    // MARK: - Completed Tournament Content
    
    @ViewBuilder
    private var completedContent: some View {
        List {
            // Tournament Summary Header
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    if let winner = viewModel.winnerName {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)
                            Text("Winner: \(winner)")
                                .font(.headline)
                        }
                    }
                    
                    Text(viewModel.dateRangeString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(viewModel.totalWeeks) weeks • \(viewModel.finalStandings.count) players")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Final Standings
            Section("Final Standings") {
                if viewModel.finalStandings.isEmpty {
                    Text("No standings available")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(viewModel.finalStandings.enumerated()), id: \.element.player.id) { index, standing in
                        StandingsRow(
                            rank: index + 1,
                            name: standing.player.name,
                            totalPoints: standing.points,
                            placementPoints: standing.placementPoints,
                            achievementPoints: standing.achievementPoints,
                            wins: standing.wins,
                            mode: .tournament
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview("Ongoing") {
    NavigationStack {
        TournamentDetailView(
            viewModel: TournamentDetailViewModel(
                context: PreviewContainer.shared.mainContext,
                tournamentId: "preview"
            )
        )
    }
}

#Preview("Completed") {
    NavigationStack {
        TournamentDetailView(
            viewModel: TournamentDetailViewModel(
                context: PreviewContainer.shared.mainContext,
                tournamentId: "completed-preview"
            )
        )
    }
}
