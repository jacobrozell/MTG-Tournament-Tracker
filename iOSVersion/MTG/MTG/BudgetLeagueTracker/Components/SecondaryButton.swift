import SwiftUI

/// A secondary action button with iOS HIG-compliant styling.
/// Uses `.bordered` style with 44pt minimum touch target.
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false
    var accessibilityLabel: String?
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .frame(minHeight: AppConstants.UI.minTouchTargetHeight)
        }
        .buttonStyle(.bordered)
        .disabled(isDisabled)
        .accessibilityLabel(accessibilityLabel ?? title)
    }
}

#Preview {
    VStack(spacing: 16) {
        SecondaryButton(title: "Cancel") {
            print("Tapped")
        }
        
        SecondaryButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
}
