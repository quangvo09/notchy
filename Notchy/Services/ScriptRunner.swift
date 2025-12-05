import Foundation
import Cocoa
import AppKit

struct ScriptRunner {

    // MARK: - Shell Command Execution

    static func runShell(_ command: String, completion: ((String?, Error?) -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            let pipe = Pipe()

            task.launchPath = "/bin/zsh"
            task.arguments = ["-c", command]
            task.standardOutput = pipe
            task.standardError = pipe

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)

                DispatchQueue.main.async {
                    completion?(output, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion?(nil, error)
                }
            }
        }
    }

    static func runAppleScript(_ script: String, completion: ((String?, Error?) -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            let pipe = Pipe()

            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", script]
            task.standardOutput = pipe
            task.standardError = pipe

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)

                DispatchQueue.main.async {
                    completion?(output, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion?(nil, error)
                }
            }
        }
    }

    // MARK: - Convenience Methods

    static func openTerminal() {
        runAppleScript("""
            tell application "Terminal"
                activate
                if not (exists window 1) then
                    do script ""
                end if
            end tell
        """)
    }

    static func copyCurrentPath() {
        runAppleScript("""
            tell application "Finder"
                if exists (front window) then
                    set currentPath to (target of front window) as alias
                    set the clipboard to POSIX path of currentPath
                else
                    set currentPath to (path to desktop) as alias
                    set the clipboard to POSIX path of currentPath
                end if
            end tell
        """)
    }

    static func getCurrentWorkingDirectory() -> String {
        return FileManager.default.currentDirectoryPath
    }

    static func openURL(_ url: String) {
        NSWorkspace.shared.open(URL(string: url)!)
    }

    static func revealInFinder(path: String) {
        runAppleScript("""
            tell application "Finder"
                reveal POSIX file "\(path)"
                activate
            end tell
        """)
    }

    // MARK: - VS Code Specific Actions

    static func runVSCodeCommand(_ command: String) {
        runShell("code --command '\(command)'")
    }

    static func openVSCodeTerminal() {
        runAppleScript("""
            tell application "Visual Studio Code"
                activate
                tell application "System Events"
                    keystroke "c" using {control down, shift down}
                end tell
            end tell
        """)
    }

    // MARK: - Browser Actions

    static func openNewBrowserTab(url: String = "about:blank") {
        runAppleScript("""
            tell application "System Events"
                set frontApp to name of first application process whose frontmost is true
                if frontApp is in {"Google Chrome", "Safari", "Firefox"} then
                    tell application frontApp
                        activate
                        tell application "System Events"
                            keystroke "t" using {command down}
                            if "\(url)" is not "about:blank" then
                                delay 0.5
                                keystroke "\(url)"
                                keystroke return
                            end if
                        end tell
                    end tell
                else
                    open location "\(url)"
                end if
            end tell
        """)
    }

    // MARK: - System Actions

    static func takeScreenshot() {
        runAppleScript("""
            tell application "System Events"
                keystroke "4" using {command down, shift down}
            end tell
        """)
    }

    static func lockScreen() {
        runAppleScript("""
            tell application "System Events"
                keystroke "q" using {control down, command down}
            end tell
        """)
    }
}