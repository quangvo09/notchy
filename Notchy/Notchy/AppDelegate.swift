//
//  AppDelegate.swift
//  Notchy
//
//  Manages menu bar and application lifecycle
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var windowManager: WindowManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon (make it a menu bar app)
        NSApp.setActivationPolicy(.accessory)

        // Create menu bar status item
        setupMenuBar()

        // Initialize window manager and show island
        windowManager = WindowManager.shared
        windowManager?.setupIslandWindow()

        // Observe screen changes for repositioning
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "🏝️"
            button.toolTip = "Notchy - Dynamic Island for macOS"
        }

        // Create menu
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "About Notchy", action: #selector(aboutClicked), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitClicked), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc func handleScreenChange() {
        windowManager?.repositionIsland()
    }

    @objc func aboutClicked() {
        let alert = NSAlert()
        alert.messageText = "Notchy"
        alert.informativeText = "Dynamic Island for macOS\nVersion 1.0"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc func quitClicked() {
        NSApplication.shared.terminate(nil)
    }
}
