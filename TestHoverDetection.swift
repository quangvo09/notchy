// Test file to demonstrate the new hover detection feature
import SwiftUI

// Example usage of the new hover detection modes:

// 1. Immediate expansion (current behavior)
let immediateNotch = DynamicNotch(
    hoverDetectionMode: .immediate,
    expanded: { /* content */ }
)

// 2. Simple delayed expansion
let delayedNotch = DynamicNotch(
    hoverDetectionMode: .delayed(1.0), // Wait 1 second before expanding
    expanded: { /* content */ }
)

// 3. Smart detection with custom parameters
let smartNotch = DynamicNotch(
    hoverDetectionMode: .smartDetection(
        hoverDelay: 0.3,        // Total hover time needed: 300ms
        velocityThreshold: 800, // Max mouse speed: 800 pts/sec
        minHoverDuration: 0.1   // Minimum hover: 100ms
    ),
    expanded: { /* content */ }
)

// 4. Very sensitive smart detection (expands easily)
let sensitiveNotch = DynamicNotch(
    hoverDetectionMode: .smartDetection(
        hoverDelay: 0.2,        // 200ms
        velocityThreshold: 1200, // Allow faster mouse movement
        minHoverDuration: 0.05  // Only need to hover for 50ms
    ),
    expanded: { /* content */ }
)

// 5. Very strict smart detection (harder to expand accidentally)
let strictNotch = DynamicNotch(
    hoverDetectionMode: .smartDetection(
        hoverDelay: 1.0,        // 1 second
        velocityThreshold: 200, // Mouse must be very slow
        minHoverDuration: 0.5   // Must hover for 500ms
    ),
    expanded: { /* content */ }
)

/*
The smart detection algorithm works as follows:

1. When mouse enters the notch area:
   - Start tracking hover time
   - Begin monitoring mouse velocity
   - Set up a delayed expansion task

2. While hovering:
   - Continuously track mouse position and calculate velocity
   - If mouse moves faster than velocityThreshold, cancel expansion
   - Must maintain hover for minHoverDuration

3. After conditions are met:
   - If total hover time exceeds hoverDelay AND
   - Mouse velocity stayed below threshold,
   - The notch expands

This prevents accidental expansions when:
- Quickly moving mouse across the notch
- Briefly touching the notch area
- Making jerky mouse movements

The notch will still expand when:
- User deliberately hovers
- Mouse moves slowly within the notch
- Event-based expansion occurs (this bypasses hover detection)
*/