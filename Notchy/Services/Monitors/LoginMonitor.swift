import Foundation
import AppKit

/// Monitors login/startup events and shows welcome message
@MainActor
class LoginMonitor {
    private let defaults = UserDefaults.standard
    private let hasShownWelcomeKey = "LoginMonitor.hasShownWelcome"
    private let lastShownTimestampKey = "LoginMonitor.lastShownTimestamp"

    // Cooldown period: don't show more than once every 4 hours
    private let cooldownPeriod: TimeInterval = 4 * 60 * 60  // 4 hours in seconds

    init() {
        print("👋 LoginMonitor: Initialized")
        setupWakeNotifications()
    }

    /// Setup notifications for system wake/unlock events
    private func setupWakeNotifications() {
        // Listen for wake from sleep
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("👋 LoginMonitor: System woke from sleep")
            Task { @MainActor in
                self?.checkLoginEvent()
            }
        }

        // Listen for screen unlock
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.sessionDidBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("👋 LoginMonitor: Screen unlocked / session active")
            Task { @MainActor in
                self?.checkLoginEvent()
            }
        }

        print("👋 LoginMonitor: Wake/unlock notifications registered")
    }

    /// Check if we should show welcome message
    /// Shows on first app launch, first wake of the day, or after cooldown period
    func checkLoginEvent() {
        let hasShownBefore = defaults.bool(forKey: hasShownWelcomeKey)
        let lastShownTimestamp = defaults.object(forKey: lastShownTimestampKey) as? Date

        let now = Date()
        let calendar = Calendar.current

        // Check if this is first launch ever
        let isFirstLaunch = !hasShownBefore

        // Check if this is first show today
        var isFirstShowToday = false
        if let lastShown = lastShownTimestamp {
            isFirstShowToday = !calendar.isDate(lastShown, inSameDayAs: now)
        } else {
            isFirstShowToday = true
        }

        // Check if cooldown period has passed
        var isCooldownExpired = false
        if let lastShown = lastShownTimestamp {
            let timeSinceLastShown = now.timeIntervalSince(lastShown)
            isCooldownExpired = timeSinceLastShown >= cooldownPeriod
        } else {
            isCooldownExpired = true
        }

        print("👋 LoginMonitor: First launch: \(isFirstLaunch), First today: \(isFirstShowToday), Cooldown expired: \(isCooldownExpired)")

        // Show welcome on first launch ever, first show of the day, or after cooldown
        if isFirstLaunch || (isFirstShowToday && isCooldownExpired) {
            print("👋 LoginMonitor: Posting welcome event")

            // Mark as shown
            defaults.set(true, forKey: hasShownWelcomeKey)
            defaults.set(now, forKey: lastShownTimestampKey)

            // Post welcome event after a short delay (let app fully launch)
            Task {
                try? await Task.sleep(for: .seconds(2))
                EventMonitor.shared.postEvent(WelcomeEvent())
            }
        } else {
            if !isCooldownExpired, let lastShown = lastShownTimestamp {
                let timeSinceLastShown = now.timeIntervalSince(lastShown)
                let timeRemaining = cooldownPeriod - timeSinceLastShown
                let minutesRemaining = Int(timeRemaining / 60)
                print("👋 LoginMonitor: Cooldown active, \(minutesRemaining) minutes remaining")
            } else {
                print("👋 LoginMonitor: Welcome already shown, skipping")
            }
        }
    }

    /// Manually trigger welcome message (for testing)
    func triggerWelcome() {
        print("👋 LoginMonitor: Manually triggering welcome")

        // Reset the flag to force show
        defaults.removeObject(forKey: hasShownWelcomeKey)
        defaults.removeObject(forKey: lastShownTimestampKey)

        checkLoginEvent()
    }

    /// Reset welcome state (for testing)
    func resetWelcomeState() {
        defaults.removeObject(forKey: hasShownWelcomeKey)
        defaults.removeObject(forKey: lastShownTimestampKey)
        print("👋 LoginMonitor: Welcome state reset")
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        print("👋 LoginMonitor: Cleaned up notifications")
    }
}
