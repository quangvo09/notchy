import SwiftUI
import AppKit

/// Protocol defining a notch event that can be displayed in the Dynamic Island
protocol NotchEvent: Identifiable {
    var id: UUID { get }
    var priority: Int { get }  // Higher = more important (0-100)
    var title: String { get }
    var message: String? { get }
    var icon: String { get }  // SF Symbol name
    var color: Color { get }
    var autoDismiss: Bool { get }
    var dismissAfter: TimeInterval? { get }  // Seconds before auto-dismiss
    var timestamp: Date { get }

    /// Background color for the notch window when this event is displayed
    var notchBackgroundColor: NSColor { get }

    /// Create custom view for this event
    /// Default implementation uses EventNotificationView
    @ViewBuilder
    func makeView() -> AnyView
}

extension NotchEvent {
    /// Default view implementation
    /// Events can override this for custom UI
    func makeView() -> AnyView {
        AnyView(
            EventNotificationView(
                icon: icon,
                iconColor: color,
                title: title,
                message: message
            )
        )
    }
}

/// Generic event notification view used as default
struct EventNotificationView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let message: String?

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(iconColor.gradient)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
    }
}
