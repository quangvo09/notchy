import SwiftUI

struct ExpandedContentView: View {
    @EnvironmentObject var monitor: ForegroundAppMonitor
    @EnvironmentObject var orchestrator: NotchContentOrchestrator
    @State private var isHoveringDismiss = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main content area - fills entire notch space
            Group {
                switch orchestrator.mode {
                case .context:
                    contextView()
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        ))

                case .event:
                    if let event = orchestrator.getCurrentEvent() {
                        event.makeView()
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.95).combined(with: .opacity),
                                removal: .scale(scale: 0.95).combined(with: .opacity)
                            ))
                    } else {
                        // Fallback if event not found
                        contextView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all)

            // Floating dismiss button (only show for events)
            if case .event = orchestrator.mode {
                dismissButton
                    .padding(8)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.6).combined(with: .opacity),
                        removal: .scale(scale: 0.6).combined(with: .opacity)
                    ))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
    }

    @ViewBuilder
    private func contextView() -> some View {
        // if monitor.isDevelopmentEnvironment() {
        //     DevToolsContextView()
        // } else if monitor.isBrowser() {
        //     BookmarksContextView()
        // } else if monitor.isTerminal() {
        //     TerminalContextView()
        // } else {
        //     DefaultContentView()
        // }
        DefaultContentView()
    }

    private var dismissButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                orchestrator.dismissCurrentEvent()
            }
        } label: {
            ZStack {
                // Backdrop blur
                Circle()
                    .fill(.thinMaterial)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 2)
                    .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)

                // X mark
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(isHoveringDismiss ? .white : .white.opacity(0.7))
            }
            .scaleEffect(isHoveringDismiss ? 1.15 : 1.0)
            .rotationEffect(.degrees(isHoveringDismiss ? 90 : 0))
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .help("Dismiss")
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                isHoveringDismiss = hovering
            }
        }
    }
}
