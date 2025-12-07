import SwiftUI

struct DevToolsContextView: View {
    @State private var isRunningServer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Development Tools")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                ToolButton(
                    title: "Run npm start",
                    icon: "play.fill",
                    color: .green,
                    script: "npm start"
                )

                ToolButton(
                    title: "Open Terminal",
                    icon: "terminal.fill",
                    color: .orange,
                    action: {
                        ScriptRunner.openTerminal()
                    }
                )

                ToolButton(
                    title: "Stop Servers",
                    icon: "stop.fill",
                    color: .red,
                    script: "pkill -f \"node\\|npm\\|yarn\" || true"
                )

                ToolButton(
                    title: "Test AirPods",
                    icon: "airpods",
                    color: .blue,
                    action: {
                        AirPodConnectionMonitor.shared.simulateAirPodConnection()
                    }
                )
            }
        }
    }
}

struct ToolButton: View {
    let title: String
    let icon: String
    let color: Color
    let script: String?
    let action: (() -> Void)?

    @State private var isExecuting = false

    init(title: String, icon: String, color: Color, script: String) {
        self.title = title
        self.icon = icon
        self.color = color
        self.script = script
        self.action = nil
    }

    init(title: String, icon: String, color: Color, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.script = nil
        self.action = action
    }

    var body: some View {
        Button(action: {
            isExecuting = true

            if let action = action {
                action()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isExecuting = false
                }
            } else if let script = script {
                ScriptRunner.runShell(script)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isExecuting = false
                }
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: isExecuting ? "hourglass" : icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isExecuting ? .secondary : color)

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
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isExecuting)
    }
}

struct TerminalContextView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Terminal Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                ToolButton(
                    title: "New Tab",
                    icon: "plus.rectangle.fill",
                    color: .blue,
                    action: {
                        ScriptRunner.runAppleScript("""
                            tell application "Terminal"
                                activate
                                do script ""
                            end tell
                        """)
                    }
                )

                ToolButton(
                    title: "Clear",
                    icon: "trash.fill",
                    color: .gray,
                    script: "clear"
                )

                ToolButton(
                    title: "Copy Path",
                    icon: "doc.on.clipboard.fill",
                    color: .purple,
                    action: {
                        ScriptRunner.copyCurrentPath()
                    }
                )
            }
        }
    }
}