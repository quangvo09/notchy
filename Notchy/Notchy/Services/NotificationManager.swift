//
//  NotificationManager.swift
//  Notchy
//
//  Manages notifications displayed in the Dynamic Island
//

import Foundation
import UserNotifications

struct IslandNotification {
    var title: String
    var message: String
    var icon: String
    var timestamp: Date

    static let empty = IslandNotification(
        title: "",
        message: "",
        icon: "bell.fill",
        timestamp: Date()
    )
}

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var currentNotification: IslandNotification = .empty
    @Published var hasNotification: Bool = false

    private override init() {
        super.init()
        requestPermissions()
    }

    // MARK: - Permissions

    private func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permissions granted")
            } else {
                print("❌ Notification permissions denied")
            }
        }
    }

    // MARK: - Show Notification

    func showNotification(title: String, message: String, icon: String = "bell.fill", duration: TimeInterval = 4.0) {
        let notification = IslandNotification(
            title: title,
            message: message,
            icon: icon,
            timestamp: Date()
        )

        DispatchQueue.main.async {
            self.currentNotification = notification
            self.hasNotification = true

            // Update island state
            IslandStateManager.shared.setMode(.notification, duration: duration)
        }

        // Auto-dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.dismissNotification()
        }
    }

    func dismissNotification() {
        DispatchQueue.main.async {
            self.hasNotification = false
            self.currentNotification = .empty
        }
    }

    // MARK: - Test Notifications

    func showTestNotification() {
        let messages = [
            ("Message Received", "Hey! How are you doing?", "message.fill"),
            ("Calendar", "Meeting in 5 minutes", "calendar"),
            ("Reminder", "Time to take a break", "bell.fill"),
            ("Download Complete", "YourFile.zip is ready", "arrow.down.circle.fill"),
            ("Battery Low", "15% remaining", "battery.25")
        ]

        let random = messages.randomElement()!
        showNotification(title: random.0, message: random.1, icon: random.2)
    }
}
