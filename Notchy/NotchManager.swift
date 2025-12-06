import SwiftUI

@MainActor
class NotchManager: ObservableObject {
    @Published var dynamicNotch: DynamicNotch<AnyView, AnyView, AnyView>?

    let monitor = ForegroundAppMonitor.shared
    let orchestrator = NotchContentOrchestrator()
    let eventMonitor = EventMonitor.shared

    // Event monitors
    private var cpuMonitor: CPUMonitor?
    private var loginMonitor: LoginMonitor?

    func showNotch() async {
        print("🚀 NotchManager: Creating DynamicNotch")

        dynamicNotch = DynamicNotch(
            hoverBehavior: .all,  // Automatically handles hover-to-expand
            expanded: {
                AnyView(
                    ExpandedContentView()
                        .environmentObject(self.monitor)
                        .environmentObject(self.orchestrator)
                )
            },
            compactLeading: {
                AnyView(EmptyView())
            },
            compactTrailing: {
                AnyView(EmptyView())
            }
        )

        await dynamicNotch?.compact()
        print("✅ Ready! Hover automatically expands the notch")

        // Setup event monitoring
        setupEventMonitoring()
    }

    private func setupEventMonitoring() {
        print("🔧 NotchManager: Setting up event monitoring")

        // Setup auto-expand on event
        eventMonitor.onEventPosted = { [weak self] in
            Task { @MainActor in
                print("🎯 NotchManager: Event posted, auto-expanding notch")
                await self?.dynamicNotch?.expand()
            }
        }

        // Setup auto-compact on event dismissal
        eventMonitor.onEventDismissed = { [weak self] in
            await withCheckedContinuation { continuation in
                Task { @MainActor in
                    print("🔽 NotchManager: Event dismissed, auto-compacting notch")
                    await self?.dynamicNotch?.compact()
                    continuation.resume()
                }
            }
        }

        // Start CPU monitoring
        cpuMonitor = CPUMonitor(threshold: 80.0, checkInterval: 30.0)
        cpuMonitor?.startMonitoring()

        // Check for welcome message
        loginMonitor = LoginMonitor()
        loginMonitor?.checkLoginEvent()

        print("✅ NotchManager: Event monitoring active")
    }

    // Note: Monitors will be cleaned up automatically when deinited
}
