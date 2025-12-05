import SwiftUI

struct NotchHostView: View {
    @StateObject private var manager = NotchManager()

    var body: some View {
        Color.clear
            .task {
                await manager.showNotch()
            }
    }
}
