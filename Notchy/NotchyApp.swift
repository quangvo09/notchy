import SwiftUI

@main
struct NotchyApp: App {
    var body: some Scene {
        WindowGroup {
            NotchHostView()
                .frame(width: 0, height: 0)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1, height: 1)
    }
}
