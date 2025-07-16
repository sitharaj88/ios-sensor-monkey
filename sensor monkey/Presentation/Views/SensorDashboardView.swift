//
//  SensorDashboardView.swift
//  sensor monkey
//
//  Created by Sitharaj Seenivasan on 16/07/25.
//

import SwiftUI
import Charts

struct SensorDashboardView: View {
    @StateObject private var viewModel = SensorDashboardViewModel()
    @State private var selectedTimeRange: TimeRange = .lastHour
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header with app status
                    headerSection
                    
                    // Quick actions
                    quickActionsSection
                    
                    // Active sensors grid
                    activeSensorsGrid
                    
                    // Chart section
                    if viewModel.selectedSensor != nil {
                        chartSection
                    }
                }
                .padding()
            }
            .navigationTitle("Sensor Monitor")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showingSettings = true
                    }) {
                        Image(systemName: "gear")
                            .foregroundColor(.primary)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                SensorSettingsView(viewModel: viewModel)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Active Sensors")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("\(viewModel.activeSensorTypes.count) of \(viewModel.availableSensors.count) sensors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusIndicator(isActive: !viewModel.activeSensorTypes.isEmpty)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var quickActionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.availableSensors) { sensorType in
                    QuickActionButton(
                        sensorType: sensorType,
                        isActive: viewModel.isMonitoring(sensorType),
                        isCalibrating: viewModel.isCalibrating[sensorType] ?? false,
                        action: {
                            viewModel.toggleSensorMonitoring(for: sensorType)
                        },
                        calibrateAction: {
                            viewModel.calibrateSensor(sensorType)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var activeSensorsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            ForEach(viewModel.activeSensorTypes) { sensorType in
                SensorCardView(
                    sensorType: sensorType,
                    data: viewModel.activeSensors[sensorType],
                    isSelected: viewModel.selectedSensor == sensorType,
                    onTap: {
                        viewModel.selectSensor(sensorType)
                    }
                )
            }
        }
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let selectedSensor = viewModel.selectedSensor {
                HStack {
                    Text("\(selectedSensor.rawValue) History")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                SensorChartView(
                    data: viewModel.historicalData[selectedSensor] ?? [],
                    sensorType: selectedSensor,
                    timeRange: selectedTimeRange
                )
                .frame(height: 200)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Supporting Views
struct StatusIndicator: View {
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.green : Color.red)
                .frame(width: 8, height: 8)
                .scaleEffect(isActive ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(), value: isActive)
            
            Text(isActive ? "Active" : "Inactive")
                .font(.caption)
                .fontWeight(.medium)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status: \(isActive ? "Active" : "Inactive")")
    }
}

struct QuickActionButton: View {
    let sensorType: SensorType
    let isActive: Bool
    let isCalibrating: Bool
    let action: () -> Void
    let calibrateAction: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                VStack(spacing: 4) {
                    Image(systemName: sensorType.icon)
                        .font(.title2)
                        .foregroundColor(isActive ? .white : sensorType.swiftUIColor)
                    
                    Text(sensorType.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isActive ? .white : sensorType.swiftUIColor)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 80, height: 60)
                .background(isActive ? sensorType.swiftUIColor : Color(.systemGray5))
                .cornerRadius(12)
            }
            .accessibilityLabel("\(sensorType.rawValue) sensor")
            .accessibilityValue(isActive ? "Active" : "Inactive")
            .accessibilityHint("Tap to toggle sensor monitoring")
            
            Button(action: calibrateAction) {
                HStack(spacing: 4) {
                    if isCalibrating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "target")
                            .font(.caption)
                    }
                    Text("Calibrate")
                        .font(.caption2)
                }
                .foregroundColor(sensorType.swiftUIColor)
            }
            .disabled(isCalibrating)
            .accessibilityLabel("Calibrate \(sensorType.rawValue)")
        }
    }
}

struct SensorCardView: View {
    let sensorType: SensorType
    let data: SensorData?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: sensorType.icon)
                        .font(.title2)
                        .foregroundColor(sensorType.swiftUIColor)
                    
                    Spacer()
                    
                    if let data = data {
                        VStack(alignment: .trailing, spacing: 2) {
                            AutoMarqueeText(
                                text: data.value.displayValue,
                                font: .caption,
                                color: .primary,
                                startDelay: 2.0,
                                speed: 25.0
                            )
                            .fontWeight(.medium)
                            .frame(maxWidth: 60, alignment: .trailing)
                            
                            Text(sensorType.unit)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    AutoMarqueeText(
                        text: sensorType.rawValue,
                        font: .headline,
                        color: .primary,
                        startDelay: 1.5,
                        speed: 20.0
                    )
                    .fontWeight(.semibold)
                    .frame(height: 20)
                    
                    if let data = data {
                        AutoMarqueeText(
                            text: "Updated: \(formatTime(data.timestamp))",
                            font: .caption,
                            color: .secondary,
                            startDelay: 3.0,
                            speed: 15.0
                        )
                        .frame(height: 12)
                    } else {
                        Text("No data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .frame(height: 120)
            .background(isSelected ? sensorType.swiftUIColor.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? sensorType.swiftUIColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(sensorType.rawValue) sensor card")
        .accessibilityValue(data?.value.displayValue ?? "No data")
        .accessibilityHint("Tap to view detailed chart")
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

enum TimeRange: String, CaseIterable, Identifiable {
    case lastMinute = "1m"
    case lastFiveMinutes = "5m"
    case lastHour = "1h"
    case lastDay = "1d"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .lastMinute: return "1m"
        case .lastFiveMinutes: return "5m"
        case .lastHour: return "1h"
        case .lastDay: return "1d"
        }
    }
    
    var timeInterval: TimeInterval {
        switch self {
        case .lastMinute: return 60
        case .lastFiveMinutes: return 300
        case .lastHour: return 3600
        case .lastDay: return 86400
        }
    }
}
