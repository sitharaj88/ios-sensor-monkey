//
//  DataStorageService.swift
//  sensor monkey
//
//  Created by Sitharaj Seenivasan on 16/07/25.
//

import Foundation
import UIKit

// MARK: - Data Storage Service Implementation
class DataStorageService: DataStorageProtocol {
    private var historicalData: [SensorType: [DataPoint]] = [:]
    private let maxDataPoints = 1000
    private let queue = DispatchQueue(label: "com.sensormonkey.datastorage", qos: .background)
    
    func saveData(_ data: SensorData) {
        queue.async { [weak self] in
            let dataPoint = DataPoint(timestamp: data.timestamp, value: data.value.numericValue)
            
            if self?.historicalData[data.type] == nil {
                self?.historicalData[data.type] = []
            }
            
            self?.historicalData[data.type]?.append(dataPoint)
            
            // Keep only the most recent data points
            if let count = self?.historicalData[data.type]?.count, count > self?.maxDataPoints ?? 0 {
                self?.historicalData[data.type]?.removeFirst()
            }
        }
    }
    
    func loadHistoricalData(for sensorType: SensorType, from startDate: Date, to endDate: Date) -> [DataPoint] {
        return queue.sync {
            return historicalData[sensorType]?.filter { dataPoint in
                dataPoint.timestamp >= startDate && dataPoint.timestamp <= endDate
            } ?? []
        }
    }
    
    func clearData(for sensorType: SensorType) {
        queue.async { [weak self] in
            self?.historicalData[sensorType] = []
        }
    }
    
    func clearAllData() {
        queue.async { [weak self] in
            self?.historicalData.removeAll()
        }
    }
}

// MARK: - Accessibility Service Implementation
class AccessibilityService: AccessibilityServiceProtocol {
    func announceDataUpdate(_ data: SensorData) {
        let announcement = "\(data.type.rawValue): \(data.value.displayValue) \(data.type.unit)"
        DispatchQueue.main.async {
            // Use VoiceOver announcement
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }
    
    func announceCalibrationComplete(for sensorType: SensorType) {
        let announcement = "\(sensorType.rawValue) calibration complete"
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }
    
    func announceAlert(_ message: String) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
}
