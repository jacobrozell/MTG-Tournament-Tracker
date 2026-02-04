import SwiftUI

/// Attendance view - record who is present and weekly settings.
struct AttendanceView: View {
    @Bindable var viewModel: AttendanceViewModel
    /// When non-nil, called after confirming attendance (e.g. to dismiss a sheet and refresh).
    var onConfirm: (() -> Void)? = nil
    
    var body: some View {
        List {
            Section("This Week") {
                LabeledToggle(
                    title: "Count achievements this week",
                    isOn: $viewModel.achievementsOnThisWeek
                )
            }
            
            Section("Players") {
                ForEach(viewModel.players, id: \.id) { player in
                    PlayerRow(
                        name: player.name,
                        mode: .toggleable(isOn: Binding(
                            get: { viewModel.isPresent(player.id) },
                            set: { _ in viewModel.togglePresence(for: player.id) }
                        ))
                    )
                }
                
                addPlayerRow
            }
            
            Section {
                PrimaryActionButton(title: "Confirm Attendance") {
                    viewModel.confirmAttendance()
                    onConfirm?()
                }
                .disabled(!viewModel.canConfirmAttendance)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Attendance – Week \(viewModel.currentWeek)")
        .onAppear {
            viewModel.refresh()
        }
    }
    
    @ViewBuilder
    private var addPlayerRow: some View {
        HStack {
            TextField("Add player this week", text: $viewModel.newPlayerName)
                .textContentType(.name)
                .submitLabel(.done)
                .onSubmit {
                    viewModel.addWeeklyPlayer()
                }
            
            Button("Add") {
                viewModel.addWeeklyPlayer()
            }
            .disabled(viewModel.newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .frame(minHeight: AppConstants.UI.minTouchTargetHeight)
    }
}

#Preview {
    NavigationStack {
        AttendanceView(
            viewModel: AttendanceViewModel(context: PreviewContainer.shared.mainContext),
            onConfirm: nil
        )
    }
}
