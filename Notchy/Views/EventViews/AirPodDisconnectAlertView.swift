import SwiftUI

/// Custom view for AirPod disconnection alert events
struct AirPodDisconnectAlertView: View {
    let deviceName: String
    let batteryLevel: Float?
    let caseBatteryLevel: Float?

    var body: some View {
        ZStack {
            // Background layer - extends beyond edges to cover top corners
            backgroundGradient
                .padding(.top, -50)  // Extend up into notch corners
                .padding(.horizontal, -20)  // Extend to left/right corners
                .edgesIgnoringSafeArea(.all)

            // Content layer
            HStack(spacing: 16) {
                // Animated AirPod icon with disconnect indicator
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.9), .red.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 2)

                    VStack {
                        Image(systemName: "airpodspro")
                            .font(.title2)
                            .foregroundStyle(.white)

                        // Disconnect indicator
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(.red)
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("AirPods Disconnected")
                        .font(.headline)
                        .foregroundStyle(.white)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(deviceName)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))

                        if let battery = batteryLevel {
                            let batteryPercent = Int(battery * 100)
                            HStack(spacing: 4) {
                                Image(systemName: batteryIcon(for: battery))
                                    .font(.caption)
                                    .foregroundStyle(battery < 0.3 ? .red : .green)

                                Text("Last battery: \(batteryPercent)%")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.75))

                                if let caseBattery = caseBatteryLevel {
                                    let casePercent = Int(caseBattery * 100)
                                    Text("•")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.5))

                                    Text("Case: \(casePercent)%")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.75))
                                }
                            }
                        }
                    }
                }

                Spacer()

                // Find AirPods button
                Button {
                    openFindMy()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                        Text("Find")
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

    // Black background with orange gradient from bottom
    private var backgroundGradient: some View {
        ZStack {
            // Pure black base
            Color.black

            // Orange gradient from bottom fading up
            VStack(spacing: 0) {
                Spacer()

                LinearGradient(
                    colors: [
                        .clear,
                        Color(red: 0.8, green: 0.4, blue: 0.1).opacity(0.1),
                        Color(red: 0.9, green: 0.5, blue: 0.2).opacity(0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
            }
        }
    }

    private func batteryIcon(for level: Float) -> String {
        switch level {
        case 0.8...1.0:
            return "battery.100"
        case 0.6..<0.8:
            return "battery.75"
        case 0.4..<0.6:
            return "battery.50"
        case 0.2..<0.4:
            return "battery.25"
        default:
            return "battery.0"
        }
    }

    private func openFindMy() {
        // Open Find My app for AirPods
        let url = URL(string: "x-apple.systempreferences:com.apple.FindMy")!
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    VStack(spacing: 20) {
        AirPodDisconnectAlertView(
            deviceName: "AirPods Pro",
            batteryLevel: 0.85,
            caseBatteryLevel: 0.45
        )
            .frame(width: 420, height: 100)
            .padding()
            .background(.ultraThickMaterial)
            .cornerRadius(20)

        AirPodDisconnectAlertView(
            deviceName: "AirPods Max",
            batteryLevel: 0.30,
            caseBatteryLevel: nil
        )
            .frame(width: 420, height: 100)
            .padding()
            .background(.ultraThickMaterial)
            .cornerRadius(20)
    }
}