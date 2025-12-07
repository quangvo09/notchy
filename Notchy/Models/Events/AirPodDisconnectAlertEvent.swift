import SwiftUI
import AppKit

/// Alert shown when AirPods are disconnected
struct AirPodDisconnectAlertEvent: NotchEvent {
    let id = UUID()
    let priority = 75  // High priority for disconnection
    let deviceName: String
    let batteryLevel: Float?  // Last known battery level
    let caseBatteryLevel: Float?  // Last known case battery level
    let timestamp = Date()

    var title: String {
        "AirPods Disconnected"
    }

    var message: String? {
        var message = deviceName

        if let battery = batteryLevel {
            let batteryPercent = Int(battery * 100)
            message += " • \(batteryPercent)%"
        }

        if let caseBattery = caseBatteryLevel {
            let casePercent = Int(caseBattery * 100)
            message += " (Case: \(casePercent)%)"
        }

        return message
    }

    let icon = "airpods"
    let color = Color.orange

    let autoDismiss = true  // Auto dismiss for disconnections
    let dismissAfter: TimeInterval? = 3.0  // 3 seconds

    var notchBackgroundColor: NSColor {
        // Orange matching disconnection theme
        NSColor(red: 0.8, green: 0.4, blue: 0.1, alpha: 1.0)
    }

    func makeView() -> AnyView {
        AnyView(AirPodDisconnectAlertView(
            deviceName: deviceName,
            batteryLevel: batteryLevel,
            caseBatteryLevel: caseBatteryLevel
        ))
    }
}