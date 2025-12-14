import AppKit

enum MarkdownStyles {
    // MARK: - Base Font Sizes

    static let baseFontSize: CGFloat = 15
    static let codeFontSize: CGFloat = 14

    // MARK: - Heading Styles

    static func headingAttributes(level: Int) -> [NSAttributedString.Key: Any] {
        let sizes: [CGFloat] = [32, 26, 22, 18, 16, 15]
        let size = level >= 1 && level <= 6 ? sizes[level - 1] : baseFontSize

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacingBefore = level <= 2 ? 16 : 12
        paragraphStyle.paragraphSpacing = 8

        return [
            .font: NSFont.systemFont(ofSize: size, weight: level <= 2 ? .bold : .semibold),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]
    }

    // MARK: - Inline Styles

    static var bold: [NSAttributedString.Key: Any] {
        [.font: NSFont.systemFont(ofSize: baseFontSize, weight: .bold)]
    }

    static var italic: [NSAttributedString.Key: Any] {
        [.font: NSFont(descriptor: NSFont.systemFont(ofSize: baseFontSize).fontDescriptor.withSymbolicTraits(.italic), size: baseFontSize) ?? NSFont.systemFont(ofSize: baseFontSize)]
    }

    static var boldItalic: [NSAttributedString.Key: Any] {
        let descriptor = NSFont.systemFont(ofSize: baseFontSize, weight: .bold).fontDescriptor.withSymbolicTraits(.italic)
        return [.font: NSFont(descriptor: descriptor, size: baseFontSize) ?? NSFont.systemFont(ofSize: baseFontSize, weight: .bold)]
    }

    static var strikethrough: [NSAttributedString.Key: Any] {
        [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
    }

    static var inlineCode: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.monospacedSystemFont(ofSize: codeFontSize, weight: .regular),
            .backgroundColor: NSColor.quaternaryLabelColor.withAlphaComponent(0.3)
        ]
    }

    // MARK: - Block Styles

    static var codeBlock: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 16
        paragraphStyle.firstLineHeadIndent = 16

        return [
            .font: NSFont.monospacedSystemFont(ofSize: codeFontSize, weight: .regular),
            .backgroundColor: NSColor.quaternaryLabelColor.withAlphaComponent(0.2),
            .paragraphStyle: paragraphStyle
        ]
    }

    static var blockquote: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 24
        paragraphStyle.firstLineHeadIndent = 24

        return [
            .foregroundColor: NSColor.secondaryLabelColor,
            .font: NSFont(descriptor: NSFont.systemFont(ofSize: baseFontSize).fontDescriptor.withSymbolicTraits(.italic), size: baseFontSize) ?? NSFont.systemFont(ofSize: baseFontSize),
            .paragraphStyle: paragraphStyle
        ]
    }

    static var listItem: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 24
        paragraphStyle.firstLineHeadIndent = 0

        return [
            .paragraphStyle: paragraphStyle
        ]
    }

    static var taskListChecked: [NSAttributedString.Key: Any] {
        [
            .foregroundColor: NSColor.secondaryLabelColor,
            .strikethroughStyle: NSUnderlineStyle.single.rawValue
        ]
    }

    static var horizontalRule: [NSAttributedString.Key: Any] {
        [
            .foregroundColor: NSColor.separatorColor
        ]
    }

    // MARK: - Link Styles

    static var linkText: [NSAttributedString.Key: Any] {
        [
            .foregroundColor: NSColor.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
    }

    static var linkURL: [NSAttributedString.Key: Any] {
        [
            .foregroundColor: NSColor.tertiaryLabelColor,
            .font: NSFont.systemFont(ofSize: baseFontSize - 1)
        ]
    }

    // MARK: - Table Styles

    static var tableCell: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.systemFont(ofSize: baseFontSize)
        ]
    }

    static var tableSeparator: [NSAttributedString.Key: Any] {
        [
            .foregroundColor: NSColor.tertiaryLabelColor
        ]
    }

    // MARK: - Front Matter Styles

    static var frontMatterDelimiter: [NSAttributedString.Key: Any] {
        [
            .foregroundColor: NSColor.systemPurple.withAlphaComponent(0.7),
            .font: NSFont.monospacedSystemFont(ofSize: codeFontSize, weight: .medium)
        ]
    }

    static var frontMatterContent: [NSAttributedString.Key: Any] {
        [
            .foregroundColor: NSColor.systemPurple.withAlphaComponent(0.8),
            .font: NSFont.monospacedSystemFont(ofSize: codeFontSize, weight: .regular),
            .backgroundColor: NSColor.systemPurple.withAlphaComponent(0.05)
        ]
    }

    // MARK: - Syntax Delimiter Style (dimmed markers)

    static var syntaxDelimiter: [NSAttributedString.Key: Any] {
        [
            .foregroundColor: NSColor.tertiaryLabelColor
        ]
    }

    // MARK: - Base/Reset Style

    static var base: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.paragraphSpacing = 8

        return [
            .font: NSFont.systemFont(ofSize: baseFontSize),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]
    }
}
