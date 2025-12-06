import SwiftUI

/// Simple content view for default context
struct SimpleContentView: View {
    var body: some View {
        ZStack {
            // Background layer with gradient
            backgroundGradient
                .edgesIgnoringSafeArea(.all)

            // Content layer
            VStack(spacing: 12) {
                // Icon with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: "app.dashed")
                        .font(.title)
                        .foregroundStyle(.white)
                }

                VStack(spacing: 4) {
                    Text("Notchy")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Your smart notch assistant")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }

    // Background with gradient similar to welcome view
    private var backgroundGradient: some View {
        ZStack {
            // Pure black base
            Color.black

            // Gradient from bottom fading up
            VStack(spacing: 0) {
                Spacer()

                LinearGradient(
                    colors: [
                        .clear,
                        .blue.opacity(0.1),
                        .purple.opacity(0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
            }
        }
    }
}

#Preview {
    SimpleContentView()
        .frame(width: 500, height: 100)
        .background(.ultraThickMaterial)
        .cornerRadius(20)
}