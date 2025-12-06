import Foundation

/// Monitors CPU usage and triggers alerts when threshold is exceeded
@MainActor
class CPUMonitor {
    private var timer: Timer?
    private let threshold: Double
    private let checkInterval: TimeInterval
    private var lastAlertTime: Date?
    private let alertCooldown: TimeInterval = 60.0  // Don't spam alerts

    /// Initialize CPU monitor
    /// - Parameters:
    ///   - threshold: CPU percentage threshold (0-100) to trigger alert
    ///   - checkInterval: How often to check CPU usage in seconds
    init(threshold: Double = 80.0, checkInterval: TimeInterval = 5.0) {
        self.threshold = threshold
        self.checkInterval = checkInterval
        print("🔥 CPUMonitor: Initialized (threshold: \(threshold)%, interval: \(checkInterval)s)")
    }

    /// Start monitoring CPU usage
    func startMonitoring() {
        print("🔥 CPUMonitor: Starting monitoring")

        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkCPU()
            }
        }

        // Run first check immediately
        Task {
            await checkCPU()
        }
    }

    /// Stop monitoring
    func stopMonitoring() {
        print("🔥 CPUMonitor: Stopping monitoring")
        timer?.invalidate()
        timer = nil
    }

    private func checkCPU() async {
        let usage = await getCPUUsage()

        // Check if we should trigger an alert
        if usage > threshold {
            // Check cooldown to avoid spam
            if let lastAlert = lastAlertTime {
                let timeSinceLastAlert = Date().timeIntervalSince(lastAlert)
                if timeSinceLastAlert < alertCooldown {
                    print("🔥 CPUMonitor: CPU high (\(Int(usage))%) but alert on cooldown")
                    return
                }
            }

            print("🔥 CPUMonitor: CPU above threshold (\(Int(usage))%), posting alert")
            lastAlertTime = Date()

            EventMonitor.shared.postEvent(
                CPUAlertEvent(cpuUsage: usage)
            )
        }
    }

    /// Get current CPU usage percentage
    private func getCPUUsage() async -> Double {
        do {
            // Run top command to get CPU usage
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = ["-c", "top -l 1 -s 0 -n 0 | grep 'CPU usage'"]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                return 0.0
            }

            // Parse output like: "CPU usage: 15.5% user, 8.2% sys, 76.3% idle"
            let components = output.components(separatedBy: ",")

            var totalUsage = 0.0

            for component in components {
                let trimmed = component.trimmingCharacters(in: .whitespaces)

                if trimmed.contains("user") || trimmed.contains("sys") {
                    // Extract percentage value
                    let parts = trimmed.components(separatedBy: "%")
                    if let firstPart = parts.first,
                       let percentStr = firstPart.components(separatedBy: " ").last,
                       let percent = Double(percentStr) {
                        totalUsage += percent
                    }
                }
            }

            return totalUsage

        } catch {
            print("🔥 CPUMonitor: Error getting CPU usage: \(error)")
            return 0.0
        }
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }
}
