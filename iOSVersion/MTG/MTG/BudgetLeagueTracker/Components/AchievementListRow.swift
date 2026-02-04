import SwiftUI

/// A row component for displaying an achievement in the Achievements list.
/// Shows name, points, "Always on" toggle, and remove button.
struct AchievementListRow: View {
    let name: String
    let points: Int
    @Binding var alwaysOn: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(points) pts")
                    .font(.caption)
                    .foregroundColor(AppConstants.AccessibleColors.captionText)
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            
            Spacer(minLength: 8)
            
            Toggle("Always on for \(name)", isOn: $alwaysOn)
                .labelsHidden()
                .accessibilityLabel("Always on for \(name)")
                .accessibilityIdentifier("toggle-\(name)")
            
            Button(role: .destructive, action: onRemove) {
                Image(systemName: "trash")
                    .frame(minWidth: AppConstants.UI.minTouchTargetHeight, minHeight: AppConstants.UI.minTouchTargetHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .frame(minWidth: AppConstants.UI.minTouchTargetHeight, minHeight: AppConstants.UI.minTouchTargetHeight)
            .accessibilityLabel("Remove \(name)")
        }
        .frame(minHeight: AppConstants.UI.minTouchTargetHeight)
    }
}

#Preview {
    List {
        AchievementListRow(name: "First Blood", points: 1, alwaysOn: .constant(false)) {
            print("Remove")
        }
        AchievementListRow(name: "Combo Master", points: 2, alwaysOn: .constant(true)) {
            print("Remove")
        }
    }
    .listStyle(.insetGrouped)
}
