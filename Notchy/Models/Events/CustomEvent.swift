import SwiftUI
import AppKit

/// Flexible custom event that can be created programmatically
/// Allows users to create their own events with custom properties
struct CustomEvent: NotchEvent {
    let id: UUID
    let priority: Int
    let title: String
    let message: String?
    let icon: String
    let color: Color
    let autoDismiss: Bool
    let dismissAfter: TimeInterval?
    let timestamp: Date
    let notchBackgroundColor: NSColor

    /// Custom view builder for this event (optional)
    private let customView: (() -> AnyView)?

    /// Create a custom event with all properties
    init(
        id: UUID = UUID(),
        priority: Int = 50,
        title: String,
        message: String? = nil,
        icon: String = "bell.fill",
        color: Color = .blue,
        notchBackgroundColor: NSColor? = nil,
        autoDismiss: Bool = true,
        dismissAfter: TimeInterval? = 5.0,
        timestamp: Date = Date(),
        customView: (() -> AnyView)? = nil
    ) {
        self.id = id
        self.priority = priority
        self.title = title
        self.message = message
        self.icon = icon
        self.color = color
        self.autoDismiss = autoDismiss
        self.dismissAfter = dismissAfter
        self.timestamp = timestamp
        self.customView = customView

        // Convert SwiftUI Color to NSColor if not provided
        if let notchBackgroundColor = notchBackgroundColor {
            self.notchBackgroundColor = notchBackgroundColor
        } else {
            self.notchBackgroundColor = NSColor(color)
        }
    }

    func makeView() -> AnyView {
        if let customView = customView {
            return customView()
        }

        // Use default implementation
        return AnyView(
            EventNotificationView(
                icon: icon,
                iconColor: color,
                title: title,
                message: message
            )
        )
    }
}

// MARK: - Convenience Initializers

extension CustomEvent {
    /// Create a simple notification-style event
    static func notification(
        title: String,
        message: String? = nil,
        icon: String = "bell.fill",
        color: Color = .blue,
        autoDismiss: Bool = true,
        dismissAfter: TimeInterval? = 5.0
    ) -> CustomEvent {
        CustomEvent(
            title: title,
            message: message,
            icon: icon,
            color: color,
            autoDismiss: autoDismiss,
            dismissAfter: dismissAfter
        )
    }

    /// Create a high-priority alert-style event
    static func alert(
        title: String,
        message: String? = nil,
        icon: String = "exclamationmark.triangle.fill",
        color: Color = .red
    ) -> CustomEvent {
        CustomEvent(
            priority: 90,
            title: title,
            message: message,
            icon: icon,
            color: color,
            autoDismiss: false,
            dismissAfter: nil
        )
    }

    /// Create a low-priority info-style event
    static func info(
        title: String,
        message: String? = nil,
        icon: String = "info.circle.fill",
        autoDismiss: Bool = true
    ) -> CustomEvent {
        CustomEvent(
            priority: 30,
            title: title,
            message: message,
            icon: icon,
            color: .blue,
            autoDismiss: autoDismiss,
            dismissAfter: 10.0
        )
    }
}
