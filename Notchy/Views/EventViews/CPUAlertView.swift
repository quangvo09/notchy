import SwiftUI

/// Custom view for CPU alert events
struct CPUAlertView: View {
    let usage: Double

    var body: some View {
        ZStack {
            // Background layer - extends beyond edges to cover top corners
            backgroundGradient
                .padding(.top, -50)  // Extend up into notch corners
                .padding(.horizontal, -20)  // Extend to left/right corners
                .edgesIgnoringSafeArea(.all)

            // Content layer
            HStack(spacing: 16) {
                // Animated flame icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.red.opacity(0.9), .orange.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 2)

                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("High CPU Usage")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("\(Int(usage))% - System may be slow")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }

                Spacer()

                // Activity Monitor button
                Button {
                    openActivityMonitor()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                        Text("Details")
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.15))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 15)
            .padding(.top, 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }

    // Black background with red gradient from bottom
    private var backgroundGradient: some View {
        ZStack {
            // Pure black base
            Color.black

            // Red gradient from bottom fading up
            VStack(spacing: 0) {
                Spacer()

                LinearGradient(
                    colors: [
                        .clear,
                        Color(red: 0.6, green: 0.15, blue: 0.15).opacity(0.1),
                        Color(red: 0.8, green: 0.2, blue: 0.2).opacity(0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
            }
        }
    }

    private func openActivityMonitor() {
        let url = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    CPUAlertView(usage: 85.5)
        .frame(width: 420, height: 100)
        .padding()
        .background(.ultraThickMaterial)
        .cornerRadius(20)
}
