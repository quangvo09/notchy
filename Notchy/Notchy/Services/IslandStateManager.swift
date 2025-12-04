//
//  IslandStateManager.swift
//  Notchy
//
//  Manages the state and content of the Dynamic Island
//

import Foundation
import Combine

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
        // Observe media player changes
        MediaPlayerService.shared.$hasActiveMedia
            .sink { [weak self] hasMedia in
                self?.updateMode()
            }
            .store(in: &cancellables)

        // Observe notification changes
        NotificationManager.shared.$hasNotification
            .sink { [weak self] hasNotification in
                self?.updateMode()
            }
            .store(in: &cancellables)
    }

    private func updateMode() {
        // Priority order: notification > music > idle
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

    // MARK: - Mode Control

    func setMode(_ mode: IslandMode, duration: TimeInterval? = nil) {
        currentMode = mode
        shouldShowContent = mode != .idle

        // Auto-dismiss after duration if specified
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
