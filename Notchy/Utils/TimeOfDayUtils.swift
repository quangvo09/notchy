import SwiftUI

/// Utility enum for time-based color schemes and gradients
enum TimeOfDay: CaseIterable {
    case earlyMorning  // 5:00 - 8:00
    case lateMorning   // 8:00 - 12:00
    case afternoon     // 12:00 - 17:00
    case evening       // 17:00 - 20:00
    case night         // 20:00 - 23:00
    case lateNight     // 23:00 - 5:00

    /// Initialize from current hour
    init(hour: Int) {
        switch hour {
        case 5..<8:
            self = .earlyMorning
        case 8..<12:
            self = .lateMorning
        case 12..<17:
            self = .afternoon
        case 17..<20:
            self = .evening
        case 20..<23:
            self = .night
        default:
            self = .lateNight
        }
    }

    /// Initialize from current date
    init(date: Date = Date()) {
        let hour = Calendar.current.component(.hour, from: date)
        self.init(hour: hour)
    }

    /// Display name for the time period
    var displayName: String {
        switch self {
        case .earlyMorning:
            return "Early Morning"
        case .lateMorning:
            return "Morning"
        case .afternoon:
            return "Afternoon"
        case .evening:
            return "Evening"
        case .night:
            return "Night"
        case .lateNight:
            return "Late Night"
        }
    }

    /// Short display name for UI
    var shortName: String {
        switch self {
        case .earlyMorning, .lateMorning:
            return "Morning"
        case .afternoon:
            return "Afternoon"
        case .evening:
            return "Evening"
        case .night, .lateNight:
            return "Night"
        }
    }

    /// Primary color for this time period
    var primaryColor: Color {
        switch self {
        case .earlyMorning:
            return .orange
        case .lateMorning:
            return .yellow
        case .afternoon:
            return .blue
        case .evening:
            return .purple
        case .night:
            return .indigo
        case .lateNight:
            return .purple
        }
    }

    /// Gradient colors for icons and backgrounds
    var gradientColors: [Color] {
        switch self {
        case .earlyMorning:
            return [.orange, .pink]
        case .lateMorning:
            return [.yellow, .orange]
        case .afternoon:
            return [.blue, .cyan]
        case .evening:
            return [.purple, .blue]
        case .night:
            return [.indigo, .blue]
        case .lateNight:
            return [.purple, .indigo]
        }
    }

    /// Get the hour range for this time period
    var hourRange: String {
        switch self {
        case .earlyMorning:
            return "5:00 - 8:00"
        case .lateMorning:
            return "8:00 - 12:00"
        case .afternoon:
            return "12:00 - 17:00"
        case .evening:
            return "17:00 - 20:00"
        case .night:
            return "20:00 - 23:00"
        case .lateNight:
            return "23:00 - 5:00"
        }
    }
}

// MARK: - Convenience Extensions
extension TimeOfDay {
    /// Get current time of day
    static var current: TimeOfDay {
        return TimeOfDay()
    }

    /// Create gradient with this time period's colors
    func createLinearGradient(startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> LinearGradient {
        LinearGradient(
            colors: gradientColors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }

    /// Create background gradient for view backgrounds
    func createBackgroundGradient(opacity: Double = 0.2, height: CGFloat = 120) -> some View {
        VStack(spacing: 0) {
            Spacer()

            LinearGradient(
                colors: [
                    .clear,
                    primaryColor.opacity(opacity * 0.5),
                    primaryColor.opacity(opacity)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: height)
        }
    }
}