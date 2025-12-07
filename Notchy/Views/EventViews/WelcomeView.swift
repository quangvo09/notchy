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
                .frame(height: 120)
            }
        }
    }

    // Icon gradient colors based on time of day (consistent with Default view)
    private var iconGradientColors: [Color] {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<8:   // Early morning - orange/pink sunrise
            return [.orange, .pink]
        case 8..<12:  // Late morning - yellow
            return [.yellow, .orange]
        case 12..<17: // Afternoon - blue
            return [.blue, .cyan]
        case 17..<20: // Evening - purple/blue
            return [.purple, .blue]
        case 20..<23: // Night - deep blue
            return [.indigo, .blue]
        default:      // Late night - dark purple
            return [.purple, .indigo]
        }
    }

    // Background accent color for subtle gradient (based on time of day, consistent with Default view)
    private var backgroundAccentColor: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<8:   // Early morning - orange/pink accent
            return .orange
        case 8..<12:  // Late morning - yellow accent
            return .yellow
        case 12..<17: // Afternoon - blue accent
            return .blue
        case 17..<20: // Evening - purple accent
            return .purple
        case 20..<23: // Night - deep blue accent
            return .indigo
        default:      // Late night - dark purple accent
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
