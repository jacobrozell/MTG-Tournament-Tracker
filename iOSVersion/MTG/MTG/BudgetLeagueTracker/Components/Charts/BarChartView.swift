import SwiftUI
import Charts

/// A reusable bar chart component supporting single and grouped bars.
/// Uses Swift Charts for rendering.
struct BarChartView: View {
    let title: String
    let data: [BarChartData]
    let barColor: Color
    let secondaryColor: Color?
    let showLegend: Bool
    let height: CGFloat
    
    /// Creates a bar chart view.
    /// - Parameters:
    ///   - title: The chart title
    ///   - data: Array of bar chart data points
    ///   - barColor: Primary bar color
    ///   - secondaryColor: Optional secondary bar color for grouped bars
    ///   - showLegend: Whether to show the legend (default: true for grouped)
    ///   - height: Chart height (default: 200)
    init(
        title: String,
        data: [BarChartData],
        barColor: Color = .blue,
        secondaryColor: Color? = nil,
        showLegend: Bool? = nil,
        height: CGFloat = 200
    ) {
        self.title = title
        self.data = data
        self.barColor = barColor
        self.secondaryColor = secondaryColor
        self.showLegend = showLegend ?? (secondaryColor != nil)
        self.height = height
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            if data.isEmpty {
                emptyState
            } else if secondaryColor != nil {
                groupedBarChart
            } else {
                singleBarChart
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Single Bar Chart
    
    @ViewBuilder
    private var singleBarChart: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Category", item.label),
                y: .value("Value", item.primaryValue)
            )
            .foregroundStyle(barColor.gradient)
            .annotation(position: .top, alignment: .center) {
                if item.primaryValue > 0 {
                    Text("\(item.primaryValue)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: height)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
    
    // MARK: - Grouped Bar Chart
    
    @ViewBuilder
    private var groupedBarChart: some View {
        let chartData = data.flatMap { item -> [GroupedBarData] in
            var result = [GroupedBarData(
                id: "\(item.id)-primary",
                label: item.label,
                series: item.primaryLabel ?? "Primary",
                value: item.primaryValue
            )]
            if let secondary = item.secondaryValue {
                result.append(GroupedBarData(
                    id: "\(item.id)-secondary",
                    label: item.label,
                    series: item.secondaryLabel ?? "Secondary",
                    value: secondary
                ))
            }
            return result
        }
        
        Chart(chartData) { item in
            BarMark(
                x: .value("Category", item.label),
                y: .value("Value", item.value)
            )
            .foregroundStyle(by: .value("Series", item.series))
            .position(by: .value("Series", item.series))
        }
        .frame(height: height)
        .chartForegroundStyleScale([
            chartData.first?.series ?? "Primary": barColor,
            chartData.dropFirst().first(where: { $0.series != chartData.first?.series })?.series ?? "Secondary": secondaryColor ?? .gray
        ])
        .chartLegend(showLegend ? .visible : .hidden)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
    
    // MARK: - Empty State
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar")
                .font(.title)
                .foregroundStyle(.tertiary)
            Text("No data available")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Data Types

/// Data point for bar charts.
struct BarChartData: Identifiable {
    let id: String
    let label: String
    let primaryValue: Int
    let primaryLabel: String?
    let secondaryValue: Int?
    let secondaryLabel: String?
    
    /// Creates a single bar data point.
    init(id: String = UUID().uuidString, label: String, value: Int) {
        self.id = id
        self.label = label
        self.primaryValue = value
        self.primaryLabel = nil
        self.secondaryValue = nil
        self.secondaryLabel = nil
    }
    
    /// Creates a grouped bar data point.
    init(
        id: String = UUID().uuidString,
        label: String,
        primaryValue: Int,
        primaryLabel: String,
        secondaryValue: Int,
        secondaryLabel: String
    ) {
        self.id = id
        self.label = label
        self.primaryValue = primaryValue
        self.primaryLabel = primaryLabel
        self.secondaryValue = secondaryValue
        self.secondaryLabel = secondaryLabel
    }
}

/// Internal data type for grouped bar chart rendering.
private struct GroupedBarData: Identifiable {
    let id: String
    let label: String
    let series: String
    let value: Int
}

// MARK: - Convenience Initializers

extension BarChartView {
    /// Creates a bar chart from player points data.
    static func playerPoints(
        title: String = "Points Comparison",
        data: [PlayerPointsData],
        height: CGFloat = 200
    ) -> BarChartView {
        let chartData = data.map { player in
            BarChartData(
                id: player.id,
                label: player.name,
                primaryValue: player.placementPoints,
                primaryLabel: "Placement",
                secondaryValue: player.achievementPoints,
                secondaryLabel: "Achievement"
            )
        }
        
        return BarChartView(
            title: title,
            data: chartData,
            barColor: .blue,
            secondaryColor: .green,
            height: height
        )
    }
    
    /// Creates a bar chart from achievement earn data.
    static func achievementLeaderboard(
        title: String = "Achievement Leaderboard",
        data: [AchievementEarnData],
        height: CGFloat = 200
    ) -> BarChartView {
        let chartData = data.map { achievement in
            BarChartData(
                id: achievement.id,
                label: achievement.achievementName,
                value: achievement.timesEarned
            )
        }
        
        return BarChartView(
            title: title,
            data: chartData,
            barColor: .orange,
            height: height
        )
    }
    
    /// Creates a bar chart from wins comparison data.
    static func winsComparison(
        title: String = "Wins",
        data: [WinsComparisonData],
        height: CGFloat = 200
    ) -> BarChartView {
        let chartData = data.map { player in
            BarChartData(
                id: player.id,
                label: player.playerName,
                value: player.wins
            )
        }
        
        return BarChartView(
            title: title,
            data: chartData,
            barColor: .purple,
            height: height
        )
    }
    
    /// Creates a bar chart from achievement player breakdown data.
    static func playerBreakdown(
        title: String,
        data: [AchievementPlayerBreakdown],
        height: CGFloat = 150
    ) -> BarChartView {
        let chartData = data.map { item in
            BarChartData(
                id: item.id,
                label: item.playerName,
                value: item.count
            )
        }
        
        return BarChartView(
            title: title,
            data: chartData,
            barColor: .teal,
            height: height
        )
    }
}

// MARK: - Preview

#Preview("Single Bar Chart") {
    BarChartView(
        title: "Wins by Player",
        data: [
            BarChartData(label: "Alice", value: 5),
            BarChartData(label: "Bob", value: 3),
            BarChartData(label: "Carol", value: 7),
            BarChartData(label: "Dave", value: 4)
        ],
        barColor: .blue
    )
    .padding()
}

#Preview("Grouped Bar Chart") {
    BarChartView(
        title: "Points Comparison",
        data: [
            BarChartData(label: "Alice", primaryValue: 25, primaryLabel: "Placement", secondaryValue: 10, secondaryLabel: "Achievement"),
            BarChartData(label: "Bob", primaryValue: 18, primaryLabel: "Placement", secondaryValue: 15, secondaryLabel: "Achievement"),
            BarChartData(label: "Carol", primaryValue: 30, primaryLabel: "Placement", secondaryValue: 5, secondaryLabel: "Achievement")
        ],
        barColor: .blue,
        secondaryColor: .green
    )
    .padding()
}

#Preview("Empty State") {
    BarChartView(
        title: "No Data",
        data: [],
        barColor: .blue
    )
    .padding()
}
