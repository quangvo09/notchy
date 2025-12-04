//
//  DynamicNotchManager.swift
//  Notchy
//
//  Manages DynamicNotchKit integration
//

import SwiftUI
import DynamicNotchKit

class DynamicNotchManager: ObservableObject {
    static let shared = DynamicNotchManager()

    @Published var notch: DynamicNotch<AnyView, AnyView, AnyView>?
    @Published var isExpanded = false

    private init() {
        setupNotch()
    }

    private func setupNotch() {
        // Create DynamicNotch with automatic style (notch or floating)
        notch = DynamicNotch(
            hoverBehavior: [.hapticFeedback, .keepVisible],
            style: .auto
        ) {
            // Expanded content
            AnyView(ExpandedNotchContent())
        } compactLeading: {
            // Compact leading (left side of notch)
            AnyView(CompactLeadingContent())
        } compactTrailing: {
            // Compact trailing (right side of notch)
            AnyView(EmptyView())
        }

        // Start in compact mode
        Task {
            await notch?.compact()
        }
    }

    func expand() {
        isExpanded = true
        Task {
            await notch?.expand()
        }
    }

    func collapse() {
        isExpanded = false
        Task {
            await notch?.compact()
        }
    }

    func hide() {
        isExpanded = false
        Task {
            await notch?.hide()
        }
    }
}

// MARK: - Compact Leading Content

struct CompactLeadingContent: View {
    @ObservedObject var mediaPlayer = MediaPlayerService.shared

    var body: some View {
        HStack(spacing: 6) {
            // Icon
            Image(systemName: mediaPlayer.hasActiveMedia
                  ? (mediaPlayer.nowPlaying.isPlaying ? "play.circle.fill" : "pause.circle.fill")
                  : "music.note")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            // Track info
            if mediaPlayer.hasActiveMedia {
                VStack(alignment: .leading, spacing: 1) {
                    Text(mediaPlayer.nowPlaying.trackName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(mediaPlayer.nowPlaying.artistName)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                .frame(maxWidth: 120)
            } else {
                Text("Notchy")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

// MARK: - Expanded Content

struct ExpandedNotchContent: View {
    @ObservedObject var mediaPlayer = MediaPlayerService.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject var stateManager = IslandStateManager.shared

    var body: some View {
        VStack(spacing: 16) {
            if stateManager.currentMode == .notification && notificationManager.hasNotification {
                notificationContent
            } else if stateManager.currentMode == .music && mediaPlayer.hasActiveMedia {
                musicPlayerContent
            } else {
                defaultContent
            }
        }
        .frame(width: 340, height: 200)
        .padding(20)
    }

    // MARK: - Music Player Content

    private var musicPlayerContent: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "music.note.list")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mediaPlayer.nowPlaying.trackName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(mediaPlayer.nowPlaying.artistName)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()

                Button(action: {
                    DynamicNotchManager.shared.collapse()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }

            // Album
            if !mediaPlayer.nowPlaying.albumName.isEmpty {
                Text(mediaPlayer.nowPlaying.albumName)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()

            // Controls
            HStack(spacing: 14) {
                Button(action: { mediaPlayer.previousTrack() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.white.opacity(0.15)))
                }
                .buttonStyle(.plain)

                Button(action: { mediaPlayer.playPause() }) {
                    Image(systemName: mediaPlayer.nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 54, height: 54)
                        .background(Circle().fill(.white.opacity(0.2)))
                }
                .buttonStyle(.plain)

                Button(action: { mediaPlayer.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.white.opacity(0.15)))
                }
                .buttonStyle(.plain)
            }

            // Source
            HStack(spacing: 4) {
                Image(systemName: mediaPlayer.nowPlaying.source == .spotify ? "s.circle.fill" : "applelogo")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))

                Text(mediaPlayer.nowPlaying.source == .spotify ? "Spotify" : "Apple Music")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }

    // MARK: - Notification Content

    private var notificationContent: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: notificationManager.currentNotification.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text(notificationManager.currentNotification.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(notificationManager.currentNotification.message)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }

                Spacer()

                Button(action: {
                    notificationManager.dismissNotification()
                    DynamicNotchManager.shared.collapse()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    // MARK: - Default Content

    private var defaultContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "island.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(.white.opacity(0.3))

            Text("Dynamic Island for macOS")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)

            Text("Hover to expand • Click to interact")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}
