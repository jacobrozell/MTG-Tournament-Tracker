import SwiftUI

/// New Achievement view - create a new achievement with name, points, and always-on setting.
struct NewAchievementView: View {
    @Bindable var viewModel: NewAchievementViewModel
    
    var body: some View {
        NavigationStack {
            List {
                // Achievement Name
                Section("Achievement Name") {
                    TextField("e.g., First Blood", text: $viewModel.name)
                        .frame(minHeight: AppConstants.UI.minTouchTargetHeight)
                        .accessibilityLabel("Achievement Name")
                        .accessibilityIdentifier("Achievement Name")
                }
                
                // Settings
                Section("Settings") {
                    LabeledStepper(
                        title: "Points",
                        value: $viewModel.points,
                        range: 0...99
                    )
                    
                    LabeledToggle(
                        title: "Always on",
                        isOn: $viewModel.alwaysOn
                    )
                }
                
                // Add Button
                Section {
                    PrimaryActionButton(title: "Add Achievement") {
                        viewModel.addAchievement()
                    }
                    .disabled(!viewModel.canAdd)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } footer: {
                    if viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Enter a name for the achievement.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("New Achievement")
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
        }
    }
}

#Preview {
    NewAchievementView(viewModel: NewAchievementViewModel(context: PreviewContainer.shared.mainContext))
}
