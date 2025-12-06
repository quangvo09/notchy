# Notchy Architecture Documentation

> Context-aware Dynamic Island for macOS - Technical Architecture Guide

## Table of Contents

- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Core Components](#core-components)
- [DynamicNotchKit Integration](#dynamicnotchkit-integration)
- [Application Detection System](#application-detection-system)
- [Context View System](#context-view-system)
- [Script Execution Layer](#script-execution-layer)
- [State Management](#state-management)
- [Animation & UI Details](#animation--ui-details)
- [Extension Guide](#extension-guide)
- [Build System](#build-system)

---

## Overview

### Project Purpose

Notchy is a macOS application that brings Dynamic Island functionality to Mac, providing context-aware quick actions based on the currently active application. It runs persistently in the notch area (or as a floating window on non-notched Macs) and automatically adapts its interface when you switch between applications.

### Key Design Principles

1. **Context-Aware**: Different content for different app types (development tools, browsers, terminals)
2. **Non-Intrusive**: Auto-hides, expands only on hover
3. **Native Feel**: Smooth animations, system materials, macOS design patterns
4. **Extensible**: Easy to add new app contexts and custom actions
5. **Self-Contained**: Zero external dependencies, embedded DynamicNotchKit

### Technology Stack

| Layer | Technology |
|-------|-----------|
| **UI Framework** | SwiftUI |
| **Window Management** | AppKit (NSPanel, NSWindow) |
| **System Integration** | NSWorkspace, NSRunningApplication |
| **Reactive State** | Combine (@Published, ObservableObject) |
| **Concurrency** | Swift async/await |
| **Build System** | Swift Package Manager |
| **Minimum OS** | macOS 14.0 (Sequoia) |
| **Swift Version** | 5.9+ |

---

## System Architecture

### High-Level Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      NotchyApp (@main)                       │
│                     [NotchyApp.swift]                        │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                      NotchHostView                           │
│                   [NotchHostView.swift]                      │
│                 (Lifecycle Coordinator)                      │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                       NotchManager                           │
│                    [NotchManager.swift]                      │
│              (Central Controller/Coordinator)                │
│  • Creates DynamicNotch instance                            │
│  • Bridges ForegroundAppMonitor ↔ DynamicNotch             │
└───────┬──────────────────────────────────────┬──────────────┘
        │                                      │
        ▼                                      ▼
┌───────────────────┐              ┌──────────────────────────┐
│ ForegroundApp     │              │    DynamicNotch          │
│ Monitor           │──observes──▶ │  [NotchKit/...]          │
│ [Models/...]      │              │                          │
│ • NSWorkspace     │              │  ┌──────────────────┐    │
│ • App Detection   │              │  │ NotchContentView │    │
└───────────────────┘              │  └────────┬─────────┘    │
                                   │           │              │
                                   │           ▼              │
                                   │  ┌──────────────────┐    │
                                   │  │ ExpandedContent  │    │
                                   │  │      View        │    │
                                   │  │   [Views/...]    │    │
                                   │  └────────┬─────────┘    │
                                   └───────────┼──────────────┘
                                               │
                    ┌──────────────────────────┼───────────────────────┐
                    │                          │                       │
                    ▼                          ▼                       ▼
        ┌─────────────────────┐   ┌─────────────────────┐  ┌─────────────────┐
        │ DevToolsContextView │   │ BookmarksContextView│  │ GenericContext  │
        │   [Views/...]       │   │    [Views/...]      │  │   View          │
        └──────────┬──────────┘   └─────────────────────┘  │  [Views/...]    │
                   │                                        └─────────────────┘
                   ▼
        ┌─────────────────────┐
        │   ScriptRunner      │
        │  [Services/...]     │
        │ • Shell Commands    │
        │ • AppleScript       │
        └─────────────────────┘
```

### Layer Breakdown

#### 1. Application Layer
**Purpose**: App lifecycle and window management

- `NotchyApp.swift` - Entry point with @main
- `NotchHostView.swift` - Triggers initialization
- Hidden 1x1 window (actual UI shown via NSPanel overlay)

#### 2. Coordination Layer
**Purpose**: Orchestrates components and state

- `NotchManager.swift` - Creates and manages DynamicNotch
- Bridges ForegroundAppMonitor with UI
- Configures hover behavior

#### 3. Model Layer
**Purpose**: Business logic and system integration

- `ForegroundAppMonitor.swift` - Singleton for app detection
- NSWorkspace notification observers
- App categorization (dev tools, browsers, terminals)

#### 4. View Layer
**Purpose**: SwiftUI UI components

- `ExpandedContentView.swift` - Router/switcher
- Context views (DevTools, Bookmarks, Generic, etc.)
- DynamicNotchKit views (NotchView, NotchlessView)

#### 5. Service Layer
**Purpose**: External interactions

- `ScriptRunner.swift` - Shell and AppleScript execution
- Thread-safe command execution
- System integration (Terminal, Finder, browsers)

#### 6. Infrastructure Layer
**Purpose**: Window rendering and animations

- DynamicNotchKit embedded library
- NSPanel at .screenSaver level
- Animation system
- Screen detection utilities

---

## Core Components

### NotchyApp - Application Entry Point
**File**: `Notchy/NotchyApp.swift`

```swift
@main
struct NotchyApp: App {
    var body: some Scene {
        WindowGroup {
            NotchHostView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1, height: 1)
    }
}
```

**Responsibilities**:
- App entry point using `@main` attribute
- Creates hidden WindowGroup (1x1 pixel, hidden title bar)
- Actual UI rendered via DynamicNotch NSPanel overlay

**Design Note**: Window must exist for SwiftUI app lifecycle, but UI is shown through NSPanel

---

### NotchHostView - Lifecycle Coordinator
**File**: `Notchy/Views/NotchHostView.swift`

```swift
struct NotchHostView: View {
    @StateObject private var manager = NotchManager()

    var body: some View {
        Color.clear
            .task {
                await manager.showNotch()
            }
    }
}
```

**Responsibilities**:
- Owns NotchManager as @StateObject
- Triggers `showNotch()` on appear via `.task` modifier
- Provides empty view (actual UI in NSPanel)

---

### NotchManager - Central Controller
**File**: `Notchy/NotchManager.swift` (Lines 1-30)

```swift
class NotchManager: ObservableObject {
    @Published var dynamicNotch: DynamicNotch<...>?
    private let monitor = ForegroundAppMonitor.shared

    func showNotch() async {
        let notch = DynamicNotch(
            expandedContent: { ExpandedContentView() },
            compactLeadingContent: { EmptyView() },
            compactTrailingContent: { EmptyView() },
            hoverBehavior: .all  // Auto-expand on hover
        )

        await notch.compact()
        self.dynamicNotch = notch
    }
}
```

**Responsibilities**:
- Creates DynamicNotch instance with ExpandedContentView
- Configures auto-expand hover behavior (`.all`)
- Injects ForegroundAppMonitor into environment
- Manages notch lifecycle

**Key Decision**: Using `.all` hover behavior enables automatic expand/compact on mouse hover

---

### ForegroundAppMonitor - Application Detection
**File**: `Notchy/Models/ForegroundAppMonitor.swift` (Lines 1-94)

**Architecture**:
```swift
@MainActor
class ForegroundAppMonitor: ObservableObject {
    static let shared = ForegroundAppMonitor()  // Singleton

    @Published var bundleIdentifier: String?
    @Published var localizedName: String?

    private init() {
        // Setup NSWorkspace observers
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }
}
```

**Responsibilities**:
1. **App Detection** (Lines 28-50)
   - Observes `NSWorkspace.didActivateApplicationNotification`
   - Extracts bundle identifier and app name
   - Updates @Published properties reactively

2. **App Categorization** (Lines 67-93)
   - `isDevelopmentEnvironment()` - VS Code, Xcode, JetBrains, Sublime
   - `isBrowser()` - Chrome, Safari, Firefox, Arc, Brave, Vivaldi
   - `isTerminal()` - Terminal, Hyper, iTerm2

**Bundle Identifier Patterns**:
```swift
// Development
"com.microsoft.VSCode"
"com.apple.dt.Xcode"
"com.jetbrains.*"
"com.sublimetext.*"

// Browsers
"com.google.Chrome"
"com.apple.Safari"
"org.mozilla.firefox"
"company.thebrowser.Browser"  // Arc

// Terminals
"com.apple.Terminal"
"com.googlecode.iterm2"
"co.zeit.hyper"
```

**Thread Safety**: Uses `@MainActor` to ensure all updates on main thread

---

### ExpandedContentView - Context Router
**File**: `Notchy/Views/ExpandedContentView.swift` (Lines 1-28)

```swift
struct ExpandedContentView: View {
    @EnvironmentObject var monitor: ForegroundAppMonitor

    var body: some View {
        Group {
            if monitor.isDevelopmentEnvironment() {
                DevToolsContextView()
            } else if monitor.isBrowser() {
                BookmarksContextView()
            } else if monitor.isTerminal() {
                TerminalContextView()
            } else {
                JumpRopeCPUView()
            }
        }
        .frame(width: 500, height: 200)
        .background(.ultraThickMaterial)
        .cornerRadius(20)
    }
}
```

**Responsibilities**:
- Routes to appropriate context view based on active app
- Receives ForegroundAppMonitor via `@EnvironmentObject`
- Applies consistent styling (material background, corner radius)

**Routing Logic**:
1. Check development environment → DevToolsContextView
2. Check browser → BookmarksContextView
3. Check terminal → TerminalContextView
4. Default → JumpRopeCPUView (CPU animation)

**Material Effect**: `.ultraThickMaterial` provides blurred, translucent background

---

### DevToolsContextView - Development Actions
**File**: `Notchy/Views/DevToolsContextView.swift` (Lines 1-148)

**Quick Actions**:
- **npm start** (Lines 14-18): Runs `npm start` in current directory
- **Open Terminal** (Lines 20-27): Opens Terminal app
- **Stop Servers** (Lines 29-34): Kills all node/npm/yarn processes
- **Terminal Actions**: New tab, Clear, Copy path (Lines 108-147)

**Component Pattern**: Reusable `ToolButton` (Lines 40-106)
```swift
struct ToolButton: View {
    let title: String
    let icon: String
    let color: Color
    var script: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            if let action = action {
                action()
            } else if let script = script {
                ScriptRunner.runShell(script)
            }
        } label: {
            VStack {
                Image(systemName: icon)
                Text(title)
            }
        }
    }
}
```

**Design Pattern**: Either shell script string OR custom Swift closure

---

### BookmarksContextView - Browser Bookmarks
**File**: `Notchy/Views/BookmarksContextView.swift` (Lines 1-87)

**Features**:
- 2-column grid layout (Lines 12-19)
- Hover animations with scale effect (Lines 81-84)
- Opens URLs in default browser (Line 62)

**Bookmark Model**:
```swift
struct Bookmark: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let icon: String
    let color: Color
}
```

**Current Implementation**: Hardcoded bookmarks (Lines 35-40)

**Note**: `Resources/bookmarks.json` exists but not currently loaded

---

### GenericContextView - Fallback UI
**File**: `Notchy/Views/GenericContextView.swift` (Lines 1-125)

**Universal Actions**:
- **Reveal in Finder** (Lines 31-40): Shows app in Finder
- **Quit App** (Lines 42-50): Terminates current app
- **New Window** (Lines 52-71): Creates new window via AppleScript

**App Icon Display** (Lines 9-28):
- Extracts NSRunningApplication
- Displays app icon and name
- Falls back to SF Symbol if icon unavailable

---

### JumpRopeCPUView - CPU Visualization
**File**: `Notchy/Views/JumpRopeCPUView.swift` (Lines 1-114)

**Features**:
- Animated rainbow rope (Lines 17-28)
- Jumping figure SF Symbol (Lines 30-36)
- Real-time CPU percentage from `top` command (Lines 66-99)
- Animation speed scales with CPU usage (Lines 60-63)

**Update Frequency**: 0.8 seconds (Line 7)

**CPU Parsing**:
```swift
let output = try await Process.run("top -l 1 -s 0")
// Parses: "CPU usage: 15.5% user, 8.2% sys, 76.3% idle"
```

---

### ScriptRunner - Script Execution Service
**File**: `Notchy/Services/ScriptRunner.swift` (Lines 1-168)

**Key Methods**:

1. **Shell Execution** (Lines 9-35)
```swift
static func runShell(_ script: String, completion: ((String) -> Void)? = nil) {
    DispatchQueue.global(qos: .userInitiated).async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", script]
        // ... execute and capture output
    }
}
```

2. **AppleScript Execution** (Lines 37-63)
```swift
static func runAppleScript(_ script: String, completion: ((String) -> Void)? = nil) {
    DispatchQueue.global(qos: .userInitiated).async {
        var error: NSDictionary?
        let appleScript = NSAppleScript(source: script)
        let output = appleScript?.executeAndReturnError(&error)
        // ... handle result
    }
}
```

**Thread Safety**:
- Executes on background queue (`.userInitiated`)
- Callbacks dispatched to main queue (Lines 26, 55)

**Specialized Methods**:
- `openTerminal()` - Opens Terminal app (Lines 67-76)
- `copyCurrentPath()` - Copies Finder path to clipboard (Lines 78-90)
- `revealInFinder(path:)` - Shows file in Finder (Lines 100-107)
- `openNewBrowserTab(url:)` - Opens URL in browser (Lines 128-149)

---

## DynamicNotchKit Integration

### Overview

DynamicNotchKit is embedded in `Notchy/NotchKit/` (originally from [github.com/MrKai77/DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit)). It provides the core notch rendering and animation system.

### Key Components

#### 1. DynamicNotch - Core Controller
**File**: `Notchy/NotchKit/DynamicNotch/DynamicNotch.swift`

**Generic Structure**:
```swift
@MainActor
public final class DynamicNotch<Expanded: View, CompactLeading: View, CompactTrailing: View>: ObservableObject {
    @Published public var state: DynamicNotchState = .hidden
    @Published public var isHovering: Bool = false

    private var panel: DynamicNotchPanel?
    private let style: DynamicNotchStyle
    private let hoverBehavior: DynamicNotchHoverBehavior
}
```

**Responsibilities**:
- Manages NSPanel lifecycle
- Handles state transitions (.hidden → .compact → .expanded)
- Animates notch size and content
- Detects screen with notch vs floating window

**State Machine**:
```
.hidden ──▶ .compact ──▶ .expanded
   ▲                         │
   └─────────────────────────┘
```

#### 2. Custom Hover Behavior (Lines 154-167)

**Modified from original DynamicNotchKit**:
```swift
.onChange(of: isHovering) { _, hovering in
    Task { @MainActor in
        if hovering && state == .compact {
            await expand()  // Auto-expand on hover
        } else if !hovering && state == .expanded {
            try? await Task.sleep(for: .milliseconds(500))
            if !isHovering && state == .expanded {
                await compact()  // Auto-compact after 500ms
            }
        }
    }
}
```

**Key Addition**: Automatic hover-to-expand/compact not in original library

#### 3. DynamicNotchPanel - Custom NSPanel
**File**: `Notchy/NotchKit/Utility/DynamicNotchPanel.swift` (Lines 1-40)

```swift
class DynamicNotchPanel: NSPanel {
    override init(contentRect: NSRect, ...) {
        super.init(contentRect: contentRect, ...)

        self.level = .screenSaver  // Always on top
        self.collectionBehavior = [
            .canJoinAllSpaces,  // Visible on all desktops
            .stationary          // Doesn't participate in Exposé
        ]
        self.backgroundColor = .clear
        self.hasShadow = false
        self.isMovable = false
    }
}
```

**Window Configuration**:
- **Level**: `.screenSaver` - Always on top of regular windows
- **Spaces**: Visible on all desktops
- **Appearance**: Transparent, no shadow, not movable

#### 4. Screen Detection
**File**: `Notchy/NotchKit/Utility/NSScreen+Extensions.swift` (Lines 1-48)

**Notch Detection** (Line 19):
```swift
var hasNotch: Bool {
    safeAreaInsets.top > 0
}
```

**Notch Size Calculation** (Lines 23-34):
```swift
var notchSize: CGSize {
    if hasNotch {
        let topInset = safeAreaInsets.top
        return CGSize(width: 200, height: topInset)
    }
    return .zero
}
```

**Fallback for Non-Notched Macs**: Uses menubar height (Lines 46-48)

#### 5. NotchView vs NotchlessView

**NotchView** (`NotchKit/Views/NotchView.swift`):
- For Macs with physical notch
- Renders content around/below notch
- Uses NotchShape mask for rounded corners
- Compact state shows leading/trailing content on sides

**NotchlessView** (`NotchKit/Views/NotchlessView.swift`):
- For non-notched Macs
- Floating window at top center
- `.popover` material background
- Slides in/out from top

**Selection Logic** in NotchContentView (Line 42):
```swift
if style.isNotch {
    NotchView(...)
} else {
    NotchlessView(...)
}
```

### Animation System

**File**: `Notchy/NotchKit/DynamicNotch/DynamicNotchStyle.swift` (Lines 66-80)

```swift
var openingAnimation: Animation {
    isNotch ? .bouncy(duration: 0.4) : .snappy(duration: 0.4)
}

var closingAnimation: Animation {
    .smooth(duration: 0.4)
}

var conversionAnimation: Animation {
    .snappy(duration: 0.4)
}
```

**Animation Types**:
- **Opening**: Bouncy (notch) or snappy (floating)
- **Closing**: Smooth ease-out
- **Conversion** (compact ↔ expanded): Snappy

---

## Application Detection System

### How It Works

```
App Switch Event
       │
       ▼
NSWorkspace.didActivateApplicationNotification
       │
       ▼
ForegroundAppMonitor.appDidActivate(_:)
       │
       ▼
Extract NSRunningApplication from notification
       │
       ▼
Update @Published bundleIdentifier, localizedName
       │
       ▼
SwiftUI observes via @EnvironmentObject
       │
       ▼
ExpandedContentView.body re-evaluates
       │
       ▼
Conditional logic selects context view
       │
       ▼
UI updates with new context
```

### NSWorkspace Integration

**Initialization** (`ForegroundAppMonitor.swift` Lines 15-20):
```swift
private init() {
    NSWorkspace.shared.notificationCenter.addObserver(
        self,
        selector: #selector(appDidActivate),
        name: NSWorkspace.didActivateApplicationNotification,
        object: nil
    )
    updateCurrentApp()  // Get initial frontmost app
}
```

**Event Handler** (Lines 28-38):
```swift
@objc private func appDidActivate(_ notification: Notification) {
    guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                    as? NSRunningApplication else { return }

    bundleIdentifier = app.bundleIdentifier
    localizedName = app.localizedName
}
```

### App Categorization Logic

**Development Environment** (Lines 67-75):
```swift
func isDevelopmentEnvironment() -> Bool {
    guard let bundleId = bundleIdentifier else { return false }
    return bundleId.contains("com.microsoft.VSCode")
        || bundleId.contains("com.apple.dt.Xcode")
        || bundleId.contains("com.jetbrains")
        || bundleId.contains("com.sublimetext")
}
```

**Browser** (Lines 77-85):
```swift
func isBrowser() -> Bool {
    guard let bundleId = bundleIdentifier else { return false }
    return bundleId.contains("com.google.Chrome")
        || bundleId.contains("org.mozilla.firefox")
        || bundleId.contains("com.apple.Safari")
        || bundleId.contains("company.thebrowser.Browser")  // Arc
        || bundleId.contains("com.brave.Browser")
        || bundleId.contains("com.vivaldi.Vivaldi")
}
```

**Terminal** (Lines 87-93):
```swift
func isTerminal() -> Bool {
    guard let bundleId = bundleIdentifier else { return false }
    return bundleId.contains("com.apple.Terminal")
        || bundleId.contains("co.zeit.hyper")
        || bundleId.contains("com.googlecode.iterm2")
}
```

**Design Note**: Uses `contains()` for pattern matching to support versioned bundle IDs

---

## Context View System

### Router Pattern

**ExpandedContentView** acts as a router using SwiftUI conditional rendering:

```swift
@EnvironmentObject var monitor: ForegroundAppMonitor

var body: some View {
    Group {
        if monitor.isDevelopmentEnvironment() {
            DevToolsContextView()
        } else if monitor.isBrowser() {
            BookmarksContextView()
        } else if monitor.isTerminal() {
            TerminalContextView()
        } else {
            JumpRopeCPUView()  // Fallback
        }
    }
}
```

**Reactive Updates**: SwiftUI automatically re-evaluates when `@Published` properties change

### Context View Responsibilities

| Context View | App Types | Primary Actions |
|--------------|-----------|-----------------|
| **DevToolsContextView** | VS Code, Xcode, JetBrains | npm start, Open Terminal, Stop Servers |
| **BookmarksContextView** | Chrome, Safari, Firefox, Arc | Quick-launch bookmarks, New tab |
| **TerminalContextView** | Terminal, iTerm2, Hyper | New tab, Clear, Copy path |
| **GenericContextView** | Any other app | Reveal in Finder, Quit, New Window |
| **JumpRopeCPUView** | Fallback/default | CPU visualization animation |

### View Communication Pattern

```
ExpandedContentView (Router)
       │
       ├──▶ DevToolsContextView ──▶ ScriptRunner.runShell("npm start")
       │
       ├──▶ BookmarksContextView ──▶ ScriptRunner.openNewBrowserTab(url)
       │
       ├──▶ GenericContextView ──▶ ScriptRunner.runAppleScript(...)
       │
       └──▶ JumpRopeCPUView ──▶ Process.run("top -l 1")
```

**Separation of Concerns**: Views handle UI, ScriptRunner handles system interactions

---

## Script Execution Layer

### Architecture

**ScriptRunner** provides a unified, thread-safe interface for executing:
1. Shell commands (zsh)
2. AppleScript
3. Common system actions (Terminal, Finder, browsers)

### Thread Safety Model

```
Main Thread (UI)
       │
       │ ScriptRunner.runShell("command")
       │
       ▼
Background Queue (.userInitiated)
       │
       │ Execute Process/NSAppleScript
       │
       ▼
Capture Output/Result
       │
       ▼
Dispatch to Main Queue
       │
       │ completion(result)
       │
       ▼
Main Thread (Update UI)
```

**Key Pattern**: All execution on background thread, all callbacks on main thread

### Shell Execution

**Implementation** (Lines 9-35):
```swift
static func runShell(_ script: String, completion: ((String) -> Void)? = nil) {
    DispatchQueue.global(qos: .userInitiated).async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", script]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try? process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        DispatchQueue.main.async {
            completion?(output)
        }
    }
}
```

**Shell**: Uses `/bin/zsh` (macOS default shell since Catalina)

**Error Handling**: Stderr merged with stdout via same pipe

### AppleScript Execution

**Implementation** (Lines 37-63):
```swift
static func runAppleScript(_ script: String, completion: ((String) -> Void)? = nil) {
    DispatchQueue.global(qos: .userInitiated).async {
        var error: NSDictionary?
        let appleScript = NSAppleScript(source: script)
        let output = appleScript?.executeAndReturnError(&error)

        DispatchQueue.main.async {
            if let error = error {
                completion?("Error: \(error)")
            } else {
                completion?(output?.stringValue ?? "")
            }
        }
    }
}
```

**Use Cases**:
- Creating new windows (`tell application "..." to make new window`)
- UI automation
- System events

### Specialized Methods

**Open Terminal** (Lines 67-76):
```applescript
tell application "Terminal"
    activate
    do script ""
end tell
```

**Copy Finder Path** (Lines 78-90):
```applescript
tell application "Finder"
    set currentPath to (POSIX path of (target of window 1 as alias))
    set the clipboard to currentPath
end tell
```

**Reveal in Finder** (Lines 100-107):
```swift
NSWorkspace.shared.selectFile(
    path,
    inFileViewerRootedAtPath: ""
)
```

**Open Browser Tab** (Lines 128-149):
```swift
NSWorkspace.shared.open(URL(string: url))
// Falls back to default browser
```

---

## State Management

### Reactive Architecture

Notchy uses Combine's `@Published` with SwiftUI's `@ObservableObject` for reactive state management:

```
Model (@Published properties)
       │
       │ Value changes
       │
       ▼
SwiftUI observes (@EnvironmentObject, @StateObject)
       │
       │ Automatic subscription
       │
       ▼
View.body re-evaluates
       │
       │ Declarative UI update
       │
       ▼
UI reflects new state
```

### State Objects

**ForegroundAppMonitor** (Singleton):
```swift
@MainActor
class ForegroundAppMonitor: ObservableObject {
    @Published var bundleIdentifier: String?
    @Published var localizedName: String?
}
```

**NotchManager** (Instance):
```swift
class NotchManager: ObservableObject {
    @Published var dynamicNotch: DynamicNotch<...>?
}
```

**DynamicNotch** (Instance):
```swift
@MainActor
public final class DynamicNotch<...>: ObservableObject {
    @Published public var state: DynamicNotchState
    @Published public var isHovering: Bool
}
```

### Environment Injection

**Injection Point** (`NotchManager.swift` Line 16):
```swift
let notch = DynamicNotch(
    expandedContent: {
        ExpandedContentView()
            .environmentObject(self.monitor)  // Inject here
    },
    ...
)
```

**Consumption** (`ExpandedContentView.swift` Line 2):
```swift
@EnvironmentObject var monitor: ForegroundAppMonitor
```

**Propagation**: All child views automatically have access via `@EnvironmentObject`

### State Flow Example

```
1. User switches to VS Code
       │
       ▼
2. NSWorkspace fires notification
       │
       ▼
3. ForegroundAppMonitor updates @Published bundleIdentifier
       │
       ▼
4. ExpandedContentView observes change via @EnvironmentObject
       │
       ▼
5. body re-evaluates: monitor.isDevelopmentEnvironment() == true
       │
       ▼
6. SwiftUI renders DevToolsContextView
       │
       ▼
7. Animation transition from previous view
```

**Key Benefit**: Completely declarative, no manual UI updates needed

---

## Animation & UI Details

### State Transition Animations

**DynamicNotch States**:
```swift
public enum DynamicNotchState {
    case hidden    // Not visible
    case compact   // Minimal (leading/trailing content)
    case expanded  // Full content below notch
}
```

**Transition Methods** (`DynamicNotch.swift`):
```swift
public func show() async {
    await compact()  // Always compact first
}

public func compact() async {
    state = .compact
    // Animate size to notch dimensions
}

public func expand() async {
    state = .expanded
    // Animate size to expanded dimensions
}

public func hide() async {
    state = .hidden
    // Animate to zero size
}
```

### Hover Behavior Implementation

**Event Detection** (`NotchView.swift`):
```swift
.onContinuousHover { phase in
    switch phase {
    case .active:
        dynamicNotch.updateHoverState(true)
    case .ended:
        dynamicNotch.updateHoverState(false)
    }
}
```

**Auto-Expand Logic** (`DynamicNotch.swift` Lines 154-167):
```swift
.onChange(of: isHovering) { _, hovering in
    Task { @MainActor in
        if hovering && state == .compact {
            await expand()
        } else if !hovering && state == .expanded {
            try? await Task.sleep(for: .milliseconds(500))  // Delay
            if !isHovering && state == .expanded {
                await compact()
            }
        }
    }
}
```

**Delay Rationale**: 500ms prevents flickering when mouse briefly leaves

### Animation Curves

**File**: `Notchy/NotchKit/DynamicNotch/DynamicNotchStyle.swift` (Lines 66-80)

| Transition | Animation | Duration | Purpose |
|------------|-----------|----------|---------|
| Opening (notch) | `.bouncy` | 0.4s | Playful, spring physics |
| Opening (floating) | `.snappy` | 0.4s | Quick, responsive |
| Closing | `.smooth` | 0.4s | Gentle ease-out |
| Compact ↔ Expanded | `.snappy` | 0.4s | Quick state change |

**Example**:
```swift
withAnimation(style.openingAnimation) {
    // State changes
}
```

### Material Effects

**ExpandedContentView** (Line 21):
```swift
.background(.ultraThickMaterial)
```

**Material Hierarchy** (least to most blur):
- `.ultraThinMaterial`
- `.thinMaterial`
- `.regularMaterial`
- `.thickMaterial`
- `.ultraThickMaterial` ← Used here

**Visual Effect**: Blurred, translucent background that adapts to dark/light mode

### Button Hover Effects

**DevToolsContextView** (Lines 81-84):
```swift
.scaleEffect(isHovered ? 1.05 : 1.0)
.animation(.spring(response: 0.3), value: isHovered)
```

**Pattern**: Subtle 5% scale on hover with spring animation

---

## Extension Guide

### Adding a New App Context

**Example**: Adding Slack support

#### Step 1: Add Detection Method
**File**: `Notchy/Models/ForegroundAppMonitor.swift`

```swift
func isSlack() -> Bool {
    guard let bundleId = bundleIdentifier else { return false }
    return bundleId.contains("com.tinyspeck.slackmacgap")
}
```

#### Step 2: Create Context View
**File**: `Notchy/Views/SlackContextView.swift`

```swift
import SwiftUI

struct SlackContextView: View {
    var body: some View {
        HStack(spacing: 20) {
            ToolButton(
                title: "New Message",
                icon: "message.fill",
                color: .purple,
                script: """
                    osascript -e 'tell application "Slack"
                        activate
                    end tell'
                """
            )

            ToolButton(
                title: "Set Status",
                icon: "person.circle.fill",
                color: .green,
                action: {
                    // Custom Swift logic
                }
            )
        }
        .padding()
    }
}
```

#### Step 3: Update Router
**File**: `Notchy/Views/ExpandedContentView.swift`

```swift
var body: some View {
    Group {
        if monitor.isSlack() {  // Add this
            SlackContextView()
        } else if monitor.isDevelopmentEnvironment() {
            DevToolsContextView()
        }
        // ... rest of conditions
    }
}
```

**Priority**: Earlier conditions take precedence, so order matters!

---

### Adding Custom Actions

#### Option A: Shell Script
```swift
ToolButton(
    title: "Git Status",
    icon: "arrow.triangle.branch",
    color: .blue,
    script: "cd ~/project && git status"
)
```

#### Option B: Swift Closure
```swift
ToolButton(
    title: "Complex Action",
    icon: "gearshape.fill",
    color: .orange,
    action: {
        // Multi-step logic
        ScriptRunner.runShell("step1") { output in
            print(output)
            ScriptRunner.runShell("step2")
        }
    }
)
```

#### Option C: AppleScript
```swift
ToolButton(
    title: "New Window",
    icon: "plus.rectangle",
    color: .purple,
    action: {
        ScriptRunner.runAppleScript("""
            tell application "System Events"
                keystroke "n" using command down
            end tell
        """)
    }
)
```

---

### Customizing Appearance

#### Change Hover Delay
**File**: `Notchy/NotchKit/DynamicNotch/DynamicNotch.swift` (Line 161)

```swift
// Change from 500ms to 1000ms
try? await Task.sleep(for: .milliseconds(1000))
```

#### Change Animation Curves
**File**: `Notchy/NotchKit/DynamicNotch/DynamicNotchStyle.swift` (Lines 66-80)

```swift
var openingAnimation: Animation {
    .spring(response: 0.5, dampingFraction: 0.7)  // Custom spring
}
```

#### Change Expanded Content Size
**File**: `Notchy/Views/ExpandedContentView.swift` (Line 16)

```swift
.frame(width: 600, height: 250)  // Larger
```

#### Change Material Effect
**File**: `Notchy/Views/ExpandedContentView.swift` (Line 21)

```swift
.background(.thinMaterial)  // Less blur
```

#### Change Window Level
**File**: `Notchy/NotchKit/Utility/DynamicNotchPanel.swift` (Line 23)

```swift
self.level = .floating  // Below .screenSaver
```

**Window Levels** (lowest to highest):
- `.normal`
- `.floating`
- `.modalPanel`
- `.popUpMenu`
- `.screenSaver` ← Current

---

### Customizing Bookmarks

#### Option A: Load from JSON
**File**: `Notchy/Views/BookmarksContextView.swift`

Replace `loadBookmarks()` (Lines 35-40):
```swift
private func loadBookmarks() {
    guard let url = Bundle.main.url(forResource: "bookmarks", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let decoded = try? JSONDecoder().decode([Bookmark].self, from: data) else {
        return
    }
    bookmarks = decoded
}
```

Make `Bookmark` Codable:
```swift
struct Bookmark: Identifiable, Codable {
    let id = UUID()
    let name: String
    let url: String
    let icon: String
    let color: String  // Change to String for JSON
}
```

#### Option B: Add to Hardcoded Array
**File**: `Notchy/Views/BookmarksContextView.swift` (Lines 35-40)

```swift
bookmarks = [
    Bookmark(name: "GitHub", url: "https://github.com", ...),
    Bookmark(name: "Your Site", url: "https://yoursite.com", ...),
    // Add more here
]
```

---

## Build System

### Swift Package Manager Configuration

**File**: `Package.swift`

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Notchy",
    platforms: [
        .macOS(.v14)  // Requires macOS 14.0 (Sequoia)
    ],
    products: [
        .executable(
            name: "Notchy",
            targets: ["Notchy"]
        )
    ],
    dependencies: [],  // No external dependencies
    targets: [
        .executableTarget(
            name: "Notchy",
            dependencies: [],
            path: "Notchy",
            resources: [
                .copy("Resources")  // Bundles Resources/ folder
            ]
        )
    ]
)
```

### Build Commands

**Debug Build**:
```bash
swift build
# Output: .build/arm64-apple-macosx/debug/Notchy
```

**Release Build**:
```bash
swift build -c release
# Output: .build/arm64-apple-macosx/release/Notchy
```

**Run**:
```bash
swift run
# Builds and launches immediately
```

**Clean**:
```bash
swift package clean
rm -rf .build
```

### Xcode Integration

**Open in Xcode**:
```bash
open Package.swift
# or
xed .
```

**Xcode Features**:
- Full autocomplete and syntax highlighting
- Breakpoint debugging
- SwiftUI previews (for individual views)
- Cmd+R to build and run

### Resources

**Resources Folder**: `Notchy/Resources/`
- `bookmarks.json` - Bookmark data (not currently loaded)
- Any other assets (images, data files, etc.)

**Access at Runtime**:
```swift
Bundle.main.url(forResource: "bookmarks", withExtension: "json")
```

### Deployment Considerations

#### Code Signing
For distribution outside App Store:
```bash
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name" \
  .build/release/Notchy
```

#### Notarization
Required for macOS Gatekeeper:
```bash
# Create zip
ditto -c -k --keepParent .build/release/Notchy Notchy.zip

# Submit for notarization
xcrun notarytool submit Notchy.zip \
  --apple-id "your@email.com" \
  --password "app-specific-password" \
  --team-id "TEAMID"

# Staple notarization ticket
xcrun stapler staple .build/release/Notchy
```

#### Permissions

**Info.plist Additions** (if creating .app bundle):
```xml
<key>NSAppleEventsUsageDescription</key>
<string>Notchy needs to send commands to other apps</string>

<key>LSUIElement</key>
<true/>  <!-- Hides dock icon -->
```

**Sandbox Considerations**: Not sandboxed due to:
- NSWorkspace access
- AppleScript automation
- Shell command execution

---

## Appendix: File Reference

### Complete File Structure

```
Notchy/
├── NotchyApp.swift                          # Entry point
├── NotchManager.swift                       # Central coordinator
├── NotchHostView.swift                      # Lifecycle manager
│
├── Models/
│   └── ForegroundAppMonitor.swift           # App detection singleton
│
├── Views/
│   ├── ExpandedContentView.swift            # Context router
│   ├── DevToolsContextView.swift            # Dev tools UI
│   ├── BookmarksContextView.swift           # Browser bookmarks UI
│   ├── GenericContextView.swift             # Fallback UI
│   └── JumpRopeCPUView.swift               # CPU visualization
│
├── Services/
│   └── ScriptRunner.swift                   # Script execution
│
├── Resources/
│   └── bookmarks.json                       # Bookmark data
│
└── NotchKit/                                # Embedded DynamicNotchKit
    ├── DynamicNotch/
    │   ├── DynamicNotch.swift              # Core controller
    │   ├── DynamicNotchState.swift         # State enum
    │   ├── DynamicNotchStyle.swift         # Animations
    │   └── DynamicNotchHoverBehavior.swift # Hover config
    │
    ├── Views/
    │   ├── NotchContentView.swift          # Main content host
    │   ├── NotchView.swift                 # Notch-style rendering
    │   ├── NotchlessView.swift             # Floating window rendering
    │   └── NotchShape.swift                # Notch shape mask
    │
    └── Utility/
        ├── DynamicNotchPanel.swift         # Custom NSPanel
        ├── DynamicNotchControllable.swift  # Protocol
        ├── NSScreen+Extensions.swift       # Screen detection
        ├── VisualEffectView.swift          # Material effects
        ├── BlurModifier.swift              # Blur utilities
        └── EnvironmentValues+Extensions.swift
```

### Line Count Summary

| Component | Files | ~Lines |
|-----------|-------|--------|
| Main App | 3 | ~50 |
| Models | 1 | ~95 |
| Views | 5 | ~450 |
| Services | 1 | ~170 |
| NotchKit | 15 | ~1500 |
| **Total** | **25** | **~2265** |

---

## Summary

Notchy demonstrates:
- **Clean SwiftUI Architecture**: MVVM-like with reactive state
- **System Integration**: NSWorkspace, AppleScript, shell commands
- **Modular Design**: Easy to extend with new contexts
- **Smooth UX**: Native animations, hover interactions
- **Self-Contained**: Zero external dependencies

The codebase is well-organized, making it straightforward to:
- Add new app-specific contexts
- Customize animations and appearance
- Extend with custom actions
- Build and deploy

For questions or contributions, see the main README.md.

---

**Last Updated**: 2025-12-06
**Version**: Based on current main branch
