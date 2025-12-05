# Notchy - Context-Aware Dynamic Island for macOS

A smart Dynamic Island for macOS that changes its content based on the currently active application. Built with SwiftUI and DynamicNotchKit.

![Notchy App](https://img.shields.io/badge/macOS-14+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Features

- **Context-Aware**: Automatically detects the foreground app and shows relevant content
- **Development Tools**: Quick actions for VS Code, Xcode, and other development environments
- **Browser Bookmarks**: Quick-launch bookmarks for Chrome, Safari, Firefox, and Arc
- **Terminal Integration**: Quick actions for Terminal and iTerm2
- **Generic Fallback**: Works with any app with basic actions
- **Smooth Animations**: Native-like Dynamic Island animations with spring physics
- **Universal Support**: Works on both notched and non-notched Macs

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

Notchy runs in your Mac's Dynamic Island (or menu bar on non-notched Macs) and intelligently changes its content based on your active application:

### Development Environments
- **VS Code/Xcode**: Run scripts, open terminal, stop servers
- **Terminal**: New tab, clear, copy current path

### Browsers
- **Quick Bookmarks**: Access your favorite development resources
- **New Tab**: Open new browser tabs instantly

### Other Apps
- **Reveal in Finder**: Show the app in Finder
- **Quit App**: Close the current application
- **New Window**: Create a new window/document

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

## 📱 Compatibility

- **macOS**: 14.0 (Sequoia) or later
- **Mac Types**: Both notched and non-notched Macs
- **Swift Version**: 5.9+

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