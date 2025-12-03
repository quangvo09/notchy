//
//  NotchyApp.swift
//  Notchy
//
//  Dynamic Island for macOS
//

import SwiftUI
import AppKit

@main
struct NotchyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
