import SwiftUI
import AppKit

/// Alert shown when CPU usage is high
struct CPUAlertEvent: NotchEvent {
    let id = UUID()
    let priority = 80  // High priority
    let cpuUsage: Double
    let timestamp = Date()

    var title: String {
        "High CPU Usage"
    }

    var message: String? {
        "\(Int(cpuUsage))% - System may be slow"
    }

    let icon = "flame.fill"
    let color = Color.red

    let autoDismiss = false  // Manual dismiss only
    let dismissAfter: TimeInterval? = nil

    var notchBackgroundColor: NSColor {
        // Dark red matching the gradient in CPUAlertView
        NSColor(red: 0.6, green: 0.15, blue: 0.15, alpha: 1.0)
    }

    func makeView() -> AnyView {
        AnyView(CPUAlertView(usage: cpuUsage))
    }
}
