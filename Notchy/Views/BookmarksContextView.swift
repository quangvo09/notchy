import SwiftUI

struct BookmarksContextView: View {
    @State private var bookmarks: [Bookmark] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Bookmarks")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(bookmarks) { bookmark in
                    BookmarkButton(bookmark: bookmark)
                }
            }

            if bookmarks.isEmpty {
                Text("No bookmarks configured")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .onAppear {
            loadBookmarks()
        }
    }

    private func loadBookmarks() {
        bookmarks = [
            Bookmark(name: "GitHub", url: "https://github.com"),
            Bookmark(name: "Stack Overflow", url: "https://stackoverflow.com"),
            Bookmark(name: "Documentation", url: "https://developer.apple.com"),
            Bookmark(name: "Figma", url: "https://figma.com")
        ]
    }
}

struct Bookmark: Identifiable, Codable {
    let id: UUID
    let name: String
    let url: String

    init(name: String, url: String) {
        self.id = UUID()
        self.name = name
        self.url = url
    }
}

struct BookmarkButton: View {
    let bookmark: Bookmark
    @State private var isHovering = false

    var body: some View {
        Button(action: {
            NSWorkspace.shared.open(URL(string: bookmark.url)!)
        }) {
            Text(bookmark.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.blue.opacity(0.3), lineWidth: isHovering ? 1 : 0)
                        )
                )
                .scaleEffect(isHovering ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}