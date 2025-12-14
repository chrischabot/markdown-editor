import SwiftUI

public struct ContentView: View {
    @Binding var document: MarkdownDocument

    public init(document: Binding<MarkdownDocument>) {
        self._document = document
    }

    @AppStorage(LargeDocumentMode.storageKey) private var largeDocumentModeSettingRaw: String = LargeDocumentModeSetting.auto.rawValue

    @State private var initialLineCount: Int = 0
    @State private var initialCharacterCount: Int = 0

    @State private var wordCount: Int = 0
    @State private var lineCount: Int = 0
    @State private var characterCount: Int = 0

    private var largeDocumentModeSetting: LargeDocumentModeSetting {
        LargeDocumentModeSetting(rawValue: largeDocumentModeSettingRaw) ?? .auto
    }

    private var isLargeDocumentAutoDetected: Bool {
        let effectiveLines = max(lineCount, initialLineCount)
        let effectiveCharacters = max(characterCount, initialCharacterCount)
        return LargeDocumentMode.shouldEnableAutomatically(characters: effectiveCharacters, lines: effectiveLines)
    }

    private var isLargeDocumentModeEnabled: Bool {
        switch largeDocumentModeSetting {
        case .auto:
            return isLargeDocumentAutoDetected
        case .on:
            return true
        case .off:
            return false
        }
    }

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
                },
                largeDocumentMode: isLargeDocumentModeEnabled
            )

            Divider()

            StatusBarView(
                wordCount: wordCount,
                lineCount: lineCount,
                characterCount: characterCount,
                largeDocumentMode: isLargeDocumentModeEnabled
            )
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(Color(nsColor: .textBackgroundColor))
        .onAppear {
            // Avoid expensive per-keystroke size checks; seed auto-detection once on load.
            let text = document.text
            initialCharacterCount = text.count
            if !text.isEmpty {
                initialLineCount = text.utf16.reduce(into: 1) { count, codeUnit in
                    if codeUnit == 10 { // "\n"
                        count += 1
                    }
                }
            } else {
                initialLineCount = 0
            }
        }
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
