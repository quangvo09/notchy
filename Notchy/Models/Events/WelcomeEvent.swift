import SwiftUI
import AppKit

/// Welcome message shown on first login/app launch
struct WelcomeEvent: NotchEvent {
    let id = UUID()
    let priority = 50
    let timestamp = Date()

    var title: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good Morning!"
        case 12..<17:
            return "Good Afternoon!"
        case 17..<22:
            return "Good Evening!"
        default:
            return "Welcome Back!"
        }
    }

    var message: String? {
        NSFullUserName()
    }

    var icon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "sunrise.fill"
        case 12..<17:
            return "sun.max.fill"
        case 17..<22:
            return "sunset.fill"
        default:
            return "moon.stars.fill"
        }
    }

    var color: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return .orange
        case 12..<17:
            return .yellow
        case 17..<22:
            return .pink
        default:
            return .indigo
        }
    }

    var notchBackgroundColor: NSColor {
        // Time-based background matching WelcomeView gradients
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  // Morning - warm sunrise
            return NSColor(red: 0.95, green: 0.7, blue: 0.3, alpha: 1.0)
        case 12..<17: // Afternoon - bright golden
            return NSColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0)
        case 17..<22: // Evening - sunset pink
            return NSColor(red: 0.6, green: 0.25, blue: 0.6, alpha: 1.0)
        default:      // Night - deep purple
            return NSColor(red: 0.4, green: 0.2, blue: 0.7, alpha: 1.0)
        }
    }

    let autoDismiss = true
    let dismissAfter: TimeInterval? = 5.0

    func makeView() -> AnyView {
        AnyView(WelcomeView(event: self))
    }
}
