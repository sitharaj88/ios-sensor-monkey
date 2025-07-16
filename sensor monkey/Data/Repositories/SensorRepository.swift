//
//  SensorRepository.swift
//  sensor monkey
//
//  Created by Sitharaj Seenivasan on 16/07/25.
//

import Foundation
import Combine

// MARK: - Sensor Repository Implementation
class SensorRepository: SensorRepositoryProtocol {
    private let sensorService: SensorServiceProtocol
    private let settingsService: SettingsServiceProtocol
    private let dataStorageService: DataStorageProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(sensorService: SensorServiceProtocol = SensorService(),
         settingsService: SettingsServiceProtocol = SettingsService(),
         dataStorageService: DataStorageProtocol = DataStorageService()) {
        self.sensorService = sensorService
        self.settingsService = settingsService
        self.dataStorageService = dataStorageService
    }
    
    func startMonitoring(for sensorType: SensorType) -> AnyPublisher<SensorData, Never> {
        return sensorService.startSensorMonitoring(for: sensorType)
            .handleEvents(receiveOutput: { [weak self] data in
                self?.dataStorageService.saveData(data)
            })
            .eraseToAnyPublisher()
    }
    
    func stopMonitoring(for sensorType: SensorType) {
        sensorService.stopSensorMonitoring(for: sensorType)
    }
    
    func calibrateSensor(_ sensorType: SensorType) -> AnyPublisher<Bool, Never> {
        return sensorService.calibrateSensor(sensorType)
    }
    
    func getSensorSettings(for sensorType: SensorType) -> SensorSettings {
        return settingsService.getSettings(for: sensorType)
    }
    
    func updateSensorSettings(_ settings: SensorSettings, for sensorType: SensorType) {
        settingsService.updateSettings(settings, for: sensorType)
    }
    
    func getHistoricalData(for sensorType: SensorType, from startDate: Date, to endDate: Date) -> [DataPoint] {
        return dataStorageService.loadHistoricalData(for: sensorType, from: startDate, to: endDate)
    }
}