import SwiftUI
import Foundation

/// Default content view showing calendar and time
struct DefaultContentView: View {
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // AirPod battery monitor
    @StateObject private var batteryMonitor = AirPodsBatteryMonitor.shared

    // Get current week dates
    private var weekDates: [Date] {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentTime)?.start else {
            return []
        }

        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }

    var body: some View {
        ZStack {
            // Background layer with gradient
            backgroundGradient
                .edgesIgnoringSafeArea(.all)

            // Content layer
            VStack(spacing: 16) {
                // Time display
                VStack(spacing: 4) {
                    Text(currentTimeFormatted)
                        .font(.system(size: 48, weight: .thin, design: .rounded))
                        .foregroundStyle(.white)
                        .onReceive(timer) { _ in
                            currentTime = Date()
                        }

                    HStack(spacing: 8) {
                        Text(currentDateFormatted)
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.75))

                        Text("•")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.5))

                        Text(timeOfDay)
                            .font(.title3)
                            .foregroundStyle(timeOfDayColor.opacity(0.8))
                    }
                }

                // Week view
                HStack(spacing: 8) {
                    ForEach(weekDates, id: \.self) { date in
                        VStack(spacing: 4) {
                            Text(dayOfWeek(for: date))
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))

                            Text(dayNumber(for: date))
                                .font(.system(size: 14, weight: isToday(date) ? .bold : .regular))
                                .foregroundStyle(isToday(date) ? .white : .white.opacity(0.7))
                                .frame(width: 20, height: 20)
                                .background(
                                    Circle()
                                        .fill(isToday(date) ? timeOfDayColor.opacity(0.3) : .clear)
                                )
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.white.opacity(0.05))
                .cornerRadius(12)
 
                // AirPod battery info below calendar (only show if connected)
                if batteryMonitor.hasBatteryData() {
                    AirPodBatteryInfoView(batteryMonitor: batteryMonitor)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
        .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }

    // Formatted time string without seconds
    private var currentTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: currentTime)
    }

    // Formatted date string
    private var currentDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: currentTime)
    }

    // Month name
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: currentTime)
    }

    // Day number
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: currentTime)
    }

    // Helper functions for week view
    private func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: currentTime)
    }

    // Get time of day with appropriate greeting
    private var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12:
            return "Morning"
        case 12..<17:
            return "Afternoon"
        case 17..<21:
            return "Evening"
        default:
            return "Night"
        }
    }

    // Dynamic color based on time of day
    private var timeOfDayColor: Color {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<8:
            // Early morning - orange/pink sunrise
            return .orange
        case 8..<12:
            // Late morning - yellow
            return .yellow
        case 12..<17:
            // Afternoon - blue
            return .blue
        case 17..<20:
            // Evening - purple/blue
            return .purple
        case 20..<23:
            // Night - deep blue
            return .indigo
        default:
            // Late night - dark purple
            return .purple
        }
    }

    // Background with time-based gradient
    private var backgroundGradient: some View {
        ZStack {
            // Pure black base
            Color.black

            // Gradient from bottom fading up with time-based colors
            VStack(spacing: 0) {
                Spacer()

                LinearGradient(
                    colors: [
                        .clear,
                        timeOfDayColor.opacity(0.1),
                        timeOfDayColor.opacity(0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
            }
        }
    }
}

/// Simplified view for displaying AirPod battery info below calendar
struct AirPodBatteryInfoView: View {
    @ObservedObject var batteryMonitor: AirPodsBatteryMonitor

    var body: some View {
        HStack(spacing: 16) {
            // AirPods average battery
            if let avgBattery = batteryMonitor.getAverageBattery() {
                HStack(spacing: 6) {
                    Image(systemName: "airpodspro")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))

                    Text("\(Int(avgBattery * 100))%")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            // Case battery
            if batteryMonitor.caseBattery >= 0 {
                HStack(spacing: 6) {
                    Image(systemName: "airpods.gen3.chargingcase.wireless")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))

                    Text("\(batteryMonitor.caseBattery)%")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            // Charging indicator
            if batteryMonitor.isChargingLeft || batteryMonitor.isChargingRight || batteryMonitor.isChargingCase {
                Image(systemName: "bolt.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        DefaultContentView()
            .frame(width: 500, height: 150)
            .background(.ultraThickMaterial)
            .cornerRadius(20)

        // Preview with connected AirPods
        AirPodBatteryInfoView(batteryMonitor: {
            let monitor = AirPodsBatteryMonitor.shared
            monitor.left = 85
            monitor.right = 78
            monitor.caseBattery = 45
            monitor.name = "AirPods Pro"
            monitor.isChargingCase = true
            return monitor
        }())
        .frame(width: 300)
        .padding()
    }
}