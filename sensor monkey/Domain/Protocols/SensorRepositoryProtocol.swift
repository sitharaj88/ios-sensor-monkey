//
//  SensorRepositoryProtocol.swift
//  sensor monkey
//
//  Created by Sitharaj Seenivasan on 16/07/25.
//

import Foundation
import Combine

// MARK: - Sensor Repository Protocol
protocol SensorRepositoryProtocol {
    func startMonitoring(for sensorType: SensorType) -> AnyPublisher<SensorData, Never>
    func stopMonitoring(for sensorType: SensorType)
    func calibrateSensor(_ sensorType: SensorType) -> AnyPublisher<Bool, Never>
    func getSensorSettings(for sensorType: SensorType) -> SensorSettings
    func updateSensorSettings(_ settings: SensorSettings, for sensorType: SensorType)
    func getHistoricalData(for sensorType: SensorType, from startDate: Date, to endDate: Date) -> [DataPoint]
}

// MARK: - Sensor Service Protocol
protocol SensorServiceProtocol {
    func startSensorMonitoring(for sensorType: SensorType) -> AnyPublisher<SensorData, Never>
    func stopSensorMonitoring(for sensorType: SensorType)
    func calibrateSensor(_ sensorType: SensorType) -> AnyPublisher<Bool, Never>
    func isAvailable(sensorType: SensorType) -> Bool
}

// MARK: - Settings Service Protocol
protocol SettingsServiceProtocol {
    func getSettings(for sensorType: SensorType) -> SensorSettings
    func updateSettings(_ settings: SensorSettings, for sensorType: SensorType)
    func resetToDefaults(for sensorType: SensorType)
}

// MARK: - Data Storage Protocol
protocol DataStorageProtocol {
    func saveData(_ data: SensorData)
    func loadHistoricalData(for sensorType: SensorType, from startDate: Date, to endDate: Date) -> [DataPoint]
    func clearData(for sensorType: SensorType)
    func clearAllData()
}

// MARK: - Accessibility Service Protocol
protocol AccessibilityServiceProtocol {
    func announceDataUpdate(_ data: SensorData)
    func announceCalibrationComplete(for sensorType: SensorType)
    func announceAlert(_ message: String)
}