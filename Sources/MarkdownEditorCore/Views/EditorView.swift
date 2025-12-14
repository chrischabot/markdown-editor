import SwiftUI

struct EditorView: View {
    @Binding var text: String
    var onStatsUpdate: @MainActor (Int, Int, Int) -> Void
    var largeDocumentMode: Bool

    var body: some View {
        MarkdownTextView(
            text: $text,
            onStatsUpdate: onStatsUpdate,
            largeDocumentMode: largeDocumentMode
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
