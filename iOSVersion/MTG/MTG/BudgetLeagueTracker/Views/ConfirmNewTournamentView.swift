import SwiftUI

/// Legacy Confirm New Tournament view - redirects to NewTournamentView.
/// Kept for backwards compatibility.
struct ConfirmNewTournamentView: View {
    @Bindable var viewModel: ConfirmNewTournamentViewModel
    
    var body: some View {
        NewTournamentView(viewModel: NewTournamentViewModel(context: viewModel.context))
    }
}

#Preview {
    NavigationStack {
        ConfirmNewTournamentView(viewModel: ConfirmNewTournamentViewModel(context: PreviewContainer.shared.mainContext))
    }
}
