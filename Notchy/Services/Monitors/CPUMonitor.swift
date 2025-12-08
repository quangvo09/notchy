import Foundation

/// Monitors CPU usage and triggers alerts when threshold is exceeded
@MainActor
class CPUMonitor {
    private var timer: Timer?
    private let threshold: Double
    private let checkInterval: TimeInterval
    private var lastAlertTime: Date?
    private let alertCooldown: TimeInterval = 60.0  // Don't spam alerts

    // Smart monitoring properties
    private let minConcurrentTime: TimeInterval  // Minimum time CPU must stay high
    private var cpuUsageHistory: [(Double, Date)] = []  // History of CPU readings
    private let maxHistorySize = 100  // Maximum history entries to keep

    /// Initialize CPU monitor
    /// - Parameters:
    ///   - threshold: CPU percentage threshold (0-100) to trigger alert
    ///   - checkInterval: How often to check CPU usage in seconds
    ///   - minConcurrentTime: Minimum time CPU must stay above threshold to trigger alert (default: 10s)
    init(threshold: Double = 80.0,
         checkInterval: TimeInterval = 5.0,
         minConcurrentTime: TimeInterval = 10.0) {
        self.threshold = threshold
        self.checkInterval = checkInterval
        self.minConcurrentTime = minConcurrentTime
        print("🔥 CPUMonitor: Initialized (threshold: \(threshold)%, interval: \(checkInterval)s, minTime: \(minConcurrentTime)s)")
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
        cpuUsageHistory.removeAll()
    }

    private func checkCPU() async {
        let usage = await getCPUUsage()
        let now = Date()

        // Add to history
        addToHistory(usage: usage, timestamp: now)

        print("🔥 CPUMonitor: Current usage: \(usage)% (threshold: \(threshold)%)")

        // Check if we should trigger an alert using smart detection
        if shouldTriggerAlert(usage: usage, at: now) {
            // Check cooldown to avoid spam
            if let lastAlert = lastAlertTime {
                let timeSinceLastAlert = now.timeIntervalSince(lastAlert)
                if timeSinceLastAlert < alertCooldown {
                    print("🔥 CPUMonitor: CPU high (\(Int(usage))%) but alert on cooldown (\(timeSinceLastAlert)s)")
                    return
                }
            }

            print("🔥 CPUMonitor: CPU above threshold for required duration (\(Int(usage))%), posting alert")
            lastAlertTime = now

            EventMonitor.shared.postEvent(
                CPUAlertEvent(cpuUsage: usage)
            )
        } else if usage > threshold {
            // CPU is high but hasn't met concurrent requirements yet
            print("🔥 CPUMonitor: CPU high (\(Int(usage))%) - monitoring for sustained usage")
        }
    }

    /// Add CPU usage to history, maintaining max size
    private func addToHistory(usage: Double, timestamp: Date) {
        cpuUsageHistory.append((usage, timestamp))

        // Trim history if it exceeds max size
        if cpuUsageHistory.count > maxHistorySize {
            cpuUsageHistory.removeFirst()
        }
    }

    /// Determine if an alert should be triggered based on smart detection logic
    private func shouldTriggerAlert(usage: Double, at timestamp: Date) -> Bool {
        guard usage > threshold else { return false }

        // Find the start of the current high CPU period
        // Look backwards through history to find when CPU went above threshold
        var startTime: Date?
        var highReadings: [(Double, Date)] = []

        // Collect all consecutive high readings from the end
        for (reading, time) in cpuUsageHistory.reversed() {
            if reading > threshold {
                highReadings.insert((reading, time), at: 0)
                startTime = time
            } else {
                break
            }
        }

        // Add current reading
        highReadings.append((usage, timestamp))

        // Calculate duration
        if let start = startTime {
            let duration = timestamp.timeIntervalSince(start)
            print("🔥 CPUMonitor: High CPU for \(duration)s (required: \(minConcurrentTime)s), readings: \(highReadings.count)")
            return duration >= minConcurrentTime
        }

        return false
    }

    /// Get current monitoring statistics for debugging
    func getMonitoringStats() -> (currentUsage: Double, highReadingsCount: Int, concurrentDuration: TimeInterval) {
        guard let lastReading = cpuUsageHistory.last else {
            return (0.0, 0, 0.0)
        }

        let currentUsage = lastReading.0
        let highReadings = cpuUsageHistory.filter { $0.0 > threshold }
        let concurrentDuration = highReadings.last?.1.timeIntervalSince(highReadings.first?.1 ?? lastReading.1) ?? 0.0

        return (currentUsage, highReadings.count, concurrentDuration)
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
