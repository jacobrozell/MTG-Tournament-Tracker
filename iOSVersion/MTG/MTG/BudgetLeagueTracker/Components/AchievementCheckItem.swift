import SwiftUI

/// A toggle item for checking an achievement, showing name and points.
/// Used in the Pods view for each active achievement per player.
struct AchievementCheckItem: View {
    let name: String
    let points: Int
    @Binding var isChecked: Bool
    var isDisabled: Bool = false
    
    var body: some View {
        Toggle(isOn: $isChecked) {
            HStack {
                Text(name)
                    .font(.body)
                Text("+\(points)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: AppConstants.UI.minTouchTargetHeight)
        .disabled(isDisabled)
        .accessibilityLabel("\(name), \(points) points")
        .accessibilityValue(isChecked ? "checked" : "unchecked")
    }
}

#Preview {
    List {
        AchievementCheckItem(name: "First Blood", points: 1, isChecked: .constant(true))
        AchievementCheckItem(name: "Combo Master", points: 2, isChecked: .constant(false))
        AchievementCheckItem(name: "Disabled", points: 1, isChecked: .constant(false), isDisabled: true)
    }
    .listStyle(.insetGrouped)
}
