import Foundation
import SwiftUI
import Combine
import IOBluetooth

/// Monitor for AirPods battery levels using Apple's private API
final class AirPodsBatteryMonitor: ObservableObject {
    @Published var left: Int = -1
    @Published var right: Int = -1
    @Published var caseBattery: Int = -1
    @Published var isChargingLeft = false
    @Published var isChargingRight = false
    @Published var isChargingCase = false
    @Published var name: String = "AirPods"

    static let shared = AirPodsBatteryMonitor()

    private var cancellable: AnyCancellable?
    private var observer: Any?
    private var lastUpdate: Date = Date.distantPast
    private let updateInterval: TimeInterval = 1.0 // Throttle updates to avoid spam

    private init() {
        setupBatteryMonitoring()
    }

    private func setupBatteryMonitoring() {
        print("🔋 AirPodsBatteryMonitor: Setting up Bluetooth monitoring with private API")

        // This is the private API that Apple uses for AirPods battery widget in menu bar
        guard NSClassFromString("BTSDevice") != nil else {
            print("⚠️ Could not access BTSDevice private API, falling back to IOBluetooth")
            setupFallbackMonitoring()
            return
        }

        // Listen to all Bluetooth changes (battery, connection, charging...)
        cancellable = NotificationCenter.default
            .publisher(for: NSNotification.Name("BTSDeviceDidUpdateNotification"))
            .sink { [weak self] _ in
                self?.updateRealBatteryData()
            }

        // Initial read
        updateRealBatteryData()
        print("🔋 AirPodsBatteryMonitor: Real battery monitoring active")
    }

    private func setupFallbackMonitoring() {
        // Fallback to IOBluetooth if private API is not available
        observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("IOBluetoothDeviceNotificationString_DeviceConnected"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAirPodsBattery()
        }

        updateAirPodsBattery()
    }

    private func updateRealBatteryData() {
        // Throttle updates
        let now = Date()
        guard now.timeIntervalSince(lastUpdate) >= updateInterval else { return }
        lastUpdate = now

        guard let devices = (NSClassFromString("BTSDevice")?
            .value(forKey: "allDevices") as? NSArray) else {
            print("🔋 AirPodsBatteryMonitor: Could not get BTS devices")
            return
        }

        for case let device as NSObject in devices {
            guard let deviceName = device.value(forKey: "name") as? String,
                  deviceName.localizedCaseInsensitiveContains("AirPods") else { continue }

            self.name = deviceName

            left            = (device.value(forKey: "batteryPercentLeft")   as? Int)  ?? -1
            right           = (device.value(forKey: "batteryPercentRight")  as? Int)  ?? -1
            caseBattery     = (device.value(forKey: "batteryPercentCase")   as? Int)  ?? -1

            isChargingLeft  = (device.value(forKey: "isChargingLeft")   as? Bool) ?? false
            isChargingRight = (device.value(forKey: "isChargingRight")  as? Bool) ?? false
            isChargingCase  = (device.value(forKey: "isChargingCase")   as? Bool) ?? false

            print("🔋 \(deviceName) - L:\(left)% R:\(right)% Case:\(caseBattery)%")
            print("   Charging: L=\(isChargingLeft) R=\(isChargingRight) Case=\(isChargingCase)")

            // Exit loop when AirPods found (only 1 pair)
            break
        }
    }

    private func updateAirPodsBattery() {
        // Fallback method using IOBluetooth
        // This should not be reached if the private API works
        print("🔋 AirPodsBatteryMonitor (fallback): Using fallback - private API not available")

        // Reset to -1 to show no data when fallback is used
        left = -1
        right = -1
        caseBattery = -1
        isChargingLeft = false
        isChargingRight = false
        isChargingCase = false

        // Don't set dummy values, just leave as -1 (no data)
    }

    /// Get average battery level for display
    func getAverageBattery() -> Float? {
        var validBatteries: [Float] = []

        if left >= 0 { validBatteries.append(Float(left) / 100.0) }
        if right >= 0 { validBatteries.append(Float(right) / 100.0) }

        return validBatteries.isEmpty ? nil : validBatteries.reduce(0, +) / Float(validBatteries.count)
    }

    /// Get case battery as Float or nil
    func getCaseBattery() -> Float? {
        return caseBattery >= 0 ? Float(caseBattery) / 100.0 : nil
    }

    /// Check if any AirPods have battery data
    func hasBatteryData() -> Bool {
        return left >= 0 || right >= 0 || caseBattery >= 0
    }

    /// Reset battery data
    func reset() {
        left = -1
        right = -1
        caseBattery = -1
        isChargingLeft = false
        isChargingRight = false
        isChargingCase = false
        name = "AirPods"
    }

    /// Manually set battery data for testing
    func setTestData(left: Int, right: Int, caseBattery: Int, deviceName: String = "AirPods Pro") {
        self.left = left
        self.right = right
        self.caseBattery = caseBattery
        self.name = deviceName
        print("🔋 AirPodsBatteryMonitor: Test data set - L:\(left)% R:\(right)% Case:\(caseBattery)%")
    }

    deinit {
        if let obs = observer {
            NotificationCenter.default.removeObserver(obs)
        }
        cancellable?.cancel()
    }
}