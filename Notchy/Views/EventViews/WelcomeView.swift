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
            .padding(.horizontal, 15)
            .padding(.top, 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }

    // Black background with time-based gradient accent (like CPU view pattern)
    private var backgroundGradient: some View {
        ZStack {
            // Pure black base
            Color.black

            // Time-based gradient from bottom fading up
            VStack(spacing: 0) {
                Spacer()

                LinearGradient(
                    colors: [
                        .clear,
                        backgroundAccentColor.opacity(0.1),
                        backgroundAccentColor.opacity(0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
            }
        }
    }

    // Icon gradient colors based on time of day
    private var iconGradientColors: [Color] {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  // Morning - golden yellow
            return [.orange, .yellow]
        case 12..<17: // Afternoon - bright blue
            return [.blue, .cyan]
        case 17..<22: // Evening - purple/pink
            return [.purple, .pink]
        default:      // Night - dark blue
            return [.indigo, .blue]
        }
    }

    // Background accent color for subtle gradient (based on time of day)
    private var backgroundAccentColor: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  // Morning - golden accent
            return Color(red: 0.8, green: 0.5, blue: 0.1)
        case 12..<17: // Afternoon - blue accent
            return Color(red: 0.1, green: 0.4, blue: 0.7)
        case 17..<22: // Evening - purple accent
            return Color(red: 0.5, green: 0.2, blue: 0.7)
        default:      // Night - deep blue accent
            return Color(red: 0.1, green: 0.1, blue: 0.4)
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
