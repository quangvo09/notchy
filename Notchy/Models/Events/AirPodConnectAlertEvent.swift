import SwiftUI
import AppKit

/// Alert shown when AirPods are connected
struct AirPodConnectAlertEvent: NotchEvent {
    let id = UUID()
    let priority = 65  // High priority but lower than phones
    let deviceName: String
    let batteryLevel: Float  // Battery level as 0.0 to 1.0
    let caseBatteryLevel: Float?  // Case battery level, nil if unknown
    let timestamp = Date()

    var title: String {
        "AirPods Connected"
    }

    var message: String? {
        var message = deviceName

        let batteryPercent = Int(batteryLevel * 100)
        message += " • \(batteryPercent)%"

        if let caseBattery = caseBatteryLevel {
            let casePercent = Int(caseBattery * 100)
            message += " (Case: \(casePercent)%)"
        }

        return message
    }

    let icon = "airpods"
    let color = Color.green

    let autoDismiss = true  // Auto dismiss for AirPod connections
    let dismissAfter: TimeInterval? = 4.0  // 4 seconds

    var notchBackgroundColor: NSColor {
        // Green matching AirPods theme
        NSColor(red: 0.15, green: 0.6, blue: 0.3, alpha: 1.0)
    }

    func makeView() -> AnyView {
        AnyView(AirPodConnectAlertView(
            deviceName: deviceName,
            batteryLevel: batteryLevel,
            caseBatteryLevel: caseBatteryLevel
        ))
    }
}