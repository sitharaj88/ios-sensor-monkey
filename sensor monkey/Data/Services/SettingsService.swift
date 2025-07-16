//
//  SettingsService.swift
//  sensor monkey
//
//  Created by Sitharaj Seenivasan on 16/07/25.
//

import Foundation

// MARK: - Settings Service Implementation
class SettingsService: SettingsServiceProtocol {
    private let userDefaults = UserDefaults.standard
    private var settings: [SensorType: SensorSettings] = [:]
    
    init() {
        loadAllSettings()
    }
    
    func getSettings(for sensorType: SensorType) -> SensorSettings {
        return settings[sensorType] ?? defaultSettings(for: sensorType)
    }
    
    func updateSettings(_ settings: SensorSettings, for sensorType: SensorType) {
        self.settings[sensorType] = settings
        saveSettings(settings, for: sensorType)
    }
    
    func resetToDefaults(for sensorType: SensorType) {
        let defaultSettings = defaultSettings(for: sensorType)
        updateSettings(defaultSettings, for: sensorType)
    }
    
    private func defaultSettings(for sensorType: SensorType) -> SensorSettings {
        switch sensorType {
        case .accelerometer, .gyroscope, .magnetometer:
            return SensorSettings(updateInterval: 0.1, alertThreshold: 2.0)
        case .barometer:
            return SensorSettings(updateInterval: 0.5, alertThreshold: 50.0)
        case .lightSensor:
            return SensorSettings(updateInterval: 0.3, alertThreshold: 800.0)
        case .proximity:
            return SensorSettings(updateInterval: 0.2, alertThreshold: 2.0)
        }
    }
    
    private func settingsKey(for sensorType: SensorType) -> String {
        return "settings_\(sensorType.rawValue)"
    }
    
    private func saveSettings(_ settings: SensorSettings, for sensorType: SensorType) {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey(for: sensorType))
        }
    }
    
    private func loadAllSettings() {
        for sensorType in SensorType.allCases {
            if let data = userDefaults.data(forKey: settingsKey(for: sensorType)),
               let settings = try? JSONDecoder().decode(SensorSettings.self, from: data) {
                self.settings[sensorType] = settings
            }
        }
    }
}