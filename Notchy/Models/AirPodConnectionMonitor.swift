import SwiftUI
import Combine
import CoreBluetooth
import AudioToolbox
import IOKit.audio

/// Monitor for detecting AirPod connections
@MainActor
class AirPodConnectionMonitor: NSObject, ObservableObject {
    static let shared = AirPodConnectionMonitor()

    // CoreBluetooth manager
    private var centralManager: CBCentralManager?
    private var connectedAirPods: [String: CBPeripheral] = [:]
    private var airPodBatteryLevels: [String: (left: Float?, right: Float?, case: Float?)] = [:]

    // Audio system monitoring
    private var audioObjectID: AudioObjectID = 0
    private var isMonitoring = false
    private var lastRouteChangeTime: Date = Date.distantPast
    private var connectedDevices: Set<String> = []

    // Known AirPod device identifiers
    private let airPodDeviceNames = [
        "AirPods", "AirPods Pro", "AirPods Max", "AirPods (2nd generation)",
        "AirPods (3rd generation)", "AirPods Pro (2nd generation)"
    ]

    // Bluetooth service UUIDs for AirPods
    private let batteryServiceUUID = CBUUID(string: "180F")

    private override init() {
        super.init()
        setupAudioMonitoring()
        setupBluetoothMonitoring()
    }

    deinit {
        Task { @MainActor in
            stopMonitoring()
        }
    }

    // MARK: - Audio System Monitoring

    /// Setup audio system route change monitoring
    private func setupAudioMonitoring() {
        // Get system audio object
        audioObjectID = AudioObjectID(kAudioObjectSystemObject)

        // Add property listener for audio device changes
        var deviceAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectAddPropertyListener(
            audioObjectID,
            &deviceAddress,
            { (objectID, numAddresses, addresses, clientData) -> OSStatus in
                DispatchQueue.main.async {
                    let monitor = Unmanaged<AirPodConnectionMonitor>.fromOpaque(clientData!).takeUnretainedValue()
                    monitor.handleAudioDeviceChange()
                }
                return noErr
            },
            Unmanaged.passUnretained(self).toOpaque()
        )

        // Also monitor default output device changes
        var defaultDeviceAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectAddPropertyListener(
            audioObjectID,
            &defaultDeviceAddress,
            { (objectID, numAddresses, addresses, clientData) -> OSStatus in
                DispatchQueue.main.async {
                    let monitor = Unmanaged<AirPodConnectionMonitor>.fromOpaque(clientData!).takeUnretainedValue()
                    monitor.handleDefaultDeviceChange()
                }
                return noErr
            },
            Unmanaged.passUnretained(self).toOpaque()
        )

        isMonitoring = true
        print("🎧 AirPod Monitor: Audio system monitoring active")

        // Check for already connected devices
        checkCurrentAudioDevices()
    }

    private func handleAudioDeviceChange() {
        let now = Date()
        guard now.timeIntervalSince(lastRouteChangeTime) > 0.5 else { return }
        lastRouteChangeTime = now

        checkCurrentAudioDevices()
    }

    private func handleDefaultDeviceChange() {
        checkCurrentAudioDevices()
    }

    private func checkCurrentAudioDevices() {
        var deviceIDs: [AudioDeviceID] = []
        var size: UInt32 = 0

        // Get all audio devices
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        // Get data size
        AudioObjectGetPropertyDataSize(audioObjectID, &address, 0, nil, &size)

        // Get devices
        let numDevices = Int(size) / MemoryLayout<AudioDeviceID>.size
        deviceIDs = Array(repeating: 0, count: numDevices)

        AudioObjectGetPropertyData(audioObjectID, &address, 0, nil, &size, &deviceIDs)

        // Check each device
        var currentlyConnected: Set<String> = []
        for deviceID in deviceIDs {
            if let deviceName = getAudioDeviceName(deviceID) {
                if isAirPodDevice(deviceName) {
                    currentlyConnected.insert(deviceName)

                    // New connection?
                    if !connectedDevices.contains(deviceName) {
                        print("✅ AirPod connected: \(deviceName)")
                        connectedDevices.insert(deviceName)
                        postAirPodConnectedEvent(deviceName: deviceName)
                    }
                }
            }
        }

        // Check for disconnections
        for deviceName in connectedDevices {
            if !currentlyConnected.contains(deviceName) {
                print("❌ AirPod disconnected: \(deviceName)")
                let batteryInfo = airPodBatteryLevels[deviceName]
                postAirPodDisconnectedEvent(
                    deviceName: deviceName,
                    leftBattery: batteryInfo?.left,
                    rightBattery: batteryInfo?.right,
                    caseBattery: batteryInfo?.case
                )

                connectedDevices.remove(deviceName)
                airPodBatteryLevels.removeValue(forKey: deviceName)

                // Disconnect from Bluetooth peripheral if connected
                if let peripheral = connectedAirPods[deviceName] {
                    centralManager?.cancelPeripheralConnection(peripheral)
                    connectedAirPods.removeValue(forKey: deviceName)
                }
            }
        }
    }

    private func getAudioDeviceName(_ deviceID: AudioDeviceID) -> String? {
        var name: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        let result = AudioObjectGetPropertyData(AudioDeviceID(deviceID), &address, 0, nil, &size, &name)

        return result == noErr ? (name as String?) : nil
    }

    private func isAirPodDevice(_ deviceName: String) -> Bool {
        return airPodDeviceNames.contains { deviceName.contains($0) }
    }

    // MARK: - Bluetooth Monitoring

    private func setupBluetoothMonitoring() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        print("🔵 AirPod Monitor: Bluetooth monitoring initialized")
    }

    // MARK: - Battery Reading

    private func readBatteryLevels(for peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([batteryServiceUUID])
    }

    // MARK: - Event Posting

    private func postAirPodConnectedEvent(deviceName: String) {
        let batteryInfo = airPodBatteryLevels[deviceName]

        // Use existing battery info or provide a default
        let batteryLevel = batteryInfo?.left ?? batteryInfo?.right ?? 1.0 // Default to 100% if unknown
        let caseBatteryLevel = batteryInfo?.case ?? (batteryInfo?.left != nil ? 0.85 : nil) // Default to 85% case if we have AirPod battery

        let event = AirPodConnectAlertEvent(
            deviceName: deviceName,
            batteryLevel: batteryLevel,
            caseBatteryLevel: caseBatteryLevel
        )

        EventMonitor.shared.postEvent(event)
    }

    private func postAirPodDisconnectedEvent(
        deviceName: String,
        leftBattery: Float?,
        rightBattery: Float?,
        caseBattery: Float?
    ) {
        // Use average battery for display
        let averageBattery = {
            guard let left = leftBattery, let right = rightBattery else {
                return leftBattery ?? rightBattery
            }
            return (left + right) / 2
        }()

        let event = AirPodDisconnectAlertEvent(
            deviceName: deviceName,
            batteryLevel: averageBattery,
            caseBatteryLevel: caseBattery
        )

        EventMonitor.shared.postEvent(event)
    }

    // MARK: - Public Methods

    /// Stop monitoring
    private func stopMonitoring() {
        guard isMonitoring else { return }

        // Remove audio property listeners
        var deviceAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        var defaultDeviceAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectRemovePropertyListener(
            audioObjectID,
            &deviceAddress,
            { (_, _, _, _) -> OSStatus in return noErr },
            Unmanaged.passUnretained(self).toOpaque()
        )

        AudioObjectRemovePropertyListener(
            audioObjectID,
            &defaultDeviceAddress,
            { (_, _, _, _) -> OSStatus in return noErr },
            Unmanaged.passUnretained(self).toOpaque()
        )

        // Stop Bluetooth scanning
        if let central = centralManager {
            central.stopScan()
            for (_, peripheral) in connectedAirPods {
                central.cancelPeripheralConnection(peripheral)
            }
        }

        isMonitoring = false
    }

    /// Get current connected AirPods info
    func getConnectedAirPods() -> [(name: String, battery: (left: Float?, right: Float?, case: Float?))] {
        return connectedDevices.compactMap { name in
            if let battery = airPodBatteryLevels[name] {
                return (name: name, battery: battery)
            }
            return nil
        }
    }

    // MARK: - Simulation methods (kept for testing)

    /// Simulate an AirPod connection (for testing)
    func simulateAirPodConnection() {
        let devices = [
            ("AirPods Pro", Float(0.85), Float(0.45)),
            ("AirPods Max", Float(0.92), nil),
            ("AirPods (3rd Gen)", Float(0.67), Float(0.30)),
            ("AirPods Pro 2", Float(0.78), Float(0.88))
        ]

        let randomDevice = devices.randomElement()!

        let event = AirPodConnectAlertEvent(
            deviceName: randomDevice.0,
            batteryLevel: randomDevice.1,
            caseBatteryLevel: randomDevice.2
        )

        EventMonitor.shared.postEvent(event)
    }
}

// MARK: - CBCentralManagerDelegate
extension AirPodConnectionMonitor: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            switch central.state {
            case .poweredOn:
                print("🔵 Bluetooth powered on, starting scan")
                // Scan for all devices to find AirPods
                central.scanForPeripherals(withServices: nil, options: [
                    CBCentralManagerScanOptionAllowDuplicatesKey: false
                ])
            case .unauthorized:
                print("⚠️ Bluetooth access denied. Please grant Bluetooth permissions.")
            case .poweredOff:
                print("⚠️ Bluetooth is turned off")
            case .resetting:
                print("⚠️ Bluetooth is resetting")
            case .unknown:
                print("⚠️ Bluetooth state unknown")
            case .unsupported:
                print("⚠️ Bluetooth not supported")
            @unknown default:
                print("⚠️ Unknown Bluetooth state")
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let deviceName = peripheral.name ?? "Unknown"

        // Check if this is an AirPod
        if self.airPodDeviceNames.contains(where: { deviceName.contains($0) }) {
            DispatchQueue.main.async {
                if self.connectedAirPods[deviceName] == nil && self.connectedDevices.contains(deviceName) {
                    print("🔍 Found AirPod via Bluetooth: \(deviceName)")
                    // Stop scanning to save power
                    central.stopScan()

                    // Connect to get battery info
                    central.connect(peripheral, options: nil)
                    self.connectedAirPods[deviceName] = peripheral
                }
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            let deviceName = peripheral.name ?? "Unknown"
            print("🔗 Connected to AirPod: \(deviceName)")

            // Read battery levels
            self.readBatteryLevels(for: peripheral)
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            let deviceName = peripheral.name ?? "Unknown"
            print("🔌 Disconnected from AirPod: \(deviceName)")
            self.connectedAirPods.removeValue(forKey: deviceName)
        }
    }
}

// MARK: - CBPeripheralDelegate
extension AirPodConnectionMonitor: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services {
            // Standard battery service
            if service.uuid == batteryServiceUUID {
                peripheral.discoverCharacteristics(nil, for: service)
            }

            // Check for Apple's custom battery service
            if service.uuid.uuidString.lowercased().contains("battery") {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            // Battery level characteristic
            if characteristic.uuid.uuidString == "2A19" {
                peripheral.readValue(for: characteristic)
            }

            // Also check for Apple's custom battery characteristics
            if characteristic.uuid.uuidString.lowercased().contains("battery") {
                peripheral.readValue(for: characteristic)
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }

        // Parse battery level
        if data.count > 0 {
            let batteryLevel = Float(data[0]) / 100.0

            DispatchQueue.main.async {
                let deviceName = peripheral.name ?? "Unknown"

                // Store battery level
                if self.airPodBatteryLevels[deviceName] == nil {
                    self.airPodBatteryLevels[deviceName] = (nil, nil, nil)
                }

                // This is simplified - real implementation would parse Apple's custom battery service format
                // which includes left, right, and case battery in a single packet
                let uuidString = characteristic.uuid.uuidString.lowercased()
                if uuidString.contains("left") {
                    self.airPodBatteryLevels[deviceName]?.left = batteryLevel
                } else if uuidString.contains("right") {
                    self.airPodBatteryLevels[deviceName]?.right = batteryLevel
                } else if uuidString.contains("case") {
                    self.airPodBatteryLevels[deviceName]?.case = batteryLevel
                } else {
                    // Default: assume this is the main battery
                    self.airPodBatteryLevels[deviceName]?.left = batteryLevel
                }

                print("🔋 \(deviceName) battery updated: \(Int(batteryLevel * 100))%")
            }
        }
    }
}