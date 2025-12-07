# Notchy - Dynamic Island for Your Mac

A smart Dynamic Island for macOS that brings context-aware information and quick actions to your Mac's notch (or floating window on non-notched Macs). Built with SwiftUI and DynamicNotchKit.

![Notchy App](https://img.shields.io/badge/macOS-14+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

> **🎉 Transform your Mac's notch into a smart, context-aware hub that adapts to what you're doing!**

## ✨ Features

### 🕐 Smart Clock & Calendar
- **Large, elegant clock** with real-time updates
- **Current date and day** display
- **Interactive week view** with today highlighted
- **Beautiful time-based themes** that smoothly change throughout the day:
  - Early Morning (5-8am): Warm orange gradient
  - Morning (8am-12pm): Bright yellow theme
  - Afternoon (12-5pm): Cool blue atmosphere
  - Evening (5-8pm): Soft purple ambiance
  - Night (8-11pm): Deep indigo theme
  - Late Night (11pm-5am): Midnight purple

### 🎧 AirPods Integration
- **Automatic detection** when AirPods connect/disconnect
- **Battery monitoring** for left/right AirPods and charging case
- **Instant notifications** for connection/disconnection events
- **Universal support** for all AirPod models (AirPods, Pro, Max, and newer generations)

### ⚡ Developer Quick Actions
When using coding tools like VS Code, Xcode, JetBrains, Sublime Text, or Terminal:
- **Run npm start** - Quickly start your development server
- **Open Terminal** - Launch terminal with one click
- **Stop Servers** - Instantly stop all running Node.js/npm/yarn processes
- **Clear Terminal** - Clean up your terminal view
- **Copy Path** - Copy current directory to clipboard

### 📊 System Monitoring
- **CPU usage tracking** in the background
- **High CPU alerts** when usage exceeds threshold (80% by default)
- **Quick access** to Activity Monitor from alerts
- **Visual indicators** with smooth flame animations

### 🎯 App-Aware Interface
Notchy intelligently recognizes your active app and adapts:
- **Development environments**: Shows coding tools and actions
- **Terminal applications**: Terminal-specific quick actions
- **Web browsers**: Context-aware for web browsing (coming soon)
- **Default mode**: Beautiful clock and calendar display

### ✨ Premium User Experience
- **Smooth animations** with native-like Dynamic Island physics
- **Auto-expand on hover** with 500ms auto-compact delay
- **Material backgrounds** using macOS blur effects
- **Universal compatibility** - works on all Macs with or without notch
- **Non-intrusive design** that perfectly blends with macOS aesthetics

### 🔔 Smart Notifications
- **Personalized greetings** on app launch or system wake
- **Priority-based event display** that temporarily replaces regular content
- **Important alerts** (CPU, AirPods) appear instantly
- **Manual dismiss** option for ongoing notifications

## 🚀 Quick Start

### Prerequisites

- macOS 14.0 (Sequoia) or later
- Xcode 15.0 or later

### Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/notchy.git
cd notchy
```

2. Open the project in Xcode:
```bash
open Package.swift
```

3. Build and run the project:
```bash
swift run
```

Or open in Xcode and press `Cmd+R`.

## 📱 How It Works

Notchy runs in your Mac's Dynamic Island (or as a floating window on non-notched Macs) and intelligently adapts its content based on what you're doing:

### Default View
When no specific context is detected, Notchy shows:
- **Time & Date**: Large, elegant clock with current date
- **Week View**: Interactive calendar showing the current week
- **Dynamic Theme**: Colors and gradients that change throughout the day

### Development Tools
When using IDEs like VS Code, Xcode, JetBrains, or Sublime Text:
- **Run npm start** - Execute npm start in current directory
- **Open Terminal** - Launch Terminal application
- **Stop Servers** - Kill all Node.js/npm/yarn processes

### Terminal Applications
When using Terminal, iTerm2, or Hyper:
- **New Tab** - Create new terminal tab
- **Clear** - Clear terminal screen
- **Copy Path** - Copy current directory path

### Smart Alerts & Events
Notchy monitors your system and shows:
- **AirPods Status** - Connection status and battery levels
- **CPU Warnings** - Alerts when CPU usage is too high
- **Welcome Messages** - Personalized greetings on startup
- **System Notifications** - Important system events

All features work automatically in the background - No configuration needed!

## 🛠️ Architecture

```
Notchy/
├── NotchyApp.swift               # Main app entry point
├── Models/
│   └── ForegroundAppMonitor.swift  # Monitors active applications
├── Views/
│   ├── NotchRootView.swift        # Main notch view coordinator
│   ├── DevToolsContextView.swift  # Development environment UI
│   ├── BookmarksContextView.swift # Browser bookmark UI
│   └── GenericContextView.swift   # Fallback UI for other apps
├── Services/
│   └── ScriptRunner.swift          # Shell script and AppleScript execution
└── Resources/
    └── bookmarks.json              # Default bookmark configuration
```

## 🎨 Customization

### Adding New Bookmarks

Edit `Resources/bookmarks.json` to add your favorite bookmarks:

```json
{
  "name": "Your Site",
  "url": "https://yoursite.com",
  "category": "development"
}
```

### Adding New App Contexts

1. Add bundle identifiers to `ForegroundAppMonitor.swift`
2. Create new view files in `Views/`
3. Update `ExpandedContextView.swift` to handle new app types

### Custom Scripts

Add custom shell commands in the development context buttons:

```swift
ToolButton(
    title: "Custom Action",
    icon: "star.fill",
    color: .purple,
    script: "your-shell-command"
)
```

## 🔧 Configuration

The app automatically detects these applications:

### Development Environments
- Visual Studio Code (`com.microsoft.VSCode`)
- Xcode (`com.apple.dt.Xcode`)
- JetBrains IDEs (`com.jetbrains.*`)
- Sublime Text (`com.sublimetext.*`)

### Browsers
- Chrome (`com.google.Chrome`)
- Safari (`com.apple.Safari`)
- Firefox (`org.mozilla.firefox`)
- Arc (`company.thebrowser.Browser`)
- Brave (`com.brave.Browser`)
- Vivaldi (`com.vivaldi.Vivaldi`)

### Terminals
- Terminal (`com.apple.Terminal`)
- Hyper (`co.zeit.hyper`)
- iTerm2 (`com.googlecode.iterm2`)

## 📱 Compatibility & Requirements

- **macOS**: 14.0 (Sequoia) or later
- **Mac Types**: Both notched and non-notched Macs (MacBook Pro, MacBook Air, iMac, Mac mini, Mac Studio)
- **Architecture**: Native support for both Intel and Apple Silicon Macs
- **Swift Version**: 5.9+
- **No external dependencies required** - Everything is built-in!

## 🤝 Contributing

1. Fork this repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit) - The amazing library that makes this possible
- Apple for Dynamic Island inspiration
- The SwiftUI community for animation techniques

## 📞 Support

If you encounter any issues or have feature requests, please [open an issue](https://github.com/yourusername/notchy/issues).

---

Made with ❤️ for Mac users who love efficient workflows