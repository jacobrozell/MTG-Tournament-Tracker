import SwiftUI

/// A destructive action button with iOS HIG-compliant styling.
/// Uses `role: .destructive` with 44pt minimum touch target.
struct DestructiveActionButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false
    var accessibilityLabel: String?
    
    var body: some View {
        Button(role: .destructive, action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .frame(minHeight: AppConstants.UI.minTouchTargetHeight)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isDisabled)
        .accessibilityLabel(accessibilityLabel ?? title)
    }
}

#Preview {
    VStack(spacing: 16) {
        DestructiveActionButton(title: "Delete All Data") {
            print("Tapped")
        }
        
        DestructiveActionButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
}
