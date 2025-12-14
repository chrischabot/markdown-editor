import AppKit

@MainActor
final class SyntaxHighlighter {
    private weak var textView: NSTextView?
    private nonisolated(unsafe) var changeObserver: NSObjectProtocol?

    // Debouncing
    private var debounceWorkItem: DispatchWorkItem?
    private let debounceDelay: TimeInterval = 0.016 // ~60fps, 16ms

    // Incremental highlighting
    private var dirtyRange: NSRange?

    init(textView: NSTextView) {
        self.textView = textView
        setupNotifications()
    }

    private func setupNotifications() {
        changeObserver = NotificationCenter.default.addObserver(
            forName: NSText.didChangeNotification,
            object: textView,
            queue: .main
        ) { [weak self] _ in
            // We're on main queue, can access MainActor-isolated properties
            MainActor.assumeIsolated {
                guard let self = self,
                      let textView = self.textView else { return }

                // Capture the edited range on main thread
                let editedRange = textView.textStorage?.editedRange ?? NSRange(location: 0, length: 0)
                self.scheduleHighlight(editedRange: editedRange)
            }
        }
    }

    deinit {
        guard let changeObserver else { return }
        NotificationCenter.default.removeObserver(changeObserver)
    }

    private func scheduleHighlight(editedRange: NSRange) {
        // NSTextStorage.editedRange can be NSNotFound in some cases; fall back to visible-range highlight.
        guard editedRange.location != NSNotFound else {
            dirtyRange = nil
            debounceWorkItem?.cancel()

            let workItem = DispatchWorkItem { [weak self] in
                Task { @MainActor in
                    self?.performIncrementalHighlight()
                }
            }
            debounceWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + debounceDelay, execute: workItem)
            return
        }

        // Expand dirty range to include this edit
        if let existing = dirtyRange {
            dirtyRange = NSUnionRange(existing, editedRange)
        } else {
            dirtyRange = editedRange
        }

        // Cancel pending work
        debounceWorkItem?.cancel()

        // Schedule new work with minimal debounce
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.performIncrementalHighlight()
            }
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceDelay, execute: workItem)
    }

    func highlightAll() {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }

        let text = textStorage.string
        let fullRange = NSRange(location: 0, length: textStorage.length)

        guard fullRange.length > 0 else { return }

        // Compute and apply synchronously for initial load
        let attributes = AttributeComputer.computeAttributes(for: text, in: fullRange)
        applyAttributes(attributes, to: textStorage, baseRange: fullRange)
    }

    private func performIncrementalHighlight() {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }

        let text = textStorage.string
        let fullLength = textStorage.length

        guard fullLength > 0 else { return }

        // Determine range to highlight
        let rangeToHighlight: NSRange

        if let dirty = dirtyRange {
            // Expand to full lines for correctness
            let nsText = text as NSString
            let lineRange = nsText.lineRange(for: dirty)

            // Add some buffer for multi-line constructs (code blocks, etc.)
            let expandedStart = max(0, lineRange.location - 500)
            let expandedEnd = min(fullLength, lineRange.upperBound + 500)
            rangeToHighlight = NSRange(location: expandedStart, length: expandedEnd - expandedStart)
        } else {
            // Highlight visible range only
            rangeToHighlight = visibleRange() ?? NSRange(location: 0, length: min(fullLength, 5000))
        }

        dirtyRange = nil

        // All highlighting is now synchronous on main thread for Swift 6 safety
        // The debouncing provides the performance improvement
        let attributes = AttributeComputer.computeAttributes(for: text, in: rangeToHighlight)
        applyAttributes(attributes, to: textStorage, baseRange: rangeToHighlight)
    }

    private func visibleRange() -> NSRange? {
        guard let textView = textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return nil }

        let visibleRect = textView.visibleRect
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        // Add buffer above and below
        let buffer = 1000
        let start = max(0, charRange.location - buffer)
        let end = min(textView.textStorage?.length ?? 0, charRange.upperBound + buffer)

        return NSRange(location: start, length: end - start)
    }

    private func applyAttributes(_ attributes: [AttributeComputer.AttributeApplication], to textStorage: NSTextStorage, baseRange: NSRange) {
        guard !attributes.isEmpty else { return }

        textStorage.beginEditing()

        for attr in attributes {
            // Validate range
            guard attr.range.location >= 0,
                  attr.range.upperBound <= textStorage.length else { continue }

            if attr.isBase {
                textStorage.setAttributes(attr.attributes, range: attr.range)
            } else {
                textStorage.addAttributes(attr.attributes, range: attr.range)
            }
        }

        textStorage.endEditing()
    }
}

// MARK: - Attribute Computation (Isolated from UI)

private enum AttributeComputer {

    struct AttributeApplication {
        let range: NSRange
        let attributes: [NSAttributedString.Key: Any]
        let isBase: Bool
    }

    static func computeAttributes(for text: String, in range: NSRange) -> [AttributeApplication] {
        let nsText = text as NSString
        var results: [AttributeApplication] = []

        // Base attributes for the range
        results.append(AttributeApplication(range: range, attributes: MarkdownStyles.base, isBase: true))

        // Front matter (only check at start)
        if range.location == 0 {
            results.append(contentsOf: computeFrontMatter(text: text, nsText: nsText))
        }

        // Code blocks (used both for styling and exclusion)
        let codeBlockRanges = computeCodeBlockRanges(text: nsText, highlightRange: range)
        for codeBlockRange in codeBlockRanges {
            results.append(AttributeApplication(range: codeBlockRange, attributes: MarkdownStyles.codeBlock, isBase: false))
        }

        // Line-based elements
        results.append(contentsOf: computeHeadings(text: text, range: range, excluding: codeBlockRanges))
        results.append(contentsOf: computeBlockquotes(text: text, range: range, excluding: codeBlockRanges))
        results.append(contentsOf: computeLists(text: text, range: range, nsText: nsText, excluding: codeBlockRanges))
        results.append(contentsOf: computeHorizontalRules(text: text, range: range, excluding: codeBlockRanges))
        results.append(contentsOf: computeTables(text: text, range: range, nsText: nsText, excluding: codeBlockRanges))

        // Inline elements
        results.append(contentsOf: computeInlineFormatting(text: text, range: range, nsText: nsText, excluding: codeBlockRanges))

        return results
    }

    private static func intersectsAny(_ range: NSRange, excluded: [NSRange]) -> Bool {
        for excludedRange in excluded {
            if NSIntersectionRange(range, excludedRange).length > 0 {
                return true
            }
        }
        return false
    }

    // MARK: - Front Matter

    private static func computeFrontMatter(text: String, nsText: NSString) -> [AttributeApplication] {
        var results: [AttributeApplication] = []

        guard let match = SyntaxPatterns.frontMatterFull.firstMatch(
            in: text,
            range: NSRange(location: 0, length: min(nsText.length, 5000))
        ) else { return results }

        let fullRange = match.range
        results.append(AttributeApplication(range: fullRange, attributes: MarkdownStyles.frontMatterContent, isBase: false))

        let firstDelimiter = nsText.range(of: "---", options: [], range: fullRange)
        if firstDelimiter.location != NSNotFound {
            results.append(AttributeApplication(range: firstDelimiter, attributes: MarkdownStyles.frontMatterDelimiter, isBase: false))
        }

        let lastDelimiter = nsText.range(of: "---", options: .backwards, range: fullRange)
        if lastDelimiter.location != NSNotFound {
            results.append(AttributeApplication(range: lastDelimiter, attributes: MarkdownStyles.frontMatterDelimiter, isBase: false))
        }

        return results
    }

    // MARK: - Headings

    private static func computeHeadings(text: String, range: NSRange, excluding codeBlocks: [NSRange]) -> [AttributeApplication] {
        var results: [AttributeApplication] = []

        SyntaxPatterns.heading.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match = match else { return }
            if intersectsAny(match.range, excluded: codeBlocks) { return }

            let hashRange = match.range(at: 1)
            guard hashRange.location != NSNotFound else { return }

            let level = hashRange.length
            results.append(AttributeApplication(range: match.range, attributes: MarkdownStyles.headingAttributes(level: level), isBase: false))
            results.append(AttributeApplication(range: hashRange, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
        }

        return results
    }

    // MARK: - Blockquotes

    private static func computeBlockquotes(text: String, range: NSRange, excluding codeBlocks: [NSRange]) -> [AttributeApplication] {
        var results: [AttributeApplication] = []

        SyntaxPatterns.blockquote.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match = match else { return }
            if intersectsAny(match.range, excluded: codeBlocks) { return }

            results.append(AttributeApplication(range: match.range, attributes: MarkdownStyles.blockquote, isBase: false))

            let markerRange = match.range(at: 1)
            if markerRange.location != NSNotFound {
                results.append(AttributeApplication(range: markerRange, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
            }
        }

        return results
    }

    // MARK: - Lists

    private static func computeLists(text: String, range: NSRange, nsText: NSString, excluding codeBlocks: [NSRange]) -> [AttributeApplication] {
        var results: [AttributeApplication] = []

        // Task lists (checked)
        SyntaxPatterns.taskListChecked.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match = match else { return }
            if intersectsAny(match.range, excluded: codeBlocks) { return }

            results.append(AttributeApplication(range: match.range, attributes: MarkdownStyles.listItem, isBase: false))
            results.append(AttributeApplication(range: match.range, attributes: MarkdownStyles.taskListChecked, isBase: false))

            let markerRange = match.range(at: 2)
            if markerRange.location != NSNotFound {
                results.append(AttributeApplication(range: markerRange, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
                let checkboxStart = markerRange.location + markerRange.length + 1
                let checkboxRange = NSRange(location: checkboxStart, length: 3)
                if checkboxRange.upperBound <= nsText.length {
                    results.append(AttributeApplication(range: checkboxRange, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
                }
            }
        }

        // Task lists (unchecked)
        SyntaxPatterns.taskListUnchecked.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match = match else { return }
            if intersectsAny(match.range, excluded: codeBlocks) { return }

            results.append(AttributeApplication(range: match.range, attributes: MarkdownStyles.listItem, isBase: false))

            let markerRange = match.range(at: 2)
            if markerRange.location != NSNotFound {
                results.append(AttributeApplication(range: markerRange, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
                let checkboxStart = markerRange.location + markerRange.length + 1
                let checkboxRange = NSRange(location: checkboxStart, length: 3)
                if checkboxRange.upperBound <= nsText.length {
                    results.append(AttributeApplication(range: checkboxRange, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
                }
            }
        }

        // Unordered lists
        SyntaxPatterns.unorderedList.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match = match else { return }
            if intersectsAny(match.range, excluded: codeBlocks) { return }
            let bulletRange = match.range(at: 2)
            if bulletRange.location != NSNotFound {
                results.append(AttributeApplication(range: bulletRange, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
            }
        }

        // Ordered lists
        SyntaxPatterns.orderedList.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match = match else { return }
            if intersectsAny(match.range, excluded: codeBlocks) { return }
            let numberRange = match.range(at: 2)
            if numberRange.location != NSNotFound {
                results.append(AttributeApplication(range: numberRange, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
            }
        }

        return results
    }

    // MARK: - Horizontal Rules

    private static func computeHorizontalRules(text: String, range: NSRange, excluding codeBlocks: [NSRange]) -> [AttributeApplication] {
        var results: [AttributeApplication] = []

        SyntaxPatterns.horizontalRule.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match = match else { return }
            if intersectsAny(match.range, excluded: codeBlocks) { return }
            results.append(AttributeApplication(range: match.range, attributes: MarkdownStyles.horizontalRule, isBase: false))
        }

        return results
    }

    // MARK: - Code Blocks

    private static func computeCodeBlockRanges(text: NSString, highlightRange: NSRange) -> [NSRange] {
        guard highlightRange.length > 0 else { return [] }

        var results: [NSRange] = []

        let clampedUpperBound = min(highlightRange.upperBound, text.length)
        let scanLimit = min(text.length, text.lineRange(for: NSRange(location: clampedUpperBound, length: 0)).upperBound)

        var inCodeBlock = false
        var codeBlockStart = 0
        var codeBlockFence = ""

        var index = 0
        while index < scanLimit {
            var lineStart = 0
            var lineEnd = 0
            var contentsEnd = 0
            text.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: index, length: 0))

            let line = text.substring(with: NSRange(location: lineStart, length: contentsEnd - lineStart))

            if !inCodeBlock {
                if let match = SyntaxPatterns.fencedCodeBlockStart.firstMatch(
                    in: line,
                    range: NSRange(location: 0, length: (line as NSString).length)
                ) {
                    inCodeBlock = true
                    codeBlockStart = lineStart
                    codeBlockFence = (line as NSString).substring(with: match.range(at: 1))
                }
            } else {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix(codeBlockFence) && trimmed.dropFirst(codeBlockFence.count).allSatisfy({ $0.isWhitespace || $0.isNewline }) {
                    let fullBlockRange = NSRange(location: codeBlockStart, length: contentsEnd - codeBlockStart)
                    let intersection = NSIntersectionRange(fullBlockRange, highlightRange)
                    if intersection.length > 0 {
                        results.append(intersection)
                    }
                    inCodeBlock = false
                }
            }

            index = lineEnd
        }

        // If we're still inside an unterminated code block by scanLimit, highlight up to scanLimit.
        if inCodeBlock {
            let fullBlockRange = NSRange(location: codeBlockStart, length: scanLimit - codeBlockStart)
            let intersection = NSIntersectionRange(fullBlockRange, highlightRange)
            if intersection.length > 0 {
                results.append(intersection)
            }
        }

        return results
    }

    // MARK: - Tables

    private static func computeTables(text: String, range: NSRange, nsText: NSString, excluding codeBlocks: [NSRange]) -> [AttributeApplication] {
        var results: [AttributeApplication] = []

        SyntaxPatterns.tableSeparator.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match = match else { return }
            if intersectsAny(match.range, excluded: codeBlocks) { return }
            results.append(AttributeApplication(range: match.range, attributes: MarkdownStyles.tableSeparator, isBase: false))
        }

        SyntaxPatterns.tableRow.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match = match else { return }
            if intersectsAny(match.range, excluded: codeBlocks) { return }

            let rowContent = nsText.substring(with: match.range)
            for (offset, codeUnit) in rowContent.utf16.enumerated() {
                if codeUnit == 124 { // "|"
                    let pipeRange = NSRange(location: match.range.location + offset, length: 1)
                    results.append(AttributeApplication(range: pipeRange, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
                }
            }
        }

        return results
    }

    // MARK: - Inline Formatting

    private static func computeInlineFormatting(text: String, range: NSRange, nsText: NSString, excluding codeBlocks: [NSRange]) -> [AttributeApplication] {
        var results: [AttributeApplication] = []

        // Bold+Italic (must come first)
        for pattern in [SyntaxPatterns.boldItalicAsterisk, SyntaxPatterns.boldItalicUnderscore] {
            pattern.enumerateMatches(in: text, range: range) { match, _, _ in
                guard let match = match else { return }
                if intersectsAny(match.range, excluded: codeBlocks) { return }
                let openDelim = match.range(at: 1)
                let content = match.range(at: 2)
                let closeDelim = match.range(at: 3)

                if content.location != NSNotFound {
                    results.append(AttributeApplication(range: content, attributes: MarkdownStyles.boldItalic, isBase: false))
                }
                if openDelim.location != NSNotFound {
                    results.append(AttributeApplication(range: openDelim, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
                }
                if closeDelim.location != NSNotFound {
                    results.append(AttributeApplication(range: closeDelim, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
                }
            }
        }

        // Bold
        for pattern in [SyntaxPatterns.boldAsterisk, SyntaxPatterns.boldUnderscore] {
            pattern.enumerateMatches(in: text, range: range) { match, _, _ in
                guard let match = match else { return }
                if intersectsAny(match.range, excluded: codeBlocks) { return }
                let openDelim = match.range(at: 1)
                let content = match.range(at: 2)
                let closeDelim = match.range(at: 3)

                if content.location != NSNotFound {
                    results.append(AttributeApplication(range: content, attributes: MarkdownStyles.bold, isBase: false))
                }
                if openDelim.location != NSNotFound {
                    results.append(AttributeApplication(range: openDelim, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
                }
                if closeDelim.location != NSNotFound {
                    results.append(AttributeApplication(range: closeDelim, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
                }
            }
        }

        // Italic
        for pattern in [SyntaxPatterns.italicAsterisk, SyntaxPatterns.italicUnderscore] {
            pattern.enumerateMatches(in: text, range: range) { match, _, _ in
                guard let match = match else { return }
                if intersectsAny(match.range, excluded: codeBlocks) { return }
                let openDelim = match.range(at: 1)
                let content = match.range(at: 2)
                let closeDelim = match.range(at: 3)

                if content.location != NSNotFound {
                    results.append(AttributeApplication(range: content, attributes: MarkdownStyles.italic, isBase: false))
                }
                if openDelim.location != NSNotFound {
                    results.append(AttributeApplication(range: openDelim, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
                }
                if closeDelim.location != NSNotFound {
                    results.append(AttributeApplication(range: closeDelim, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
                }
            }
        }

        // Strikethrough
        SyntaxPatterns.strikethrough.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match = match else { return }
            if intersectsAny(match.range, excluded: codeBlocks) { return }
            let openDelim = match.range(at: 1)
            let content = match.range(at: 2)
            let closeDelim = match.range(at: 3)

            if content.location != NSNotFound {
                results.append(AttributeApplication(range: content, attributes: MarkdownStyles.strikethrough, isBase: false))
            }
            if openDelim.location != NSNotFound {
                results.append(AttributeApplication(range: openDelim, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
            }
            if closeDelim.location != NSNotFound {
                results.append(AttributeApplication(range: closeDelim, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
            }
        }

        // Inline code
        SyntaxPatterns.inlineCode.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match = match else { return }
            if intersectsAny(match.range, excluded: codeBlocks) { return }
            results.append(AttributeApplication(range: match.range, attributes: MarkdownStyles.inlineCode, isBase: false))

            let openDelim = match.range(at: 1)
            let closeDelim = match.range(at: 3)
            if openDelim.location != NSNotFound {
                results.append(AttributeApplication(range: openDelim, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
            }
            if closeDelim.location != NSNotFound {
                results.append(AttributeApplication(range: closeDelim, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
            }
        }

        // Links
        SyntaxPatterns.link.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match = match else { return }
            if intersectsAny(match.range, excluded: codeBlocks) { return }

            let textRange = match.range(at: 1)
            let urlRange = match.range(at: 2)

            if textRange.location != NSNotFound {
                results.append(AttributeApplication(range: textRange, attributes: MarkdownStyles.linkText, isBase: false))
            }
            if urlRange.location != NSNotFound {
                results.append(AttributeApplication(range: urlRange, attributes: MarkdownStyles.linkURL, isBase: false))
            }

            let openBracket = NSRange(location: match.range.location, length: 1)
            results.append(AttributeApplication(range: openBracket, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))

            if textRange.location != NSNotFound {
                let closeBracketOpenParen = NSRange(location: textRange.upperBound, length: 2)
                results.append(AttributeApplication(range: closeBracketOpenParen, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
            }

            let closeParen = NSRange(location: match.range.upperBound - 1, length: 1)
            results.append(AttributeApplication(range: closeParen, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
        }

        // Images
        SyntaxPatterns.image.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match = match else { return }
            if intersectsAny(match.range, excluded: codeBlocks) { return }

            let altRange = match.range(at: 1)
            let urlRange = match.range(at: 2)

            if altRange.location != NSNotFound && altRange.length > 0 {
                results.append(AttributeApplication(range: altRange, attributes: MarkdownStyles.linkText, isBase: false))
            }
            if urlRange.location != NSNotFound {
                results.append(AttributeApplication(range: urlRange, attributes: MarkdownStyles.linkURL, isBase: false))
            }

            let exclamationBracket = NSRange(location: match.range.location, length: 2)
            results.append(AttributeApplication(range: exclamationBracket, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))

            if altRange.location != NSNotFound {
                let closeBracketOpenParen = NSRange(location: altRange.upperBound, length: 2)
                results.append(AttributeApplication(range: closeBracketOpenParen, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
            }

            let closeParen = NSRange(location: match.range.upperBound - 1, length: 1)
            results.append(AttributeApplication(range: closeParen, attributes: MarkdownStyles.syntaxDelimiter, isBase: false))
        }

        return results
    }
}
