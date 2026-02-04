import SwiftUI
import Charts

/// A reusable card component showing achievement statistics with optional mini-chart.
/// Used in both StatsView and AchievementsView for consistent display.
struct AchievementStatsCard: View {
    let achievementName: String
    let achievementPoints: Int
    let totalEarned: Int
    let topEarners: [(playerName: String, count: Int)]
    let isAlwaysOn: Bool
    let showDetailedBreakdown: Bool
    let onToggleAlwaysOn: (() -> Void)?
    let onRemove: (() -> Void)?
    
    @State private var isExpanded: Bool = false
    
    /// Creates an achievement stats card.
    /// - Parameters:
    ///   - achievementName: Name of the achievement
    ///   - achievementPoints: Points value of the achievement
    ///   - totalEarned: Total times this achievement has been earned
    ///   - topEarners: Top earners with their counts
    ///   - isAlwaysOn: Whether the achievement is always on
    ///   - showDetailedBreakdown: Whether to show expandable breakdown
    ///   - onToggleAlwaysOn: Optional callback for toggling always on
    ///   - onRemove: Optional callback for removing the achievement
    init(
        achievementName: String,
        achievementPoints: Int,
        totalEarned: Int,
        topEarners: [(playerName: String, count: Int)],
        isAlwaysOn: Bool = false,
        showDetailedBreakdown: Bool = true,
        onToggleAlwaysOn: (() -> Void)? = nil,
        onRemove: (() -> Void)? = nil
    ) {
        self.achievementName = achievementName
        self.achievementPoints = achievementPoints
        self.totalEarned = totalEarned
        self.topEarners = topEarners
        self.isAlwaysOn = isAlwaysOn
        self.showDetailedBreakdown = showDetailedBreakdown
        self.onToggleAlwaysOn = onToggleAlwaysOn
        self.onRemove = onRemove
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            headerView
            
            // Stats Summary
            statsSummary
            
            // Top Earners Mini Bar
            if !topEarners.isEmpty {
                topEarnersView
            }
            
            // Expandable Breakdown
            if showDetailedBreakdown && !topEarners.isEmpty {
                expandableBreakdown
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Header View
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(achievementName)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Label("\(achievementPoints) pts", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if isAlwaysOn {
                        Text("Always On")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            if onToggleAlwaysOn != nil || onRemove != nil {
                Menu {
                    if let toggle = onToggleAlwaysOn {
                        Button {
                            toggle()
                        } label: {
                            Label(isAlwaysOn ? "Disable Always On" : "Enable Always On", 
                                  systemImage: isAlwaysOn ? "toggle.off" : "toggle.on")
                        }
                    }
                    
                    if let remove = onRemove {
                        Button(role: .destructive) {
                            remove()
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Stats Summary
    
    @ViewBuilder
    private var statsSummary: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Times Earned")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(totalEarned)")
                    .font(.title2.bold())
                    .foregroundStyle(totalEarned > 0 ? .primary : .tertiary)
            }
            
            if !topEarners.isEmpty {
                Divider()
                    .frame(height: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Top Earner")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(topEarners.first?.playerName ?? "-")
                        .font(.subheadline.bold())
                    Text("\(topEarners.first?.count ?? 0) times")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Top Earners Mini Bar
    
    @ViewBuilder
    private var topEarnersView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Top Earners")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Mini horizontal bar chart
            HStack(spacing: 4) {
                ForEach(Array(topEarners.prefix(5).enumerated()), id: \.offset) { index, earner in
                    VStack(spacing: 2) {
                        // Bar
                        GeometryReader { geometry in
                            let maxCount = topEarners.first?.count ?? 1
                            let barHeight = CGFloat(earner.count) / CGFloat(maxCount) * geometry.size.height
                            
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(barColor(for: index).gradient)
                                    .frame(height: max(barHeight, 4))
                            }
                        }
                        .frame(height: 40)
                        
                        // Label
                        Text(abbreviate(earner.playerName))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    // MARK: - Expandable Breakdown
    
    @ViewBuilder
    private var expandableBreakdown: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(topEarners.enumerated()), id: \.offset) { index, earner in
                    HStack {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(earner.playerName)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(earner.count)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            Text("View all \(topEarners.count) earners")
                .font(.caption)
                .foregroundStyle(.blue)
        }
    }
    
    // MARK: - Helpers
    
    private func barColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink]
        return colors[index % colors.count]
    }
    
    private func abbreviate(_ name: String) -> String {
        if name.count <= 6 {
            return name
        }
        return String(name.prefix(5)) + "…"
    }
}

// MARK: - Compact Variant

/// A more compact version of the achievement stats card for list rows.
struct AchievementStatsRow: View {
    let achievementName: String
    let achievementPoints: Int
    let totalEarned: Int
    let topEarners: [(playerName: String, count: Int)]
    let isAlwaysOn: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header Row
            HStack {
                Text(achievementName)
                    .font(.headline)
                
                Spacer()
                
                Text("\(achievementPoints) pts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if isAlwaysOn {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            
            // Stats Row
            HStack {
                Label("Earned \(totalEarned)×", systemImage: "trophy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let top = topEarners.first {
                    Text("Top: \(top.playerName) (\(top.count))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            // Mini earners display
            if !topEarners.isEmpty {
                HStack(spacing: 4) {
                    ForEach(Array(topEarners.prefix(3).enumerated()), id: \.offset) { index, earner in
                        HStack(spacing: 2) {
                            Circle()
                                .fill(earnerColor(for: index))
                                .frame(width: 6, height: 6)
                            Text("\(earner.playerName) (\(earner.count))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        if index < min(2, topEarners.count - 1) {
                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(.quaternary)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func earnerColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .orange
        default: return .secondary
        }
    }
}

// MARK: - Preview

#Preview("Stats Card") {
    VStack(spacing: 16) {
        AchievementStatsCard(
            achievementName: "First Blood",
            achievementPoints: 1,
            totalEarned: 42,
            topEarners: [
                (playerName: "Alice", count: 12),
                (playerName: "Bob", count: 10),
                (playerName: "Carol", count: 8),
                (playerName: "Dave", count: 7),
                (playerName: "Eve", count: 5)
            ],
            isAlwaysOn: true
        )
        
        AchievementStatsCard(
            achievementName: "Combo King",
            achievementPoints: 2,
            totalEarned: 0,
            topEarners: [],
            isAlwaysOn: false
        )
    }
    .padding()
}

#Preview("Stats Row") {
    List {
        AchievementStatsRow(
            achievementName: "First Blood",
            achievementPoints: 1,
            totalEarned: 42,
            topEarners: [
                (playerName: "Alice", count: 12),
                (playerName: "Bob", count: 10),
                (playerName: "Carol", count: 8)
            ],
            isAlwaysOn: true
        )
        
        AchievementStatsRow(
            achievementName: "Mill Victory",
            achievementPoints: 3,
            totalEarned: 5,
            topEarners: [
                (playerName: "Dave", count: 3),
                (playerName: "Eve", count: 2)
            ],
            isAlwaysOn: false
        )
    }
}
