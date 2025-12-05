import SwiftUI

@MainActor
class NotchManager: ObservableObject {
    @Published var dynamicNotch: DynamicNotch<AnyView, AnyView, AnyView>?
    let monitor = ForegroundAppMonitor.shared

    func showNotch() async {
        print("🚀 NotchManager: Creating DynamicNotch")

        dynamicNotch = DynamicNotch(
            hoverBehavior: .all,  // Automatically handles hover-to-expand
            expanded: {
                AnyView(
                    ExpandedContentView()
                        .environmentObject(self.monitor)
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
    }
}
