import SwiftUI

/// Defines the different display modes for PlayerRow.
enum PlayerRowMode {
    /// Display only: shows name and optional subtitle (e.g., for Stats view)
    case display(subtitle: String?)
    
    /// With remove button: shows name and a trash button (e.g., for Add Players view)
    case removable(onRemove: () -> Void)
    
    /// With toggle: shows name and a toggle for present/absent (e.g., for Attendance view)
    case toggleable(isOn: Binding<Bool>)
}

/// A versatile player row component used across multiple views.
/// Supports display, removable, and toggleable modes.
struct PlayerRow: View {
    let name: String
    let mode: PlayerRowMode
    
    var body: some View {
        HStack {
            switch mode {
            case .display(let subtitle):
                displayContent(subtitle: subtitle)
                
            case .removable(let onRemove):
                removableContent(onRemove: onRemove)
                
            case .toggleable(let isOn):
                toggleableContent(isOn: isOn)
            }
        }
        .frame(minHeight: AppConstants.UI.minTouchTargetHeight)
    }
    
    @ViewBuilder
    private func displayContent(subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppConstants.AccessibleColors.captionText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        Spacer(minLength: 8)
    }
    
    @ViewBuilder
    private func removableContent(onRemove: @escaping () -> Void) -> some View {
        Text(name)
            .font(.body)
        Spacer()
        Button(role: .destructive, action: onRemove) {
            Image(systemName: "trash")
        }
        .accessibilityLabel("Remove \(name)")
    }
    
    @ViewBuilder
    private func toggleableContent(isOn: Binding<Bool>) -> some View {
        Toggle(name, isOn: isOn)
            .accessibilityLabel("Mark \(name) as present")
    }
}

// MARK: - Preview

#Preview("Display Mode") {
    List {
        PlayerRow(name: "Alice", mode: .display(subtitle: "Wins: 3, Placement: 12, Achievements: 5"))
        PlayerRow(name: "Bob", mode: .display(subtitle: nil))
    }
    .listStyle(.insetGrouped)
}

#Preview("Removable Mode") {
    List {
        PlayerRow(name: "Alice", mode: .removable(onRemove: { print("Remove Alice") }))
        PlayerRow(name: "Bob", mode: .removable(onRemove: { print("Remove Bob") }))
    }
    .listStyle(.insetGrouped)
}

#Preview("Toggleable Mode") {
    List {
        PlayerRow(name: "Alice", mode: .toggleable(isOn: .constant(true)))
        PlayerRow(name: "Bob", mode: .toggleable(isOn: .constant(false)))
    }
    .listStyle(.insetGrouped)
}
