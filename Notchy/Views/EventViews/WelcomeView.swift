import SwiftUI

/// Custom view for welcome events
struct WelcomeView: View {
    let event: WelcomeEvent
    private let timeOfDay = TimeOfDay.current

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
                        .fill(timeOfDay.createLinearGradient())
                        .frame(width: 50, height: 50)
                        .shadow(color: timeOfDay.primaryColor.opacity(0.4), radius: 8, x: 0, y: 2)

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

    // Black background with time-based gradient accent
    private var backgroundGradient: some View {
        ZStack {
            // Pure black base
            Color.black

            // Time-based gradient from bottom fading up
            timeOfDay.createBackgroundGradient(opacity: 0.2, height: 120)
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
