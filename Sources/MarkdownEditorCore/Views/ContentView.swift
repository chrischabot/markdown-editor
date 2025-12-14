import SwiftUI

public struct ContentView: View {
    @Binding var document: MarkdownDocument

    public init(document: Binding<MarkdownDocument>) {
        self._document = document
    }
    @State private var wordCount: Int = 0
    @State private var lineCount: Int = 0
    @State private var characterCount: Int = 0

    public var body: some View {
        VStack(spacing: 0) {
            ToolbarView(text: $document.text)

            Divider()

            EditorView(
                text: $document.text,
                onStatsUpdate: { words, lines, chars in
                    wordCount = words
                    lineCount = lines
                    characterCount = chars
                }
            )

            Divider()

            StatusBarView(
                wordCount: wordCount,
                lineCount: lineCount,
                characterCount: characterCount
            )
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(Color(nsColor: .textBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: .showPreview)) { notification in
            // Only respond if our window is key
            guard let window = NSApp.keyWindow,
                  window.contentView?.subviews.first(where: { $0 is NSHostingView<ContentView> }) != nil ||
                  window.isKeyWindow else { return }

            let text = (notification.object as? String) ?? document.text
            let title = window.title.isEmpty ? "Untitled" : window.title
            PreviewWindowController.shared.showPreview(markdown: text, title: title)
        }
    }
}
