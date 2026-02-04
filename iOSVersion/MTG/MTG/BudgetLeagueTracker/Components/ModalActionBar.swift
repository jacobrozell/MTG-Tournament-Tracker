import SwiftUI

/// A vertical stack of action buttons for sheet/fullScreenCover modals.
struct ModalActionBar: View {
    let primaryTitle: String
    let primaryAction: () -> Void
    var secondaryTitle: String?
    var secondaryAction: (() -> Void)?
    var isPrimaryDisabled: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            PrimaryActionButton(
                title: primaryTitle,
                action: primaryAction,
                isDisabled: isPrimaryDisabled
            )
            
            if let secondaryTitle = secondaryTitle,
               let secondaryAction = secondaryAction {
                SecondaryButton(
                    title: secondaryTitle,
                    action: secondaryAction
                )
            }
        }
        .padding()
    }
}

#Preview("With Secondary") {
    ModalActionBar(
        primaryTitle: "Continue to Next Week",
        primaryAction: { print("Continue") },
        secondaryTitle: "Exit Standings",
        secondaryAction: { print("Exit") }
    )
}

#Preview("Primary Only") {
    ModalActionBar(
        primaryTitle: "Close",
        primaryAction: { print("Close") }
    )
}
