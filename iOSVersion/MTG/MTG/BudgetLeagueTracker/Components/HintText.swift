import SwiftUI

/// A small hint or validation message displayed below controls.
/// Uses accessible colors that meet WCAG 2.1 AA contrast requirements.
struct HintText: View {
    let message: String
    var accessibilityLabel: String?
    
    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundColor(AppConstants.AccessibleColors.hintText)
            .accessibilityLabel(accessibilityLabel ?? message)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        HintText(message: "Add at least one player to start")
        HintText(message: "Undo is disabled because no pods have been saved")
    }
    .padding()
}
