//
//  SensorData.swift
//  sensor monkey
//
//  Created by Sitharaj Seenivasan on 16/07/25.
//

import Foundation

// MARK: - Sensor Types
enum SensorType: String, CaseIterable, Identifiable {
    case accelerometer = "Accelerometer"
    case gyroscope = "Gyroscope"
    case magnetometer = "Magnetometer"
    case barometer = "Barometer"
    case lightSensor = "Light Sensor"
    case proximity = "Proximity"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .accelerometer: return "figure.run"
        case .gyroscope: return "arrow.triangle.2.circlepath"
        case .magnetometer: return "scope"
        case .barometer: return "thermometer"
        case .lightSensor: return "sun.max"
        case .proximity: return "hand.point.up"
        }
    }
    
    var unit: String {
        switch self {
        case .accelerometer: return "m/s²"
        case .gyroscope: return "rad/s"
        case .magnetometer: return "µT"
        case .barometer: return "hPa"
        case .lightSensor: return "lux"
        case .proximity: return "cm"
        }
    }
    
    var color: String {
        switch self {
        case .accelerometer: return "AccelerometerColor"
        case .gyroscope: return "GyroscopeColor"
        case .magnetometer: return "MagnetometerColor"
        case .barometer: return "BarometerColor"
        case .lightSensor: return "LightSensorColor"
        case .proximity: return "ProximityColor"
        }
    }
    
    var hexColor: String {
        switch self {
        case .accelerometer: return "#007AFF" // Blue
        case .gyroscope: return "#34C759" // Green
        case .magnetometer: return "#AF52DE" // Purple
        case .barometer: return "#FF9500" // Orange
        case .lightSensor: return "#FFCC00" // Yellow
        case .proximity: return "#FF3B30" // Red
        }
    }
}

// MARK: - Sensor Data Model
struct SensorData: Identifiable, Equatable {
    let id = UUID()
    let type: SensorType
    let value: SensorValue
    let timestamp: Date
    let isCalibrated: Bool
    
    init(type: SensorType, value: SensorValue, timestamp: Date = Date(), isCalibrated: Bool = true) {
        self.type = type
        self.value = value
        self.timestamp = timestamp
        self.isCalibrated = isCalibrated
    }
}

// MARK: - Sensor Value Types
enum SensorValue: Equatable {
    case single(Double)
    case triple(x: Double, y: Double, z: Double)
    case boolean(Bool)
    
    var displayValue: String {
        switch self {
        case .single(let value):
            return String(format: "%.2f", value)
        case .triple(let x, let y, let z):
            return String(format: "X: %.2f, Y: %.2f, Z: %.2f", x, y, z)
        case .boolean(let value):
            return value ? "Active" : "Inactive"
        }
    }
    
    var numericValue: Double {
        switch self {
        case .single(let value):
            return value
        case .triple(let x, let y, let z):
            return sqrt(x * x + y * y + z * z)
        case .boolean(let value):
            return value ? 1.0 : 0.0
        }
    }
}

// MARK: - Sensor Settings
struct SensorSettings: Codable {
    var isEnabled: Bool
    var updateInterval: TimeInterval
    var calibrationOffset: Double
    var alertThreshold: Double?
    
    init(isEnabled: Bool = true, updateInterval: TimeInterval = 0.1, calibrationOffset: Double = 0.0, alertThreshold: Double? = nil) {
        self.isEnabled = isEnabled
        self.updateInterval = updateInterval
        self.calibrationOffset = calibrationOffset
        self.alertThreshold = alertThreshold
    }
}

// MARK: - Historical Data Point
struct DataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
    
    init(timestamp: Date, value: Double) {
        self.timestamp = timestamp
        self.value = value
    }
}
