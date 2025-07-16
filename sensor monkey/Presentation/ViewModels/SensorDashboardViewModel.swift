//
//  SensorDashboardViewModel.swift
//  sensor monkey
//
//  Created by Sitharaj Seenivasan on 16/07/25.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Dashboard ViewModel
class SensorDashboardViewModel: ObservableObject {
    @Published var activeSensors: [SensorType: SensorData] = [:]
    @Published var sensorSettings: [SensorType: SensorSettings] = [:]
    @Published var isCalibrating: [SensorType: Bool] = [:]
    @Published var historicalData: [SensorType: [DataPoint]] = [:]
    @Published var selectedSensor: SensorType?
    @Published var showingSettings = false
    @Published var showingChart = false
    
    private let sensorService: SensorServiceProtocol
    private let settingsService: SettingsServiceProtocol
    private let dataStorageService: DataStorageProtocol
    private let accessibilityService: AccessibilityServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var sensorSubscriptions: [SensorType: AnyCancellable] = [:]
    
    init(sensorService: SensorServiceProtocol = SensorService(),
         settingsService: SettingsServiceProtocol = SettingsService(),
         dataStorageService: DataStorageProtocol = DataStorageService(),
         accessibilityService: AccessibilityServiceProtocol = AccessibilityService()) {
        
        self.sensorService = sensorService
        self.settingsService = settingsService
        self.dataStorageService = dataStorageService
        self.accessibilityService = accessibilityService
        
        loadSettings()
        startMonitoringAvailableSensors()
    }
    
    // MARK: - Public Methods
    func startMonitoring(for sensorType: SensorType) {
        guard sensorService.isAvailable(sensorType: sensorType) else { return }
        
        let subscription = sensorService.startSensorMonitoring(for: sensorType)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sensorData in
                self?.handleSensorData(sensorData)
            }
        
        sensorSubscriptions[sensorType] = subscription
    }
    
    func stopMonitoring(for sensorType: SensorType) {
        sensorSubscriptions[sensorType]?.cancel()
        sensorSubscriptions.removeValue(forKey: sensorType)
        sensorService.stopSensorMonitoring(for: sensorType)
        activeSensors.removeValue(forKey: sensorType)
    }
    
    func calibrateSensor(_ sensorType: SensorType) {
        isCalibrating[sensorType] = true
        
        sensorService.calibrateSensor(sensorType)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] success in
                self?.isCalibrating[sensorType] = false
                if success {
                    self?.accessibilityService.announceCalibrationComplete(for: sensorType)
                }
            }
            .store(in: &cancellables)
    }
    
    func updateSettings(_ settings: SensorSettings, for sensorType: SensorType) {
        sensorSettings[sensorType] = settings
        settingsService.updateSettings(settings, for: sensorType)
        
        // Restart monitoring with new settings if active
        if sensorSubscriptions[sensorType] != nil {
            stopMonitoring(for: sensorType)
            startMonitoring(for: sensorType)
        }
    }
    
    func loadHistoricalData(for sensorType: SensorType, from startDate: Date, to endDate: Date) {
        let data = dataStorageService.loadHistoricalData(for: sensorType, from: startDate, to: endDate)
        historicalData[sensorType] = data
    }
    
    func toggleSensorMonitoring(for sensorType: SensorType) {
        if sensorSubscriptions[sensorType] != nil {
            stopMonitoring(for: sensorType)
        } else {
            startMonitoring(for: sensorType)
        }
    }
    
    func selectSensor(_ sensorType: SensorType) {
        selectedSensor = sensorType
        loadHistoricalData(for: sensorType, from: Date().addingTimeInterval(-3600), to: Date())
    }
    
    // MARK: - Private Methods
    private func handleSensorData(_ data: SensorData) {
        activeSensors[data.type] = data
        dataStorageService.saveData(data)
        
        // Check for alerts
        if let threshold = sensorSettings[data.type]?.alertThreshold {
            if data.value.numericValue > threshold {
                accessibilityService.announceAlert("Alert: \(data.type.rawValue) exceeds threshold")
            }
        }
        
        // Announce data updates for accessibility
        if UIAccessibility.isVoiceOverRunning {
            accessibilityService.announceDataUpdate(data)
        }
    }
    
    private func loadSettings() {
        for sensorType in SensorType.allCases {
            sensorSettings[sensorType] = settingsService.getSettings(for: sensorType)
        }
    }
    
    private func startMonitoringAvailableSensors() {
        for sensorType in SensorType.allCases {
            if sensorService.isAvailable(sensorType: sensorType) &&
               sensorSettings[sensorType]?.isEnabled == true {
                startMonitoring(for: sensorType)
            }
        }
    }
}

// MARK: - Helper Extensions
extension SensorDashboardViewModel {
    var availableSensors: [SensorType] {
        return SensorType.allCases.filter { sensorService.isAvailable(sensorType: $0) }
    }
    
    var activeSensorTypes: [SensorType] {
        return Array(sensorSubscriptions.keys).sorted { $0.rawValue < $1.rawValue }
    }
    
    func isMonitoring(_ sensorType: SensorType) -> Bool {
        return sensorSubscriptions[sensorType] != nil
    }
    
    func getSensorValue(for sensorType: SensorType) -> String {
        return activeSensors[sensorType]?.value.displayValue ?? "No Data"
    }
    
    func getSensorTimestamp(for sensorType: SensorType) -> String {
        guard let timestamp = activeSensors[sensorType]?.timestamp else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}