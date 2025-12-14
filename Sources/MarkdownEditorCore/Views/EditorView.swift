import SwiftUI

struct EditorView: View {
    @Binding var text: String
    var onStatsUpdate: @MainActor (Int, Int, Int) -> Void

    var body: some View {
        MarkdownTextView(
            text: $text,
            onStatsUpdate: onStatsUpdate
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
