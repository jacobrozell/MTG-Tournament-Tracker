import SwiftUI
import Charts

/// Style options for pie charts.
enum PieStyle {
    case pie
    case donut
}

/// A reusable pie/donut chart component.
/// Uses Swift Charts for rendering.
struct PieChartView: View {
    let title: String
    let data: [PieChartData]
    let style: PieStyle
    let showLegend: Bool
    let showLabels: Bool
    let height: CGFloat
    
    private var total: Int {
        data.reduce(0) { $0 + $1.value }
    }
    
    /// Creates a pie chart view.
    /// - Parameters:
    ///   - title: The chart title
    ///   - data: Array of pie chart data points
    ///   - style: Pie or donut style (default: .donut)
    ///   - showLegend: Whether to show the legend (default: true)
    ///   - showLabels: Whether to show percentage labels on slices (default: true)
    ///   - height: Chart height (default: 200)
    init(
        title: String,
        data: [PieChartData],
        style: PieStyle = .donut,
        showLegend: Bool = true,
        showLabels: Bool = true,
        height: CGFloat = 200
    ) {
        self.title = title
        self.data = data
        self.style = style
        self.showLegend = showLegend
        self.showLabels = showLabels
        self.height = height
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            if data.isEmpty || total == 0 {
                emptyState
            } else {
                chartContent
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Chart Content
    
    @ViewBuilder
    private var chartContent: some View {
        HStack(spacing: 16) {
            // Chart
            ZStack {
                Chart(data) { item in
                    SectorMark(
                        angle: .value("Value", item.value),
                        innerRadius: style == .donut ? .ratio(0.5) : .ratio(0),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Category", item.label))
                    .cornerRadius(4)
                }
                .frame(width: height, height: height)
                .chartLegend(.hidden)
                
                // Center label for donut
                if style == .donut {
                    VStack(spacing: 2) {
                        Text("\(total)")
                            .font(.title2.bold())
                        Text("Total")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Legend
            if showLegend {
                legendView
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
    
    // MARK: - Legend View
    
    @ViewBuilder
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(data) { item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(item.color ?? .gray)
                        .frame(width: 10, height: 10)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.label)
                            .font(.caption)
                            .foregroundStyle(.primary)
                        
                        HStack(spacing: 4) {
                            Text("\(item.value)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            if showLabels && total > 0 {
                                Text("(\(percentage(for: item.value))%)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.pie")
                .font(.title)
                .foregroundStyle(.tertiary)
            Text("No data available")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helpers
    
    private func percentage(for value: Int) -> Int {
        guard total > 0 else { return 0 }
        return Int(round(Double(value) / Double(total) * 100))
    }
}

// MARK: - Data Types

/// Data point for pie charts.
struct PieChartData: Identifiable {
    let id: String
    let label: String
    let value: Int
    let color: Color?
    
    /// Creates a pie chart data point.
    init(id: String = UUID().uuidString, label: String, value: Int, color: Color? = nil) {
        self.id = id
        self.label = label
        self.value = value
        self.color = color
    }
}

// MARK: - Convenience Initializers

extension PieChartView {
    /// Default placement colors for consistency.
    static let placementColors: [Int: Color] = [
        1: .yellow,
        2: .gray,
        3: .orange,
        4: .brown
    ]
    
    /// Creates a pie chart from placement distribution data.
    static func placementDistribution(
        title: String = "Placement Distribution",
        data: [PlacementData],
        style: PieStyle = .donut,
        height: CGFloat = 180
    ) -> PieChartView {
        let chartData = data.map { placement in
            PieChartData(
                id: placement.id,
                label: placement.label,
                value: placement.count,
                color: placementColors[placement.placement]
            )
        }
        
        return PieChartView(
            title: title,
            data: chartData,
            style: style,
            height: height
        )
    }
    
    /// Creates a pie chart from points breakdown data.
    static func pointsBreakdown(
        title: String = "Points Breakdown",
        placementPoints: Int,
        achievementPoints: Int,
        style: PieStyle = .donut,
        height: CGFloat = 180
    ) -> PieChartView {
        let chartData = [
            PieChartData(id: "placement", label: "Placement", value: placementPoints, color: .blue),
            PieChartData(id: "achievement", label: "Achievement", value: achievementPoints, color: .green)
        ]
        
        return PieChartView(
            title: title,
            data: chartData,
            style: style,
            height: height
        )
    }
    
    /// Creates a pie chart from achievement distribution data.
    static func achievementDistribution(
        title: String = "Achievement Distribution",
        data: [AchievementEarnData],
        style: PieStyle = .pie,
        height: CGFloat = 200
    ) -> PieChartView {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .teal, .indigo, .mint]
        
        let chartData = data.enumerated().map { index, achievement in
            PieChartData(
                id: achievement.id,
                label: achievement.achievementName,
                value: achievement.timesEarned,
                color: colors[index % colors.count]
            )
        }
        
        return PieChartView(
            title: title,
            data: chartData,
            style: style,
            height: height
        )
    }
}

// MARK: - Preview

#Preview("Donut Chart") {
    PieChartView(
        title: "Placement Distribution",
        data: [
            PieChartData(label: "1st", value: 5, color: .yellow),
            PieChartData(label: "2nd", value: 8, color: .gray),
            PieChartData(label: "3rd", value: 6, color: .orange),
            PieChartData(label: "4th", value: 3, color: .brown)
        ],
        style: .donut
    )
    .padding()
}

#Preview("Pie Chart") {
    PieChartView(
        title: "Points Breakdown",
        data: [
            PieChartData(label: "Placement", value: 45, color: .blue),
            PieChartData(label: "Achievement", value: 20, color: .green)
        ],
        style: .pie
    )
    .padding()
}

#Preview("Empty State") {
    PieChartView(
        title: "No Data",
        data: []
    )
    .padding()
}
