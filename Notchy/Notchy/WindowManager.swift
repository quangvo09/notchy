//
//  WindowManager.swift
//  Notchy
//
//  Manages the floating island window
//

import AppKit
import SwiftUI

class WindowManager: ObservableObject {
    static let shared = WindowManager()

    var islandWindow: NSWindow?

    // Island dimensions
    let collapsedWidth: CGFloat = 120
    let collapsedHeight: CGFloat = 35

    private init() {}

    func setupIslandWindow() {
        guard let screen = NSScreen.main else {
            print("❌ No main screen found")
            return
        }

        // Detect notch
        let hasNotch = screen.safeAreaInsets.top > 0
        let notchHeight = screen.safeAreaInsets.top
        let menuBarHeight: CGFloat = 24

        print("🖥️  Screen: \(screen.frame.width)x\(screen.frame.height)")
        print("🔍 Notch detected: \(hasNotch), Height: \(notchHeight)")

        // Calculate initial position (centered horizontally, just below menu bar/notch)
        let xPos = (screen.frame.width / 2) - (collapsedWidth / 2)
        let yPos: CGFloat

        if hasNotch {
            // Position just below the notch
            yPos = screen.frame.height - notchHeight - 5
        } else {
            // Position below menu bar for non-notched Macs
            yPos = screen.frame.height - menuBarHeight - 10
        }

        // Create borderless window
        islandWindow = NSWindow(
            contentRect: NSRect(x: xPos, y: yPos, width: collapsedWidth, height: collapsedHeight),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        guard let window = islandWindow else { return }

        // Window configuration
        window.level = .statusBar  // Always on top, but below system UI
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = false  // Allow interactions
        window.isMovableByWindowBackground = false

        // Set content view
        let islandView = DynamicIslandView(windowManager: self)
        window.contentView = NSHostingView(rootView: islandView)

        // Show window
        window.orderFrontRegardless()

        print("✅ Island window created at (\(xPos), \(yPos))")
    }

    func repositionIsland() {
        guard let screen = NSScreen.main, let window = islandWindow else { return }

        let hasNotch = screen.safeAreaInsets.top > 0
        let notchHeight = screen.safeAreaInsets.top
        let menuBarHeight: CGFloat = 24

        let xPos = (screen.frame.width / 2) - (window.frame.width / 2)
        let yPos: CGFloat

        if hasNotch {
            yPos = screen.frame.height - notchHeight - 5
        } else {
            yPos = screen.frame.height - menuBarHeight - 10
        }

        window.setFrameOrigin(NSPoint(x: xPos, y: yPos))

        print("🔄 Repositioned island to (\(xPos), \(yPos))")
    }

    func updateWindowSize(width: CGFloat, height: CGFloat, animated: Bool = true) {
        guard let window = islandWindow, let screen = NSScreen.main else { return }

        let hasNotch = screen.safeAreaInsets.top > 0
        let notchHeight = screen.safeAreaInsets.top
        let menuBarHeight: CGFloat = 24

        let xPos = (screen.frame.width / 2) - (width / 2)
        let yPos: CGFloat

        if hasNotch {
            yPos = screen.frame.height - notchHeight - 5
        } else {
            yPos = screen.frame.height - menuBarHeight - 10
        }

        let newFrame = NSRect(x: xPos, y: yPos, width: width, height: height)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.4
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(newFrame, display: true)
            }
        } else {
            window.setFrame(newFrame, display: true)
        }
    }
}
