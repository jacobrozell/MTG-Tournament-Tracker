import SwiftUI

/// A toggle control with a label, ensuring 44pt minimum touch target.
struct LabeledToggle: View {
    let title: String
    @Binding var isOn: Bool
    var accessibilityLabel: String?
    
    var body: some View {
        Toggle(title, isOn: $isOn)
            .frame(minHeight: AppConstants.UI.minTouchTargetHeight)
            .accessibilityLabel(accessibilityLabel ?? title)
    }
}

#Preview {
    List {
        LabeledToggle(title: "Count achievements this week", isOn: .constant(true))
        LabeledToggle(title: "Always on", isOn: .constant(false))
    }
    .listStyle(.insetGrouped)
}
