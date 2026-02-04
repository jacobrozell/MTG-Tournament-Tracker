import SwiftUI

/// A cell displaying tournament information in a list.
/// Shows different information based on tournament status.
struct TournamentCell: View {
    let tournament: Tournament
    let playerCount: Int
    let winnerName: String?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tournament.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            
            Spacer(minLength: 8)
            
            if tournament.status == .ongoing {
                statusBadge
            }
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(minHeight: AppConstants.UI.minTouchTargetHeight)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tournament.name), \(subtitle)")
    }
    
    // MARK: - Subtitle
    
    private var subtitle: String {
        switch tournament.status {
        case .ongoing:
            return "Week \(tournament.currentWeek) of \(tournament.totalWeeks) • \(playerCount) players"
        case .completed:
            if let winner = winnerName {
                return "Winner: \(winner) • \(tournament.totalWeeks) weeks"
            } else {
                return "\(tournament.totalWeeks) weeks • \(tournament.dateRangeString)"
            }
        }
    }
    
    // MARK: - Status Badge
    
    @ViewBuilder
    private var statusBadge: some View {
        Text("Active")
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.2))
            .foregroundStyle(Color(UIColor.systemGreen))
            .clipShape(Capsule())
            .accessibilityLabel("Tournament status: Active")
    }
}

#Preview("Ongoing Tournament") {
    List {
        TournamentCell(
            tournament: Tournament(
                name: "Spring 2026 League",
                totalWeeks: 8,
                currentWeek: 3
            ),
            playerCount: 12,
            winnerName: nil
        )
    }
}

#Preview("Completed Tournament") {
    List {
        TournamentCell(
            tournament: Tournament(
                name: "Winter 2025 League",
                totalWeeks: 6,
                status: .completed
            ),
            playerCount: 10,
            winnerName: "Alice"
        )
    }
}
