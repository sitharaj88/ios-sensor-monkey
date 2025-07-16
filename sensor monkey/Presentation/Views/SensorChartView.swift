//
//  SensorChartView.swift
//  sensor monkey
//
//  Created by Sitharaj Seenivasan on 16/07/25.
//

import SwiftUI
import Charts

struct SensorChartView: View {
    let data: [DataPoint]
    let sensorType: SensorType
    let timeRange: TimeRange
    
    private var filteredData: [DataPoint] {
        let cutoffDate = Date().addingTimeInterval(-timeRange.timeInterval)
        return data.filter { $0.timestamp >= cutoffDate }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if filteredData.isEmpty {
                EmptyChartView()
            } else {
                Chart {
                    ForEach(filteredData) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(chartColor)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        AreaMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(chartColor.opacity(0.2))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(formatAxisLabel(date))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(String(format: "%.1f", doubleValue))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 180)
                .padding()
                .accessibilityLabel("Chart showing \(sensorType.rawValue) data over time")
                .accessibilityValue("Data points: \(filteredData.count)")
            }
            
            // Chart statistics
            chartStatistics
        }
    }
    
    private var chartColor: Color {
        switch sensorType {
        case .accelerometer: return .blue
        case .gyroscope: return .green
        case .magnetometer: return .purple
        case .barometer: return .orange
        case .lightSensor: return .yellow
        case .proximity: return .red
        }
    }
    
    private var chartStatistics: some View {
        HStack {
            StatisticView(title: "Min", value: minValue, unit: sensorType.unit)
            Spacer()
            StatisticView(title: "Max", value: maxValue, unit: sensorType.unit)
            Spacer()
            StatisticView(title: "Avg", value: avgValue, unit: sensorType.unit)
            Spacer()
            StatisticView(title: "Points", value: String(filteredData.count), unit: "")
        }
        .padding(.horizontal)
    }
    
    private var minValue: String {
        guard let min = filteredData.map(\.value).min() else { return "N/A" }
        return String(format: "%.2f", min)
    }
    
    private var maxValue: String {
        guard let max = filteredData.map(\.value).max() else { return "N/A" }
        return String(format: "%.2f", max)
    }
    
    private var avgValue: String {
        guard !filteredData.isEmpty else { return "N/A" }
        let sum = filteredData.map(\.value).reduce(0, +)
        return String(format: "%.2f", sum / Double(filteredData.count))
    }
    
    private func formatAxisLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch timeRange {
        case .lastMinute, .lastFiveMinutes:
            formatter.timeStyle = .short
        case .lastHour:
            formatter.dateFormat = "HH:mm"
        case .lastDay:
            formatter.dateFormat = "HH:mm"
        }
        return formatter.string(from: date)
    }
}

struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No Data Available")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Start monitoring to see real-time data")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("No chart data available")
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) \(unit)")
    }
}