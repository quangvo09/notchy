//
//  HoverableView.swift
//  Notchy
//
//  DEPRECATED: DynamicNotchKit handles hover detection automatically
//

import SwiftUI
import AppKit

struct HoverableView<Content: View>: View {
    let content: Content
    let onEnter: () -> Void
    let onExit: () -> Void

    var body: some View {
        content
    }
}
