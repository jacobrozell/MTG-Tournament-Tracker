import SwiftUI

/// Add Players view - configure players and league settings before starting.
struct AddPlayersView: View {
    @Bindable var viewModel: AddPlayersViewModel
    
    var body: some View {
        List {
            Section("Players") {
                ForEach(viewModel.players, id: \.id) { player in
                    PlayerRow(name: player.name, mode: .removable {
                        viewModel.removePlayer(player)
                    })
                }
                
                addPlayerRow
            }
            
            Section("League Settings") {
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
            
            Section {
                PrimaryActionButton(title: "Start Tournament") {
                    viewModel.startTournament()
                }
                .disabled(!viewModel.canStartTournament)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Add Players")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    viewModel.cancel()
                }
            }
        }
        .onAppear {
            viewModel.refresh()
        }
    }
    
    @ViewBuilder
    private var addPlayerRow: some View {
        HStack {
            TextField("Player name", text: $viewModel.newPlayerName)
                .textContentType(.name)
                .submitLabel(.done)
                .onSubmit {
                    viewModel.addPlayer()
                }
            
            Button("Add") {
                viewModel.addPlayer()
            }
            .disabled(viewModel.newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .frame(minHeight: AppConstants.UI.minTouchTargetHeight)
    }
}

#Preview {
    NavigationStack {
        AddPlayersView(viewModel: AddPlayersViewModel(context: PreviewContainer.shared.mainContext))
    }
}
