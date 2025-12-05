import SwiftUI

struct GenericContextView: View {
    let appName: String
    @StateObject private var monitor = ForegroundAppMonitor.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let icon = monitor.frontmostApp?.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(appName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(appInfoText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            HStack(spacing: 12) {
                GenericToolButton(
                    title: "Reveal in Finder",
                    icon: "folder.fill",
                    action: {
                        if let bundleId = monitor.bundleIdentifier,
                           let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                            ScriptRunner.revealInFinder(path: appUrl.path)
                        }
                    }
                )

                GenericToolButton(
                    title: "Quit App",
                    icon: "xmark.circle.fill",
                    action: {
                        if let app = monitor.frontmostApp {
                            app.terminate()
                        }
                    }
                )

                GenericToolButton(
                    title: "New Window",
                    icon: "plus.square.fill",
                    action: {
                        ScriptRunner.runAppleScript("""
                            tell application "\(appName)"
                                activate
                                try
                                    make new document
                                on error
                                    try
                                        make new window
                                    on error
                                        keystroke "n" using command down
                                    end try
                                end try
                            end tell
                        """)
                    }
                )
            }
        }
    }

    private var appInfoText: String {
        guard monitor.bundleIdentifier != nil else { return "Unknown app" }

        if let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "Version \(version)"
        }

        return "Active application"
    }
}

struct GenericToolButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)

                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.primary.opacity(0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(isHovering ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}