//
//  MediaPlayerService.swift
//  Notchy
//
//  Monitors now playing info from Apple Music and Spotify
//

import Foundation
import AppKit
import Combine

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
    private let updateInterval: TimeInterval = 2.0 // Poll every 2 seconds

    private init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Monitoring

    func startMonitoring() {
        // Initial fetch
        updateNowPlaying()

        // Start timer for periodic updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateNowPlaying()
        }
    }

    func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func updateNowPlaying() {
        // Try Spotify first, then Apple Music
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

    // MARK: - Spotify Integration

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

    // MARK: - Apple Music Integration

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

    // MARK: - Playback Controls

    func playPause() {
        switch nowPlaying.source {
        case .spotify:
            runAppleScript("tell application \"Spotify\" to playpause")
        case .appleMusic:
            runAppleScript("tell application \"Music\" to playpause")
        case .none:
            break
        }

        // Update immediately
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

        // Update immediately
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

        // Update immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.updateNowPlaying()
        }
    }

    // MARK: - AppleScript Helper

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
