//
//  HoverableView.swift
//  Notchy
//
//  Wraps SwiftUI view with AppKit hover detection
//

import SwiftUI
import AppKit

struct HoverableView<Content: View>: NSViewRepresentable {
    let content: Content
    let onEnter: () -> Void
    let onExit: () -> Void

    func makeNSView(context: Context) -> NSView {
        let containerView = HoverDetectorView()
        containerView.onEnter = onEnter
        containerView.onExit = onExit

        let hostingView = NSHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        return containerView
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let containerView = nsView as? HoverDetectorView,
           let hostingView = containerView.subviews.first as? NSHostingView<Content> {
            hostingView.rootView = content
        }
    }
}

class HoverDetectorView: NSView {
    var onEnter: (() -> Void)?
    var onExit: (() -> Void)?
    private var trackingArea: NSTrackingArea?
    private var isMouseInside = false

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let existingArea = trackingArea {
            removeTrackingArea(existingArea)
        }

        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .activeAlways,
            .inVisibleRect
        ]

        trackingArea = NSTrackingArea(
            rect: bounds,
            options: options,
            owner: self,
            userInfo: nil
        )

        if let area = trackingArea {
            addTrackingArea(area)
        }

        // Check if mouse is currently inside after updating
        if let window = self.window {
            let mouseLocation = window.mouseLocationOutsideOfEventStream
            let localPoint = convert(mouseLocation, from: nil)
            let isInside = bounds.contains(localPoint)

            if isInside && !isMouseInside {
                isMouseInside = true
                onEnter?()
            } else if !isInside && isMouseInside {
                isMouseInside = false
                onExit?()
            }
        }
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        guard !isMouseInside else { return }
        isMouseInside = true
        print("🔵 Mouse ENTERED tracking area")
        onEnter?()
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        guard isMouseInside else { return }
        isMouseInside = false
        print("🔴 Mouse EXITED tracking area")
        onExit?()
    }
}
