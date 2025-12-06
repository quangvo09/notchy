import SwiftUI
import Combine

/// Central hub for managing all notch events
/// Singleton that monitors, queues, and dispatches events
@MainActor
class EventMonitor: ObservableObject {
    static let shared = EventMonitor()

    /// Active events sorted by priority (highest first)
    @Published var activeEvents: [any NotchEvent] = []

    /// Callback when notch should auto-expand for an event
    var onEventPosted: (() -> Void)?

    /// Callback when event is dismissed (notch should compact)
    var onEventDismissed: (() -> Void)?

    private var dismissTasks: [UUID: Task<Void, Never>] = [:]

    private init() {
        print("📊 EventMonitor: Initialized")
    }

    /// Post a new event
    /// - Parameter event: The event to post
    func postEvent(_ event: any NotchEvent) {
        print("🔔 EventMonitor: Posting event '\(event.title)' (priority: \(event.priority))")

        // Add event to queue
        activeEvents.append(event)

        // Sort by priority (highest first)
        activeEvents.sort { $0.priority > $1.priority }

        // Trigger auto-expand
        onEventPosted?()

        // Setup auto-dismiss if configured
        if event.autoDismiss, let delay = event.dismissAfter {
            let task = Task { @MainActor in
                do {
                    try await Task.sleep(for: .seconds(delay))
                    print("⏰ EventMonitor: Auto-dismissing '\(event.title)'")
                    dismissEvent(event.id)
                } catch {
                    // Task was cancelled
                }
            }
            dismissTasks[event.id] = task
        }
    }

    /// Dismiss a specific event
    /// - Parameter id: ID of the event to dismiss
    func dismissEvent(_ id: UUID) {
        // Cancel auto-dismiss task if exists
        dismissTasks[id]?.cancel()
        dismissTasks.removeValue(forKey: id)

        // Remove from active events
        if let index = activeEvents.firstIndex(where: { $0.id == id }) {
            let event = activeEvents[index]
            print("❌ EventMonitor: Dismissed '\(event.title)'")
            activeEvents.remove(at: index)

            // If no more events, trigger compact callback
            if activeEvents.isEmpty {
                print("🔽 EventMonitor: No more events, triggering compact")
                onEventDismissed?()
            }
        }
    }

    /// Dismiss all events
    func dismissAll() {
        print("🗑️ EventMonitor: Dismissing all events")

        // Cancel all auto-dismiss tasks
        dismissTasks.values.forEach { $0.cancel() }
        dismissTasks.removeAll()

        // Clear events
        let hadEvents = !activeEvents.isEmpty
        activeEvents.removeAll()

        // Trigger compact callback if we had events
        if hadEvents {
            print("🔽 EventMonitor: All events dismissed, triggering compact")
            onEventDismissed?()
        }
    }

    /// Get the highest priority event (to be shown)
    var currentEvent: (any NotchEvent)? {
        activeEvents.first
    }

    /// Check if there are any active events
    var hasEvents: Bool {
        !activeEvents.isEmpty
    }
}
