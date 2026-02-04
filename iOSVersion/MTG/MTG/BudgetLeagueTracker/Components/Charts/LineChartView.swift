import SwiftUI
import Charts

/// A reusable line chart component supporting single and multi-series data.
/// Uses Swift Charts for rendering.
struct LineChartView: View {
    let title: String
    let data: [LineChartData]
    let lineColor: Color
    let showPoints: Bool
    let showArea: Bool
    let height: CGFloat
    
    /// Creates a line chart view.
    /// - Parameters:
    ///   - title: The chart title
    ///   - data: Array of line chart data points
    ///   - lineColor: Primary line color (used for single series)
    ///   - showPoints: Whether to show data points (default: true)
    ///   - showArea: Whether to show area fill under the line (default: false)
    ///   - height: Chart height (default: 200)
    init(
        title: String,
        data: [LineChartData],
        lineColor: Color = .blue,
        showPoints: Bool = true,
        showArea: Bool = false,
        height: CGFloat = 200
    ) {
        self.title = title
        self.data = data
        self.lineColor = lineColor
        self.showPoints = showPoints
        self.showArea = showArea
        self.height = height
    }
    
    private var isMultiSeries: Bool {
        Set(data.map { $0.series }).count > 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            if data.isEmpty {
                emptyState
            } else if isMultiSeries {
                multiSeriesChart
            } else {
                singleSeriesChart
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Single Series Chart
    
    @ViewBuilder
    private var singleSeriesChart: some View {
        Chart(data) { item in
            LineMark(
                x: .value("Week", item.xValue),
                y: .value("Points", item.yValue)
            )
            .foregroundStyle(lineColor.gradient)
            .interpolationMethod(.catmullRom)
            
            if showArea {
                AreaMark(
                    x: .value("Week", item.xValue),
                    y: .value("Points", item.yValue)
                )
                .foregroundStyle(lineColor.opacity(0.1).gradient)
                .interpolationMethod(.catmullRom)
            }
            
            if showPoints {
                PointMark(
                    x: .value("Week", item.xValue),
                    y: .value("Points", item.yValue)
                )
                .foregroundStyle(lineColor)
                .symbolSize(30)
            }
        }
        .frame(height: height)
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("W\(intValue)")
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
    
    // MARK: - Multi Series Chart
    
    @ViewBuilder
    private var multiSeriesChart: some View {
        Chart(data) { item in
            LineMark(
                x: .value("Week", item.xValue),
                y: .value("Points", item.yValue)
            )
            .foregroundStyle(by: .value("Player", item.series))
            .interpolationMethod(.catmullRom)
            
            if showPoints {
                PointMark(
                    x: .value("Week", item.xValue),
                    y: .value("Points", item.yValue)
                )
                .foregroundStyle(by: .value("Player", item.series))
                .symbolSize(30)
            }
        }
        .frame(height: height)
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("W\(intValue)")
                    }
                }
            }
        }
        .chartLegend(.visible)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
    
    // MARK: - Empty State
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
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

/// Data point for line charts.
struct LineChartData: Identifiable {
    let id: String
    let series: String
    let xValue: Int
    let yValue: Int
    
    /// Creates a line chart data point.
    init(id: String = UUID().uuidString, series: String = "Default", xValue: Int, yValue: Int) {
        self.id = id
        self.series = series
        self.xValue = xValue
        self.yValue = yValue
    }
}

// MARK: - Convenience Initializers

extension LineChartView {
    /// Creates a line chart from performance trend data.
    static func performanceTrend(
        title: String = "Performance Trend",
        data: [PerformanceTrendData],
        showPoints: Bool = true,
        showArea: Bool = false,
        height: CGFloat = 200
    ) -> LineChartView {
        let chartData = data.map { trend in
            LineChartData(
                id: trend.id,
                series: trend.playerName,
                xValue: trend.week,
                yValue: trend.cumulativePoints
            )
        }
        
        return LineChartView(
            title: title,
            data: chartData,
            lineColor: .blue,
            showPoints: showPoints,
            showArea: showArea,
            height: height
        )
    }
    
    /// Creates a single-player performance trend chart.
    static func singlePlayerTrend(
        title: String,
        playerName: String,
        weeklyPoints: [(week: Int, points: Int)],
        color: Color = .blue,
        showArea: Bool = true,
        height: CGFloat = 200
    ) -> LineChartView {
        // Calculate cumulative points
        var cumulative = 0
        let chartData = weeklyPoints.map { week, points -> LineChartData in
            cumulative += points
            return LineChartData(
                series: playerName,
                xValue: week,
                yValue: cumulative
            )
        }
        
        return LineChartView(
            title: title,
            data: chartData,
            lineColor: color,
            showPoints: true,
            showArea: showArea,
            height: height
        )
    }
    
    /// Creates a multi-player comparison trend chart.
    static func multiPlayerTrend(
        title: String = "Player Comparison",
        playerData: [(name: String, weeklyPoints: [(week: Int, points: Int)])],
        height: CGFloat = 250
    ) -> LineChartView {
        var chartData: [LineChartData] = []
        
        for (playerName, weeklyPoints) in playerData {
            var cumulative = 0
            for (week, points) in weeklyPoints {
                cumulative += points
                chartData.append(LineChartData(
                    series: playerName,
                    xValue: week,
                    yValue: cumulative
                ))
            }
        }
        
        return LineChartView(
            title: title,
            data: chartData,
            lineColor: .blue,
            showPoints: true,
            showArea: false,
            height: height
        )
    }
}

// MARK: - Preview

#Preview("Single Series") {
    LineChartView(
        title: "Points Over Time",
        data: [
            LineChartData(xValue: 1, yValue: 10),
            LineChartData(xValue: 2, yValue: 25),
            LineChartData(xValue: 3, yValue: 35),
            LineChartData(xValue: 4, yValue: 50),
            LineChartData(xValue: 5, yValue: 62)
        ],
        lineColor: .blue,
        showArea: true
    )
    .padding()
}

#Preview("Multi Series") {
    LineChartView(
        title: "Player Comparison",
        data: [
            LineChartData(series: "Alice", xValue: 1, yValue: 10),
            LineChartData(series: "Alice", xValue: 2, yValue: 25),
            LineChartData(series: "Alice", xValue: 3, yValue: 40),
            LineChartData(series: "Bob", xValue: 1, yValue: 8),
            LineChartData(series: "Bob", xValue: 2, yValue: 20),
            LineChartData(series: "Bob", xValue: 3, yValue: 35),
            LineChartData(series: "Carol", xValue: 1, yValue: 12),
            LineChartData(series: "Carol", xValue: 2, yValue: 22),
            LineChartData(series: "Carol", xValue: 3, yValue: 38)
        ]
    )
    .padding()
}

#Preview("Empty State") {
    LineChartView(
        title: "No Data",
        data: []
    )
    .padding()
}
