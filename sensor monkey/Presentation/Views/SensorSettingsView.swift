//
//  SensorSettingsView.swift
//  sensor monkey
//
//  Created by Sitharaj Seenivasan on 16/07/25.
//

import SwiftUI

struct SensorSettingsView: View {
    @ObservedObject var viewModel: SensorDashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSensor: SensorType?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    ForEach(viewModel.availableSensors) { sensorType in
                        SensorSettingsRow(
                            sensorType: sensorType,
                            settings: viewModel.sensorSettings[sensorType] ?? SensorSettings(),
                            isMonitoring: viewModel.isMonitoring(sensorType),
                            onToggle: {
                                viewModel.toggleSensorMonitoring(for: sensorType)
                            },
                            onSettingsChange: { newSettings in
                                viewModel.updateSettings(newSettings, for: sensorType)
                            }
                        )
                    }
                } header: {
                    Text("Sensor Configuration")
                }
                
                Section {
                    Button("Clear All Data") {
                        // Clear all historical data
                    }
                    .foregroundColor(.red)
                    
                    Button("Reset All Settings") {
                        // Reset all sensor settings to defaults
                    }
                    .foregroundColor(.orange)
                } header: {
                    Text("Data Management")
                }
                
                Section {
                    HStack {
                        Text("Accessibility")
                        Spacer()
                        Toggle("", isOn: .constant(UIAccessibility.isVoiceOverRunning))
                            .disabled(true)
                    }
                    
                    HStack {
                        Text("Announce Updates")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                    }
                } header: {
                    Text("Accessibility")
                } footer: {
                    Text("Enable voice announcements for sensor data updates and alerts")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SensorSettingsRow: View {
    let sensorType: SensorType
    let settings: SensorSettings
    let isMonitoring: Bool
    let onToggle: () -> Void
    let onSettingsChange: (SensorSettings) -> Void
    
    @State private var showingDetailSettings = false
    @State private var localSettings: SensorSettings
    
    init(sensorType: SensorType, settings: SensorSettings, isMonitoring: Bool, onToggle: @escaping () -> Void, onSettingsChange: @escaping (SensorSettings) -> Void) {
        self.sensorType = sensorType
        self.settings = settings
        self.isMonitoring = isMonitoring
        self.onToggle = onToggle
        self.onSettingsChange = onSettingsChange
        self._localSettings = State(initialValue: settings)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: sensorType.icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading) {
                    Text(sensorType.rawValue)
                        .font(.headline)
                    
                    Text("Update: \(String(format: "%.1f", settings.updateInterval))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: .init(
                    get: { isMonitoring },
                    set: { _ in onToggle() }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .frame(width: 55) // Improved width for better appearance
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showingDetailSettings = true
            }
            
            if isMonitoring {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Monitoring active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(sensorType.rawValue) sensor")
        .accessibilityValue(isMonitoring ? "Monitoring active" : "Monitoring inactive")
        .accessibilityHint("Tap to configure sensor settings")
        .sheet(isPresented: $showingDetailSettings) {
            SensorDetailSettingsView(
                sensorType: sensorType,
                settings: $localSettings,
                onSave: { newSettings in
                    onSettingsChange(newSettings)
                }
            )
        }
    }
}

struct SensorDetailSettingsView: View {
    let sensorType: SensorType
    @Binding var settings: SensorSettings
    let onSave: (SensorSettings) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Enabled")
                        Spacer()
                        Toggle("", isOn: $settings.isEnabled)
                    }
                } header: {
                    Text("General")
                }
                
                Section {
                    VStack(alignment: .leading) {
                        Text("Update Interval: \(String(format: "%.1f", settings.updateInterval))s")
                        
                        Slider(
                            value: $settings.updateInterval,
                            in: 0.1...2.0,
                            step: 0.1
                        )
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Calibration Offset: \(String(format: "%.2f", settings.calibrationOffset))")
                        
                        Slider(
                            value: $settings.calibrationOffset,
                            in: -10.0...10.0,
                            step: 0.1
                        )
                    }
                } header: {
                    Text("Monitoring")
                }
                
                Section {
                    HStack {
                        Text("Alert Threshold")
                        Spacer()
                        if let threshold = settings.alertThreshold {
                            Text(String(format: "%.1f", threshold))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Off")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let threshold = settings.alertThreshold {
                        VStack(alignment: .leading) {
                            Text("Threshold: \(String(format: "%.1f", threshold)) \(sensorType.unit)")
                            
                            Slider(
                                value: Binding(
                                    get: { threshold },
                                    set: { settings.alertThreshold = $0 }
                                ),
                                in: 0.0...100.0,
                                step: 0.1
                            )
                        }
                    }
                    
                    Button(settings.alertThreshold == nil ? "Enable Alerts" : "Disable Alerts") {
                        if settings.alertThreshold == nil {
                            settings.alertThreshold = 10.0
                        } else {
                            settings.alertThreshold = nil
                        }
                    }
                } header: {
                    Text("Alerts")
                }
                
                Section {
                    Button("Reset to Defaults") {
                        settings = SensorSettings()
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle(sensorType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(settings)
                        dismiss()
                    }
                }
            }
        }
    }
}
