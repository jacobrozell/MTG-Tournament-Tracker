import SwiftUI

/// New Tournament view - create a new tournament with name, settings, and player selection.
struct NewTournamentView: View {
    @Bindable var viewModel: NewTournamentViewModel
    
    var body: some View {
        List {
            // Tournament Name
            Section("Tournament Name") {
                TextField("e.g., Spring 2026 League", text: $viewModel.tournamentName)
                    .textContentType(.organizationName)
            }
            
            // Settings
            Section("Settings") {
                LabeledStepper(
                    title: "Weeks",
                    value: $viewModel.totalWeeks,
                    range: AppConstants.League.weeksRange
                )
                
                LabeledStepper(
                    title: "Random achievements/week",
                    value: $viewModel.randomAchievementsPerWeek,
                    range: AppConstants.League.randomAchievementsPerWeekRange
                )
            }
            
            // Players
            Section {
                ForEach(viewModel.allPlayers, id: \.id) { player in
                    PlayerRow(
                        name: player.name,
                        mode: .toggleable(
                            isOn: Binding(
                                get: { viewModel.isSelected(player) },
                                set: { _ in viewModel.togglePlayer(player) }
                            )
                        )
                    )
                }
                
                addPlayerRow
            } header: {
                HStack {
                    Text("Players")
                    Spacer()
                    Text("\(viewModel.selectedPlayerCount) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Create Button
            Section {
                PrimaryActionButton(title: "Create Tournament") {
                    viewModel.createTournament()
                }
                .accessibilityIdentifier("Submit Create Tournament")
                .disabled(!viewModel.canCreateTournament)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } footer: {
                if viewModel.selectedPlayerIds.isEmpty {
                    Text("Select at least one player to create the tournament.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("New Tournament")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    viewModel.cancel()
                } label: {
                    Text("Cancel")
                        .frame(minHeight: AppConstants.UI.minTouchTargetHeight)
                }
            }
        }
        .onAppear {
            // #region agent log
            AgentLog.write(location: "NewTournamentView.swift:onAppear", message: "onAppear", data: [:], hypothesisId: "C")
            // #endregion
            viewModel.refresh()
        }
    }
    
    // MARK: - Add Player Row
    
    @ViewBuilder
    private var addPlayerRow: some View {
        HStack {
            TextField("Add player", text: $viewModel.newPlayerName)
                .textContentType(.name)
                .submitLabel(.done)
                .onSubmit {
                    viewModel.addPlayer()
                }
            
            Button {
                viewModel.addPlayer()
            } label: {
                Text("Add")
                    .frame(minWidth: AppConstants.UI.minTouchTargetHeight, minHeight: AppConstants.UI.minTouchTargetHeight)
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.canAddPlayer)
            .accessibilityLabel("Add player")
            .accessibilityIdentifier("Add player")
        }
        .frame(minHeight: AppConstants.UI.minTouchTargetHeight)
    }
}

#Preview {
    NavigationStack {
        NewTournamentView(viewModel: NewTournamentViewModel(context: PreviewContainer.shared.mainContext))
    }
}
