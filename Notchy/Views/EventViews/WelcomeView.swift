import SwiftUI

/// Custom view for welcome events
struct WelcomeView: View {
    let event: WelcomeEvent

    var body: some View {
        ZStack {
            // Background layer - extends beyond edges to cover top corners
            backgroundGradient
                .padding(.top, -50)  // Extend up into notch corners
                .padding(.horizontal, -20)  // Extend to left/right corners
                .edgesIgnoringSafeArea(.all)

            // Content layer
            HStack(spacing: 16) {
                // Time-based icon with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: iconGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: iconGradientColors.first!.opacity(0.4), radius: 8, x: 0, y: 2)

                    Image(systemName: event.icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundStyle(.white)

                    if let userName = event.message {
                        Text(userName)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }

                Spacer()

                // Time display
                Text(currentTimeString)
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .monospacedDigit()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }

    // Extracted background gradient with top fade
    private var backgroundGradient: some View {
        ZStack {
            // Main gradient background
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Accent gradient overlay
            RadialGradient(
                colors: [
                    accentColor.opacity(0.3),
                    .clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 200
            )

            // Top edge fade to blend with notch
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        .black.opacity(0.4),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 30)

                Spacer()
            }
        }
    }

    // Icon gradient colors (for the circle)
    private var iconGradientColors: [Color] {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  // Morning
            return [.orange, .yellow]
        case 12..<17: // Afternoon
            return [.yellow, .orange]
        case 17..<22: // Evening
            return [.pink, .purple]
        default:      // Night
            return [.indigo, .purple]
        }
    }

    // Background gradient colors (for the card)
    private var backgroundGradientColors: [Color] {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  // Morning - warm sunrise
            return [
                Color(red: 0.9, green: 0.5, blue: 0.2),
                Color(red: 0.95, green: 0.7, blue: 0.3)
            ]
        case 12..<17: // Afternoon - bright golden
            return [
                Color(red: 0.95, green: 0.7, blue: 0.2),
                Color(red: 1.0, green: 0.85, blue: 0.4)
            ]
        case 17..<22: // Evening - sunset pink
            return [
                Color(red: 0.8, green: 0.3, blue: 0.5),
                Color(red: 0.6, green: 0.25, blue: 0.6)
            ]
        default:      // Night - deep purple/blue
            return [
                Color(red: 0.3, green: 0.2, blue: 0.6),
                Color(red: 0.4, green: 0.2, blue: 0.7)
            ]
        }
    }

    // Accent color for shadows and radial gradient
    private var accentColor: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return .orange
        case 12..<17:
            return .yellow
        case 17..<22:
            return .pink
        default:
            return .purple
        }
    }

    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }
}

#Preview {
    WelcomeView(event: WelcomeEvent())
        .frame(width: 420, height: 120)
        .padding()
        .background(.ultraThickMaterial)
        .cornerRadius(20)
}
