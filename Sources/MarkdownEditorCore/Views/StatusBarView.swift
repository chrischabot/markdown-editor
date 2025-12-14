import SwiftUI

struct StatusBarView: View {
    let wordCount: Int
    let lineCount: Int
    let characterCount: Int

    var body: some View {
        HStack(spacing: 16) {
            Spacer()

            StatLabel(value: lineCount, singular: "line", plural: "lines")
            StatLabel(value: wordCount, singular: "word", plural: "words")
            StatLabel(value: characterCount, singular: "character", plural: "characters")
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.bar)
    }
}

private struct StatLabel: View {
    let value: Int
    let singular: String
    let plural: String

    var body: some View {
        Text("\(value) \(value == 1 ? singular : plural)")
            .monospacedDigit()
    }
}
