import SwiftUI

/// A view displayed when there's no content to show.
/// Displays a message and optional hint text.
struct EmptyStateView: View {
    let message: String
    var hint: String?
    
    var body: some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            if let hint = hint {
                Text(hint)
                    .font(.caption)
                    .foregroundColor(AppConstants.AccessibleColors.hintText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 32) {
        EmptyStateView(message: "No players yet")
        
        EmptyStateView(
            message: "No stats yet",
            hint: "Add players and run pods to see stats."
        )
    }
}
