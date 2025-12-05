import SwiftUI

struct JumpRopeCPUView: View {
    @State private var phase: CGFloat = 0.0          // animation phase
    @State private var cpuUsage: Double = 0.15       // 0.0 – 1.0

    private let timer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 10) {
            Text("CPU is jumping!")
                .font(.caption)
                .foregroundStyle(.secondary)

            ZStack {
                // Rotating rope (rainbow style)
                Circle()
                    .trim(from: 0.05, to: 0.95)
                    .stroke(
                        AngularGradient(
                            colors: [.red, .orange, .yellow, .green, .blue, .purple, .red],
                            center: .center
                        ),
                        lineWidth: 6
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(phase * 360))
                    .hueRotation(.degrees(phase * 120))

                // Jumping person (SF Symbol + bounce)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 54))
                    .foregroundStyle(.orange)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .offset(y: jumpOffset)
            }
            .frame(height: 90)

            // CPU percentage
            Text("\(Int(cpuUsage * 100))%")
                .font(.title2.bold())
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(20)
        .onReceive(timer) { _ in
            updateCPUAndAnimate()
        }
        .onAppear {
            updateCPUAndAnimate()
        }
    }

    // MARK: - Animation Calculations
    private var jumpOffset: CGFloat {
        // Bouncy jump using sine wave
        -abs(sin(phase * .pi * 4)) * 18
    }

    private var animationSpeed: Double {
        // CPU 0% → slow (0.8×) | CPU 100% → very fast (5×)
        0.8 + (cpuUsage * 4.2)
    }

    // MARK: - CPU Monitoring + Animation
    private func updateCPUAndAnimate() {
        // Get real CPU usage using `top`
        let task = Process()
        task.launchPath = "/usr/bin/top"
        task.arguments = ["-l", "1", "-n", "0"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Use a simpler string parsing approach
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    if line.contains("CPU usage") {
                        let pattern = #"CPU usage: ([\d.]+)%"#
                        if let regex = try? NSRegularExpression(pattern: pattern) {
                            let range = NSRange(location: 0, length: line.utf16.count)
                            if let match = regex.firstMatch(in: line, range: range) {
                                if let valueRange = Range(match.range(at: 1), in: line),
                                   let value = Double(line[valueRange]) {
                                    cpuUsage = max(0.05, min(0.95, value / 100))
                                    break
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            cpuUsage = 0.15 // fallback
        }

        // Advance animation based on CPU load
        withAnimation(.linear(duration: 0.04)) {
            phase += 0.04 * animationSpeed
        }
    }
}

// MARK: - Preview
#Preview {
    JumpRopeCPUView()
        .frame(width: 340, height: 100)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
}