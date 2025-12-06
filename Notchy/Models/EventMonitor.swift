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
    var onEventDismissed: (() async -> Void)?

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

        // Find the event to dismiss
        guard let index = activeEvents.firstIndex(where: { $0.id == id }) else {
            return
        }

        let event = activeEvents[index]

        // If this is the last event, we need to compact first, then remove
        if activeEvents.count == 1 {
            print("🔽 EventMonitor: Last event '\(event.title)', compacting before removal")

            // Call compact callback and wait for it to complete
            Task { @MainActor in
                await onEventDismissed?()
                print("❌ EventMonitor: Removing '\(event.title)' after compact")
                activeEvents.remove(at: index)
            }
        } else {
            // If there are other events, remove immediately
            print("❌ EventMonitor: Dismissed '\(event.title)' (other events remain)")
            activeEvents.remove(at: index)
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
            Task { @MainActor in
                await onEventDismissed?()
            }
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
