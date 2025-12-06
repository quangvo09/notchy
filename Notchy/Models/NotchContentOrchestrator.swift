import SwiftUI
import Combine

/// Content display mode for the notch
enum NotchContentMode: Equatable {
    case context  // Show context-based view for active app
    case event(UUID)  // Show event notification with given ID

    static func == (lhs: NotchContentMode, rhs: NotchContentMode) -> Bool {
        switch (lhs, rhs) {
        case (.context, .context):
            return true
        case (.event(let lhsId), .event(let rhsId)):
            return lhsId == rhsId
        default:
            return false
        }
    }
}

/// Orchestrates what content to display in the notch
/// Decides between context-aware views and event notifications
@MainActor
class NotchContentOrchestrator: ObservableObject {
    @Published var mode: NotchContentMode = .context

    private let eventMonitor = EventMonitor.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        print("🎭 NotchContentOrchestrator: Initialized")
        setupEventObserver()
    }

    private func setupEventObserver() {
        // Watch for changes in active events
        eventMonitor.$activeEvents
            .sink { [weak self] events in
                if let topEvent = events.first {
                    // Show highest priority event
                    print("🎭 NotchContentOrchestrator: Switching to event mode '\(topEvent.title)'")
                    self?.mode = .event(topEvent.id)
                } else {
                    // No events, show context view
                    print("🎭 NotchContentOrchestrator: Switching to context mode")
                    self?.mode = .context
                }
            }
            .store(in: &cancellables)
    }

    /// Dismiss the currently displayed event
    func dismissCurrentEvent() {
        if case .event(let eventId) = mode {
            print("🎭 NotchContentOrchestrator: User dismissed current event")
            eventMonitor.dismissEvent(eventId)
        }
    }

    /// Get the current event being displayed (if any)
    func getCurrentEvent() -> (any NotchEvent)? {
        if case .event(let eventId) = mode {
            return eventMonitor.activeEvents.first { $0.id == eventId }
        }
        return nil
    }
}
