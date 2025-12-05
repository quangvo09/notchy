import Cocoa
import Combine
import SwiftUI

class ForegroundAppMonitor: ObservableObject {
    static let shared = ForegroundAppMonitor()

    @Published var frontmostApp: NSRunningApplication?
    @Published var bundleIdentifier: String?
    @Published var localizedName: String?

    private var cancellables = Set<AnyCancellable>()
    private var workspaceObserver: NSObjectProtocol?

    private init() {
        setupMonitoring()

        // Initial value
        updateCurrentApp()
    }

    deinit {
        if let observer = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    private func setupMonitoring() {
        // Monitor for application activation/deactivation
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                self?.updateAppInfo(app)
            }
        }

        // Also monitor for application termination
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.updateCurrentApp()
            }
        }
    }

    private func updateCurrentApp() {
        if let currentApp = NSWorkspace.shared.frontmostApplication {
            updateAppInfo(currentApp)
        }
    }

    private func updateAppInfo(_ app: NSRunningApplication) {
        DispatchQueue.main.async {
            self.frontmostApp = app
            self.bundleIdentifier = app.bundleIdentifier
            self.localizedName = app.localizedName
        }
    }

    // Helper method to check if current app is a specific type
    func isDevelopmentEnvironment() -> Bool {
        guard let bundleId = bundleIdentifier else { return false }
        return bundleId.contains("com.microsoft.VSCode") ||
               bundleId.contains("com.apple.dt.Xcode") ||
               bundleId.contains("com.jetbrains") ||
               bundleId.contains("com.sublimetext")
    }

    func isBrowser() -> Bool {
        guard let bundleId = bundleIdentifier else { return false }
        let browsers = [
            "com.google.Chrome",
            "org.mozilla.firefox",
            "com.apple.Safari",
            "company.thebrowser.Browser",
            "com.brave.Browser",
            "com.vivaldi.Vivaldi"
        ]
        return browsers.contains(bundleId)
    }

    func isTerminal() -> Bool {
        guard let bundleId = bundleIdentifier else { return false }
        return bundleId.contains("com.apple.Terminal") ||
               bundleId.contains("co.zeit.hyper") ||
               bundleId.contains("com.googlecode.iterm2")
    }
}