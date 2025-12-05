import SwiftUI

@main
struct NotchyApp: App {
    @StateObject private var notchManager = NotchManager()

    var body: some Scene {
        WindowGroup {
            // THIS IS THE KEY LINE — we actually show the notch!
            NotchHostView()
                .environmentObject(notchManager.monitor)
                .frame(width: 0, height: 0) // invisible window, just a container
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1, height: 1)
    }
}

// MARK: - Host View — Initializes and keeps the notch alive
struct NotchHostView: View {
    @StateObject private var manager = NotchManager()

    var body: some View {
        Color.clear
            .task {
                await manager.showNotch()  // creates and shows the notch
            }
    }
}

// MARK: - Notch Manager
@MainActor
class NotchManager: ObservableObject {
    @Published var dynamicNotch: DynamicNotch<AnyView, AnyView, AnyView>?
    let monitor = ForegroundAppMonitor.shared
    private var hoverTask: Task<Void, Never>?

    // Track hover state like the library does
    @Published private var isHovering = false

    func showNotch() async {
        print("🚀 NotchManager: Creating DynamicNotch")

        dynamicNotch = DynamicNotch(
            hoverBehavior: .all,
            expanded: {
                AnyView(
                    ExpandedContentView()
                        .environmentObject(self.monitor)
                        .onAppear { print("👁️ ExpandedContentView appeared!") }
                        .onHover { hovering in
                            self.updateHoverState(hovering)
                        }
                )
            },
            compactLeading: {
                AnyView(EmptyView())
            },
            compactTrailing: {
                AnyView(EmptyView())
            }
        )

        try? await Task.sleep(for: .milliseconds(100))
        await dynamicNotch?.compact()
        print("✅ Ready! Hover the top center of your screen")
    }

    // Clone of library's hover detection with custom expansion logic
    private func updateHoverState(_ hovering: Bool) {
        guard hovering != isHovering else { return }
        isHovering = hovering

        print("🖱️ Hover state changed: \(hovering)")

        hoverTask?.cancel()

        if hovering {
            // Expand immediately on hover
            hoverTask = Task { @MainActor in
                print("🖱️ Expanding...")
                await dynamicNotch?.expand()
            }
        } else {
            // Delay collapse to avoid flickering
            hoverTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                if !Task.isCancelled && !self.isHovering {
                    print("🖱️ Compacting...")
                    await dynamicNotch?.compact()
                }
            }
        }
    }
}

// MARK: - ExpandedContentView
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
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 30))
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.6)
        )
        .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
        .onAppear {
            print("🎯 ExpandedContentView: View appeared! Monitor state: dev=\(monitor.isDevelopmentEnvironment()), browser=\(monitor.isBrowser()), terminal=\(monitor.isTerminal())")
        }
        .onDisappear {
            print("🔄 ExpandedContentView: View disappeared (collapsed)")
        }
    }
}
