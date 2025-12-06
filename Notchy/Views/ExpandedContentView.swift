import SwiftUI

struct ExpandedContentView: View {
    @EnvironmentObject var monitor: ForegroundAppMonitor

    var body: some View {
        VStack(spacing: 16) {
            if monitor.isDevelopmentEnvironment() {
                DevToolsContextView()
            } else if monitor.isBrowser() {
                BookmarksContextView()
            } else if monitor.isTerminal() {
                TerminalContextView()
            } else {
                JumpRopeCPUView()
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 24)
        .frame(maxWidth: 420, maxHeight: 120)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.6)
        )
        .shadow(color: .black.opacity(0.25), radius: 10, y: 8)
    }
}
