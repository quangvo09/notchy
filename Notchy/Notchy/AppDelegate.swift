//
//  AppDelegate.swift
//  Notchy
//
//  Manages menu bar and application lifecycle
//

import AppKit
import SwiftUI
import DynamicNotchKit
import Combine
import UserNotifications

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var notchManager: DynamicNotchManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon (make it a menu bar app)
        NSApp.setActivationPolicy(.accessory)

        // Create menu bar status item
        setupMenuBar()

        // Initialize DynamicNotchKit
        notchManager = DynamicNotchManager.shared

        // No need to observe screen changes - DynamicNotchKit handles this automatically
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "🏝️"
            button.toolTip = "Notchy - Dynamic Island for macOS"
        }

        // Create menu
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Expand Island", action: #selector(expandClicked), keyEquivalent: "e"))
        menu.addItem(NSMenuItem(title: "Show Test Notification", action: #selector(testNotificationClicked), keyEquivalent: "n"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About Notchy", action: #selector(aboutClicked), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitClicked), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc func expandClicked() {
        notchManager?.expand()
    }

    @objc func testNotificationClicked() {
        NotificationManager.shared.showTestNotification()
        notchManager?.expand()
    }

    @objc func aboutClicked() {
        let alert = NSAlert()
        alert.messageText = "Notchy"
        alert.informativeText = "Dynamic Island for macOS\nPowered by DynamicNotchKit\nVersion 1.0"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc func quitClicked() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Media Player Service

struct NowPlayingInfo {
    var trackName: String
    var artistName: String
    var albumName: String
    var isPlaying: Bool
    var playerState: PlayerState
    var artworkURL: String?
    var source: MediaSource

    enum MediaSource {
        case appleMusic
        case spotify
        case none
    }

    enum PlayerState {
        case playing
        case paused
        case stopped
    }

    static let empty = NowPlayingInfo(
        trackName: "",
        artistName: "",
        albumName: "",
        isPlaying: false,
        playerState: .stopped,
        artworkURL: nil,
        source: .none
    )
}

class MediaPlayerService: ObservableObject {
    static let shared = MediaPlayerService()

    @Published var nowPlaying: NowPlayingInfo = .empty
    @Published var hasActiveMedia: Bool = false

    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 2.0

    private init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        updateNowPlaying()
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateNowPlaying()
        }
    }

    func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func updateNowPlaying() {
        if let spotifyInfo = getSpotifyInfo() {
            DispatchQueue.main.async {
                self.nowPlaying = spotifyInfo
                self.hasActiveMedia = spotifyInfo.isPlaying
            }
        } else if let musicInfo = getAppleMusicInfo() {
            DispatchQueue.main.async {
                self.nowPlaying = musicInfo
                self.hasActiveMedia = musicInfo.isPlaying
            }
        } else {
            DispatchQueue.main.async {
                self.nowPlaying = .empty
                self.hasActiveMedia = false
            }
        }
    }

    private func getSpotifyInfo() -> NowPlayingInfo? {
        let script = """
        tell application "System Events"
            set spotifyRunning to (name of processes) contains "Spotify"
        end tell

        if spotifyRunning then
            tell application "Spotify"
                if player state is not stopped then
                    set trackName to name of current track
                    set artistName to artist of current track
                    set albumName to album of current track
                    set isPlaying to (player state is playing)
                    set artworkURL to artwork url of current track

                    return trackName & "|||" & artistName & "|||" & albumName & "|||" & isPlaying & "|||" & artworkURL
                end if
            end tell
        end if
        return ""
        """

        guard let result = runAppleScript(script), !result.isEmpty else {
            return nil
        }

        let parts = result.components(separatedBy: "|||")
        guard parts.count >= 4 else { return nil }

        return NowPlayingInfo(
            trackName: parts[0],
            artistName: parts[1],
            albumName: parts[2],
            isPlaying: parts[3].lowercased() == "true",
            playerState: parts[3].lowercased() == "true" ? .playing : .paused,
            artworkURL: parts.count > 4 ? parts[4] : nil,
            source: .spotify
        )
    }

    private func getAppleMusicInfo() -> NowPlayingInfo? {
        let script = """
        tell application "System Events"
            set musicRunning to (name of processes) contains "Music"
        end tell

        if musicRunning then
            tell application "Music"
                if player state is not stopped then
                    set trackName to name of current track
                    set artistName to artist of current track
                    set albumName to album of current track
                    set isPlaying to (player state is playing)

                    return trackName & "|||" & artistName & "|||" & albumName & "|||" & isPlaying
                end if
            end tell
        end if
        return ""
        """

        guard let result = runAppleScript(script), !result.isEmpty else {
            return nil
        }

        let parts = result.components(separatedBy: "|||")
        guard parts.count >= 4 else { return nil }

        return NowPlayingInfo(
            trackName: parts[0],
            artistName: parts[1],
            albumName: parts[2],
            isPlaying: parts[3].lowercased() == "true",
            playerState: parts[3].lowercased() == "true" ? .playing : .paused,
            artworkURL: nil,
            source: .appleMusic
        )
    }

    func playPause() {
        switch nowPlaying.source {
        case .spotify:
            runAppleScript("tell application \"Spotify\" to playpause")
        case .appleMusic:
            runAppleScript("tell application \"Music\" to playpause")
        case .none:
            break
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.updateNowPlaying()
        }
    }

    func nextTrack() {
        switch nowPlaying.source {
        case .spotify:
            runAppleScript("tell application \"Spotify\" to next track")
        case .appleMusic:
            runAppleScript("tell application \"Music\" to next track")
        case .none:
            break
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.updateNowPlaying()
        }
    }

    func previousTrack() {
        switch nowPlaying.source {
            case .spotify:
            runAppleScript("tell application \"Spotify\" to previous track")
        case .appleMusic:
            runAppleScript("tell application \"Music\" to previous track")
        case .none:
            break
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.updateNowPlaying()
        }
    }

    private func runAppleScript(_ script: String) -> String? {
        var error: NSDictionary?
        guard let scriptObject = NSAppleScript(source: script) else {
            return nil
        }

        let output = scriptObject.executeAndReturnError(&error)

        if let error = error {
            print("❌ AppleScript error: \(error)")
            return nil
        }

        return output.stringValue
    }
}

// MARK: - Notification Manager

struct IslandNotification {
    var title: String
    var message: String
    var icon: String
    var timestamp: Date

    static let empty = IslandNotification(
        title: "",
        message: "",
        icon: "bell.fill",
        timestamp: Date()
    )
}

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var currentNotification: IslandNotification = .empty
    @Published var hasNotification: Bool = false

    private override init() {
        super.init()
        requestPermissions()
    }

    private func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permissions granted")
            } else {
                print("❌ Notification permissions denied")
            }
        }
    }

    func showNotification(title: String, message: String, icon: String = "bell.fill", duration: TimeInterval = 4.0) {
        let notification = IslandNotification(
            title: title,
            message: message,
            icon: icon,
            timestamp: Date()
        )

        DispatchQueue.main.async {
            self.currentNotification = notification
            self.hasNotification = true
            IslandStateManager.shared.setMode(.notification, duration: duration)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.dismissNotification()
        }
    }

    func dismissNotification() {
        DispatchQueue.main.async {
            self.hasNotification = false
            self.currentNotification = .empty
        }
    }

    func showTestNotification() {
        let messages = [
            ("Message Received", "Hey! How are you doing?", "message.fill"),
            ("Calendar", "Meeting in 5 minutes", "calendar"),
            ("Reminder", "Time to take a break", "bell.fill"),
            ("Download Complete", "YourFile.zip is ready", "arrow.down.circle.fill"),
            ("Battery Low", "15% remaining", "battery.25")
        ]

        let random = messages.randomElement()!
        showNotification(title: random.0, message: random.1, icon: random.2)
    }
}

// MARK: - Island State Manager

enum IslandMode {
    case idle
    case music
    case notification
    case timer
    case activity

    var priority: Int {
        switch self {
        case .notification: return 100
        case .timer: return 80
        case .music: return 60
        case .activity: return 40
        case .idle: return 0
        }
    }
}

class IslandStateManager: ObservableObject {
    static let shared = IslandStateManager()

    @Published var currentMode: IslandMode = .idle
    @Published var shouldShowContent: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupObservers()
    }

    private func setupObservers() {
        MediaPlayerService.shared.$hasActiveMedia
            .sink { [weak self] _ in
                self?.updateMode()
            }
            .store(in: &cancellables)

        NotificationManager.shared.$hasNotification
            .sink { [weak self] _ in
                self?.updateMode()
            }
            .store(in: &cancellables)
    }

    private func updateMode() {
        if NotificationManager.shared.hasNotification {
            currentMode = .notification
            shouldShowContent = true
        } else if MediaPlayerService.shared.hasActiveMedia {
            currentMode = .music
            shouldShowContent = true
        } else {
            currentMode = .idle
            shouldShowContent = false
        }
    }

    func setMode(_ mode: IslandMode, duration: TimeInterval? = nil) {
        currentMode = mode
        shouldShowContent = mode != .idle

        if let duration = duration {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                self?.dismissMode(mode)
            }
        }
    }

    func dismissMode(_ mode: IslandMode) {
        guard currentMode == mode else { return }
        currentMode = .idle
        shouldShowContent = false
    }

    func showNotification(title: String, message: String, duration: TimeInterval = 3.0) {
        setMode(.notification, duration: duration)
    }
}

// MARK: - Dynamic Notch Manager

class DynamicNotchManager: ObservableObject {
    static let shared = DynamicNotchManager()

    @Published var notch: DynamicNotch<AnyView, AnyView, AnyView>?
    @Published var isExpanded = false

    private init() {
        setupNotch()
    }

    private func setupNotch() {
        Task { @MainActor in
            self.notch = DynamicNotch(
                hoverBehavior: [.hapticFeedback, .keepVisible],
                style: .auto
            ) {
                AnyView(ExpandedNotchContent())
            } compactLeading: {
                AnyView(CompactLeadingContent())
            } compactTrailing: {
                AnyView(EmptyView())
            }

            await self.notch?.compact()
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
            Image(systemName: mediaPlayer.hasActiveMedia
                  ? (mediaPlayer.nowPlaying.isPlaying ? "play.circle.fill" : "pause.circle.fill")
                  : "music.note")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

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

    private var musicPlayerContent: some View {
        VStack(spacing: 12) {
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

            if !mediaPlayer.nowPlaying.albumName.isEmpty {
                Text(mediaPlayer.nowPlaying.albumName)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()

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

    private var defaultContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(.white.opacity(0.3))

            Text("Dynamic Island for macOS")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)

            Text("Hover to expand • Play music to see controls")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }
}
