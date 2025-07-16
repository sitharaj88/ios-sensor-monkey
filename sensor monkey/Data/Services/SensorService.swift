//
//  SensorService.swift
//  sensor monkey
//
//  Created by Sitharaj Seenivasan on 16/07/25.
//

import Foundation
import CoreMotion
import Combine

// MARK: - Sensor Service Implementation
class SensorService: ObservableObject, SensorServiceProtocol {
    private let motionManager = CMMotionManager()
    private var cancellables = Set<AnyCancellable>()
    private var activePublishers: [SensorType: PassthroughSubject<SensorData, Never>] = [:]
    private var updateTimers: [SensorType: Timer] = [:]
    
    init() {
        setupMotionManager()
    }
    
    private func setupMotionManager() {
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.gyroUpdateInterval = 0.1
        motionManager.magnetometerUpdateInterval = 0.1
        motionManager.deviceMotionUpdateInterval = 0.1
    }
    
    func startSensorMonitoring(for sensorType: SensorType) -> AnyPublisher<SensorData, Never> {
        let publisher = PassthroughSubject<SensorData, Never>()
        activePublishers[sensorType] = publisher
        
        switch sensorType {
        case .accelerometer:
            startAccelerometerUpdates(publisher: publisher)
        case .gyroscope:
            startGyroscopeUpdates(publisher: publisher)
        case .magnetometer:
            startMagnetometerUpdates(publisher: publisher)
        case .barometer:
            startBarometerUpdates(publisher: publisher)
        case .lightSensor:
            startLightSensorUpdates(publisher: publisher)
        case .proximity:
            startProximityUpdates(publisher: publisher)
        }
        
        return publisher.eraseToAnyPublisher()
    }
    
    func stopSensorMonitoring(for sensorType: SensorType) {
        activePublishers[sensorType]?.send(completion: .finished)
        activePublishers.removeValue(forKey: sensorType)
        updateTimers[sensorType]?.invalidate()
        updateTimers.removeValue(forKey: sensorType)
        
        switch sensorType {
        case .accelerometer:
            motionManager.stopAccelerometerUpdates()
        case .gyroscope:
            motionManager.stopGyroUpdates()
        case .magnetometer:
            motionManager.stopMagnetometerUpdates()
        default:
            break
        }
    }
    
    func calibrateSensor(_ sensorType: SensorType) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                promise(.success(true))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func isAvailable(sensorType: SensorType) -> Bool {
        switch sensorType {
        case .accelerometer:
            return motionManager.isAccelerometerAvailable
        case .gyroscope:
            return motionManager.isGyroAvailable
        case .magnetometer:
            return motionManager.isMagnetometerAvailable
        case .barometer, .lightSensor, .proximity:
            return true // Simulated sensors
        }
    }
    
    // MARK: - Private Methods
    private func startAccelerometerUpdates(publisher: PassthroughSubject<SensorData, Never>) {
        guard motionManager.isAccelerometerAvailable else { return }
        
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            
            let sensorData = SensorData(
                type: .accelerometer,
                value: .triple(x: data.acceleration.x, y: data.acceleration.y, z: data.acceleration.z)
            )
            
            publisher.send(sensorData)
        }
    }
    
    private func startGyroscopeUpdates(publisher: PassthroughSubject<SensorData, Never>) {
        guard motionManager.isGyroAvailable else { return }
        
        motionManager.startGyroUpdates(to: .main) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            
            let sensorData = SensorData(
                type: .gyroscope,
                value: .triple(x: data.rotationRate.x, y: data.rotationRate.y, z: data.rotationRate.z)
            )
            
            publisher.send(sensorData)
        }
    }
    
    private func startMagnetometerUpdates(publisher: PassthroughSubject<SensorData, Never>) {
        guard motionManager.isMagnetometerAvailable else { return }
        
        motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            
            let sensorData = SensorData(
                type: .magnetometer,
                value: .triple(x: data.magneticField.x, y: data.magneticField.y, z: data.magneticField.z)
            )
            
            publisher.send(sensorData)
        }
    }
    
    private func startBarometerUpdates(publisher: PassthroughSubject<SensorData, Never>) {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            let pressure = 1013.25 + Double.random(in: -10...10)
            let sensorData = SensorData(
                type: .barometer,
                value: .single(pressure)
            )
            publisher.send(sensorData)
        }
        updateTimers[.barometer] = timer
    }
    
    private func startLightSensorUpdates(publisher: PassthroughSubject<SensorData, Never>) {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            let lux = Double.random(in: 0...1000)
            let sensorData = SensorData(
                type: .lightSensor,
                value: .single(lux)
            )
            publisher.send(sensorData)
        }
        updateTimers[.lightSensor] = timer
    }
    
    private func startProximityUpdates(publisher: PassthroughSubject<SensorData, Never>) {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            let distance = Double.random(in: 0...10)
            let sensorData = SensorData(
                type: .proximity,
                value: .single(distance)
            )
            publisher.send(sensorData)
        }
        updateTimers[.proximity] = timer
    }
}