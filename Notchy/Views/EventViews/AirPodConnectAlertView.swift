import SwiftUI

/// Custom view for AirPod connection alert events
struct AirPodConnectAlertView: View {
    let deviceName: String
    let batteryLevel: Float
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
                // Animated AirPod icon with battery indicator
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green.opacity(0.9), .mint.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 2)

                    Image(systemName: "airpodspro")
                        .font(.title2)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("AirPods Connected")
                        .font(.headline)
                        .foregroundStyle(.white)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(deviceName)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))

                        let batteryPercent = Int(batteryLevel * 100)
                        HStack(spacing: 4) {
                            Image(systemName: batteryIcon(for: batteryLevel))
                                .font(.caption)
                                .foregroundStyle(batteryLevel < 0.3 ? .red : .green)

                            Text("\(batteryPercent)%")
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

                Spacer()

                // Open Bluetooth settings button
                Button {
                    openBluetoothSettings()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
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

    // Black background with green gradient from bottom
    private var backgroundGradient: some View {
        ZStack {
            // Pure black base
            Color.black

            // Green gradient from bottom fading up
            VStack(spacing: 0) {
                Spacer()

                LinearGradient(
                    colors: [
                        .clear,
                        Color(red: 0.15, green: 0.6, blue: 0.3).opacity(0.1),
                        Color(red: 0.2, green: 0.7, blue: 0.4).opacity(0.2)
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

    private func openBluetoothSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings")!
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    VStack(spacing: 20) {
        AirPodConnectAlertView(
            deviceName: "AirPods Pro",
            batteryLevel: 0.85,
            caseBatteryLevel: 0.45
        )
            .frame(width: 420, height: 100)
            .padding()
            .background(.ultraThickMaterial)
            .cornerRadius(20)

        AirPodConnectAlertView(
            deviceName: "AirPods Max",
            batteryLevel: 0.92,
            caseBatteryLevel: nil
        )
            .frame(width: 420, height: 100)
            .padding()
            .background(.ultraThickMaterial)
            .cornerRadius(20)
    }
}