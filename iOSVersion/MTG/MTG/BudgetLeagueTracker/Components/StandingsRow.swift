import SwiftUI

/// Display mode for standings row.
enum StandingsMode {
    /// Weekly standings: shows placement and achievement points
    case weekly
    
    /// Tournament standings: also shows wins
    case tournament
}

/// A row component for displaying player standings (weekly or tournament).
struct StandingsRow: View {
    let rank: Int
    let name: String
    let totalPoints: Int
    let placementPoints: Int
    let achievementPoints: Int
    var wins: Int = 0
    let mode: StandingsMode
    
    var body: some View {
        HStack {
            Text("#\(rank)")
                .font(.headline)
                .frame(minWidth: 36, alignment: .leading)
            
            Text(name)
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 8)
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(totalPoints) pts")
                    .font(.body)
                
                HStack(spacing: 4) {
                    Text("P: \(placementPoints)")
                    Text("A: \(achievementPoints)")
                    if case .tournament = mode {
                        Text("W: \(wins)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
        }
        .frame(minHeight: AppConstants.UI.minTouchTargetHeight)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
    
    private var accessibilityDescription: String {
        var description = "Rank \(rank), \(name), \(totalPoints) points"
        if case .tournament = mode {
            description += ", \(wins) wins"
        }
        return description
    }
}

#Preview("Weekly Mode") {
    List {
        StandingsRow(rank: 1, name: "Alice", totalPoints: 12, placementPoints: 8, achievementPoints: 4, mode: .weekly)
        StandingsRow(rank: 2, name: "Bob", totalPoints: 10, placementPoints: 7, achievementPoints: 3, mode: .weekly)
        StandingsRow(rank: 3, name: "Charlie", totalPoints: 8, placementPoints: 6, achievementPoints: 2, mode: .weekly)
    }
    .listStyle(.insetGrouped)
}

#Preview("Tournament Mode") {
    List {
        StandingsRow(rank: 1, name: "Alice", totalPoints: 45, placementPoints: 32, achievementPoints: 13, wins: 5, mode: .tournament)
        StandingsRow(rank: 2, name: "Bob", totalPoints: 40, placementPoints: 28, achievementPoints: 12, wins: 4, mode: .tournament)
    }
    .listStyle(.insetGrouped)
}
