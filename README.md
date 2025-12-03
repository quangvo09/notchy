# Notchy 🏝️

Dynamic Island for macOS - Bringing iPhone's most delightful UI to your Mac.

![Platform](https://img.shields.io/badge/platform-macOS%2012.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

✨ **Smooth Animations** - High-fidelity spring animations matching iPhone's Dynamic Island
🖱️ **Hover Detection** - Automatically expands when you hover over it
🎨 **Beautiful Design** - Blur effects, shadows, and polished UI
🎯 **Notch-Aware** - Automatically positions itself in the notch area on supported Macs
🖥️ **Multi-Monitor** - Adjusts position when screens change
⚡ **Lightweight** - Menu bar app that stays out of your way

## Screenshots

### Collapsed State
The island sits quietly in your notch, showing minimal information.

### Expanded State
Hover to reveal interactive controls and detailed information.

## Requirements

- macOS 12.0 (Monterey) or later
- Xcode 15.0+ (for building)
- Works best on MacBooks with a notch (14" & 16" MacBook Pro)
- Also works on non-notched Macs (positions at top center)

## Installation

### Option 1: Build from Source

1. Clone the repository:
   ```bash
   cd /path/to/notchy
   ```

2. Open in Xcode:
   ```bash
   open Notchy/Notchy.xcodeproj
   ```

3. Build and run:
   - Press `⌘ + R` in Xcode
   - Or use the build script: `./build_and_run.sh`

### Option 2: Quick Run Script

```bash
./build_and_run.sh
```

## Usage

1. **Launch the App**: Run Notchy from Xcode or the build script
2. **Find the Island**: Look at the top center of your screen (in the notch area)
3. **Hover to Expand**: Move your mouse over the island to see it expand
4. **Interact**: Click buttons, close with the ✕ button
5. **Quit**: Click the menu bar icon (🏝️) and select "Quit"

## Project Structure

```
Notchy/
├── Notchy/
│   ├── NotchyApp.swift          # Main app entry point
│   ├── AppDelegate.swift        # Menu bar and lifecycle management
│   ├── WindowManager.swift      # Floating window management
│   ├── Views/
│   │   ├── DynamicIslandView.swift    # Main island UI
│   │   └── HoverableView.swift        # Hover detection wrapper
│   ├── Models/                  # (Future: State management)
│   ├── Assets.xcassets/         # App icons and resources
│   └── Info.plist              # App configuration
└── Notchy.xcodeproj/           # Xcode project
```

## Architecture

### Key Components

1. **NotchyApp.swift** - SwiftUI app entry with AppDelegate integration
2. **AppDelegate** - Manages menu bar item and application lifecycle
3. **WindowManager** - Singleton that creates and manages the floating borderless window
4. **DynamicIslandView** - SwiftUI view with collapsed/expanded states
5. **HoverableView** - NSViewRepresentable wrapper for AppKit hover detection

### How It Works

```
┌─────────────────────────────────────────────┐
│         Notchy App (Menu Bar)               │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│         WindowManager Singleton             │
│  • Creates borderless window                │
│  • Detects notch via safeAreaInsets         │
│  • Positions window                         │
│  • Handles screen changes                   │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│         Floating Window                     │
│  • Always on top (statusBar level)          │
│  • Transparent background                   │
│  • No chrome, borderless                    │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│         HoverableView (AppKit)              │
│  • NSTrackingArea for hover                 │
│  • Triggers expand/collapse                 │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│      DynamicIslandView (SwiftUI)            │
│  • Collapsed: 120×35pt pill                 │
│  • Expanded: 320×100pt card                 │
│  • Spring animations                        │
│  • Interactive buttons                      │
└─────────────────────────────────────────────┘
```

## Customization

### Animation Tuning

Edit `DynamicIslandView.swift` to adjust animation parameters:

```swift
let springResponse: Double = 0.4      // Animation duration
let springDamping: Double = 0.75      // Bounce/stiffness
```

### Dimensions

```swift
let collapsedWidth: CGFloat = 120
let collapsedHeight: CGFloat = 35
let expandedWidth: CGFloat = 320
let expandedHeight: CGFloat = 100
```

### Hover Delay

Change debounce time in `handleMouseExit()`:

```swift
hoverDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, ...)  // 300ms
```

## Development

### Building

```bash
cd Notchy
xcodebuild -project Notchy.xcodeproj -scheme Notchy -configuration Debug build
```

### Running

```bash
open ~/Library/Developer/Xcode/DerivedData/Notchy-*/Build/Products/Debug/Notchy.app
```

### Debugging

- Console logs are visible in Xcode's console (⌘ + ⇧ + C)
- Look for emoji-prefixed logs: 🖥️ 🔍 ✅ 🖱️

### Clean Build

```bash
xcodebuild clean -project Notchy.xcodeproj -scheme Notchy
rm -rf ~/Library/Developer/Xcode/DerivedData/Notchy-*
```

## Roadmap

### MVP (Current)
- [x] Floating window in notch area
- [x] Hover detection
- [x] Smooth expand/collapse animations
- [x] Interactive buttons
- [x] Multi-monitor support

### Future Features
- [ ] Media playback integration (Now Playing)
- [ ] Notification integration
- [ ] Calendar events
- [ ] System stats (CPU, memory, network)
- [ ] Customizable widgets
- [ ] Keyboard shortcuts
- [ ] Settings panel
- [ ] App integrations (Spotify, Music, etc.)
- [ ] Long-press gestures
- [ ] Swipe to dismiss
- [ ] Multiple island styles/themes

## Technical Details

### Notch Detection

```swift
let hasNotch = NSScreen.main?.safeAreaInsets.top > 0
```

On MacBooks with notch, `safeAreaInsets.top` is ~32px. On regular Macs, it's 0.

### Window Configuration

```swift
window.level = .statusBar              // Always on top
window.backgroundColor = .clear        // Transparent
window.isOpaque = false                // Allow blur effects
window.ignoresMouseEvents = false      // Enable interactions
window.collectionBehavior = [
    .canJoinAllSpaces,                 // Visible on all desktops
    .stationary,                       // Doesn't move
    .ignoresCycle                      // Not in ⌘ + Tab
]
```

## Troubleshooting

### Island doesn't appear
- Check Console.app for errors
- Ensure macOS 12.0+
- Try repositioning: Change screen resolution and back

### Hover doesn't work
- Verify `ignoresMouseEvents = false` in WindowManager
- Check NSTrackingArea setup in HoverableView

### Animation is janky
- Reduce spring stiffness
- Profile with Instruments
- Check for view hierarchy depth

### App won't build
- Clean build folder (⌘ + ⇧ + K)
- Delete DerivedData
- Verify Xcode version (15.0+)

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - See LICENSE file for details

## Credits

- Inspired by iPhone's Dynamic Island
- Built with SwiftUI and AppKit
- Created with ❤️ for the Mac community

## Contact

- GitHub Issues: [Report a bug](https://github.com/yourusername/notchy/issues)
- Discussions: [Feature requests](https://github.com/yourusername/notchy/discussions)

---

**Note**: This is an MVP implementation. The goal is to capture the essence of Dynamic Island's delightful interactions on macOS. Contributions to add more features are welcome!
