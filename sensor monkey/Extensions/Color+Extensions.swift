//
//  Color+Extensions.swift
//  sensor monkey
//
//  Created by Sitharaj Seenivasan on 16/07/25.
//

import SwiftUI

extension Color {
    // MARK: - Sensor Colors
    static let accelerometerColor = Color(hex: "#007AFF") // Blue
    static let gyroscopeColor = Color(hex: "#34C759") // Green
    static let magnetometerColor = Color(hex: "#AF52DE") // Purple
    static let barometerColor = Color(hex: "#FF9500") // Orange
    static let lightSensorColor = Color(hex: "#FFCC00") // Yellow
    static let proximityColor = Color(hex: "#FF3B30") // Red
    
    // MARK: - Hex Color Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension SensorType {
    var swiftUIColor: Color {
        switch self {
        case .accelerometer: return .accelerometerColor
        case .gyroscope: return .gyroscopeColor
        case .magnetometer: return .magnetometerColor
        case .barometer: return .barometerColor
        case .lightSensor: return .lightSensorColor
        case .proximity: return .proximityColor
        }
    }
}
