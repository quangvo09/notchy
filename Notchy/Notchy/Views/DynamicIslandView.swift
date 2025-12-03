//
//  DynamicIslandView.swift
//  Notchy
//
//  The main Dynamic Island UI
//

import SwiftUI

struct DynamicIslandView: View {
    @ObservedObject var windowManager: WindowManager

    @State private var isExpanded = false
    @State private var isVisible = true
    @State private var hoverDebounceTimer: Timer?

    // Animation parameters (tuned to match iPhone)
    let springResponse: Double = 0.4
    let springDamping: Double = 0.75

    // Dimensions
    let collapsedWidth: CGFloat = 120
    let collapsedHeight: CGFloat = 35
    let expandedWidth: CGFloat = 320
    let expandedHeight: CGFloat = 100

    var body: some View {
        HoverableView(
            content: islandContent,
            onEnter: {
                handleMouseEnter()
            },
            onExit: {
                handleMouseExit()
            }
        )
    }

    var islandContent: some View {
        ZStack {
            // Background with blur effect
            RoundedRectangle(cornerRadius: isExpanded ? 25 : 17.5, style: .continuous)
                .fill(.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: isExpanded ? 25 : 17.5, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: isExpanded ? 20 : 10, x: 0, y: 5)

            // Content
            content
                .padding(.horizontal, isExpanded ? 16 : 8)
                .padding(.vertical, isExpanded ? 12 : 8)
        }
        .frame(
            width: isExpanded ? expandedWidth : collapsedWidth,
            height: isExpanded ? expandedHeight : collapsedHeight
        )
        .animation(.spring(response: springResponse, dampingFraction: springDamping), value: isExpanded)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.5, anchor: .top)
        .onChange(of: isExpanded) { newValue in
            // Update window size when expanding/collapsing
            let width = newValue ? expandedWidth : collapsedWidth
            let height = newValue ? expandedHeight : collapsedHeight
            windowManager.updateWindowSize(width: width, height: height, animated: true)
        }
    }

    @ViewBuilder
    var content: some View {
        if isExpanded {
            expandedContent
        } else {
            collapsedContent
        }
    }

    var collapsedContent: some View {
        HStack(spacing: 8) {
            Image(systemName: "music.note")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            Text("Notchy")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
        }
    }

    var expandedContent: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "music.note.list")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Dynamic Island")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Text("macOS Edition")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Button(action: {
                    withAnimation {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }

            // Interactive controls
            HStack(spacing: 12) {
                Button(action: {
                    print("⏮️ Previous")
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.white.opacity(0.15)))
                }
                .buttonStyle(.plain)

                Button(action: {
                    print("⏯️ Play/Pause")
                }) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(.white.opacity(0.2)))
                }
                .buttonStyle(.plain)

                Button(action: {
                    print("⏭️ Next")
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.white.opacity(0.15)))
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.9)),
            removal: .opacity
        ))
    }

    // MARK: - Hover Handling

    private func handleMouseEnter() {
        // Cancel any pending collapse
        hoverDebounceTimer?.invalidate()

        // Expand immediately
        withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
            isExpanded = true
        }

        print("🖱️ Mouse entered - expanding")
    }

    private func handleMouseExit() {
        // Debounce the collapse (delay by 300ms)
        hoverDebounceTimer?.invalidate()
        hoverDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
                isExpanded = false
            }
            print("🖱️ Mouse exited - collapsing")
        }
    }
}

// MARK: - Preview

#Preview {
    DynamicIslandView(windowManager: WindowManager.shared)
        .frame(width: 320, height: 100)
        .background(.gray)
}
