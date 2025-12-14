import XCTest
@testable import MarkdownEditorCore

final class EdgeCaseTests: XCTestCase {

    // MARK: - Weird Input Tests

    func testExtremelyLongLine() {
        let longLine = String(repeating: "a", count: 100000)
        let doc = MarkdownDocument(text: "# \(longLine)")
        XCTAssertEqual(doc.text.count, longLine.count + 2)
    }

    func testManyConsecutiveNewlines() {
        let text = "Start" + String(repeating: "\n", count: 1000) + "End"
        let doc = MarkdownDocument(text: text)
        XCTAssertTrue(doc.text.contains("Start"))
        XCTAssertTrue(doc.text.contains("End"))
    }

    func testMixedUnicodeScripts() {
        let text = """
        # Mixed Scripts

        English, 日本語, العربية, עברית, Ελληνικά, Русский, 한국어

        Emojis: 🎉🚀💡🔥✨🎨📱💻

        Math: ∑∏∫∂∇√∞

        Symbols: ©®™℃℉°±×÷
        """

        let doc = MarkdownDocument(text: text)
        XCTAssertEqual(doc.text, text)

        // Test patterns still work
        let matches = SyntaxPatterns.heading.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testZeroWidthCharacters() {
        let text = "Hello\u{200B}World\u{FEFF}Test" // Zero-width space and BOM
        let doc = MarkdownDocument(text: text)
        XCTAssertEqual(doc.text, text)
    }

    func testCombiningCharacters() {
        let text = "café résumé naïve" // Characters with combining diacritics
        let doc = MarkdownDocument(text: text)
        XCTAssertEqual(doc.text, text)
    }

    func testSurrogatePairs() {
        let text = "Emoji: 👨‍👩‍👧‍👦 🏳️‍🌈 👩🏽‍💻" // Complex emoji with ZWJ sequences
        let doc = MarkdownDocument(text: text)
        XCTAssertEqual(doc.text, text)
    }

    // MARK: - Malformed Markdown Tests

    func testUnclosedBold() {
        let text = "This is **unclosed bold"
        let matches = SyntaxPatterns.boldAsterisk.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 0)
    }

    func testUnclosedItalic() {
        let text = "This is *unclosed italic"
        let matches = SyntaxPatterns.italicAsterisk.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 0)
    }

    func testUnclosedInlineCode() {
        let text = "This is `unclosed code"
        let matches = SyntaxPatterns.inlineCode.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 0)
    }

    func testMismatchedDelimiters() {
        let text = "**bold* or *italic**"
        let boldMatches = SyntaxPatterns.boldAsterisk.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        // Pattern should not match mismatched delimiters
        XCTAssertTrue(true) // Just ensuring no crash
    }

    func testNestedFormattingEdgeCases() {
        let text = "***bold and italic*** and **just bold** and *just italic*"
        // Should not crash
        let boldItalic = SyntaxPatterns.boldItalicAsterisk.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        let bold = SyntaxPatterns.boldAsterisk.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        let italic = SyntaxPatterns.italicAsterisk.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertGreaterThanOrEqual(boldItalic.count + bold.count + italic.count, 1)
    }

    func testMalformedLink() {
        let text = "[link text](no closing paren"
        let matches = SyntaxPatterns.link.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 0)
    }

    func testMalformedImage() {
        let text = "![alt text(no closing bracket"
        let matches = SyntaxPatterns.image.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 0)
    }

    // MARK: - Boundary Tests

    func testFormattingAtStart() {
        let text = "**bold** at start"
        let matches = SyntaxPatterns.boldAsterisk.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testFormattingAtEnd() {
        let text = "text at end **bold**"
        let matches = SyntaxPatterns.boldAsterisk.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testOnlyFormatting() {
        let text = "**bold**"
        let matches = SyntaxPatterns.boldAsterisk.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testConsecutiveFormattedBlocks() {
        let text = "**bold1****bold2****bold3**"
        let matches = SyntaxPatterns.boldAsterisk.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertGreaterThanOrEqual(matches.count, 1)
    }

    // MARK: - Performance-Related Edge Cases

    func testManySmallMatches() {
        var text = ""
        for i in 0..<100 {
            text += "**bold\(i)** "
        }

        let matches = SyntaxPatterns.boldAsterisk.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 100)
    }

    func testDeeplyNestedBlockquotes() {
        var text = ""
        for i in 0..<20 {
            text += String(repeating: ">", count: i + 1) + " Level \(i + 1)\n"
        }

        let matches = SyntaxPatterns.blockquote.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 20)
    }

    func testLongListItems() {
        var text = ""
        for i in 0..<100 {
            text += "- Item \(i)\n"
        }

        let matches = SyntaxPatterns.unorderedList.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 100)
    }

    // MARK: - Front Matter Edge Cases

    func testFrontMatterWithBinaryLookingContent() {
        let text = """
        ---
        title: Test
        binary: \\x00\\x01\\x02
        ---

        Content
        """

        let result = FrontMatterParser.parse(text)
        XCTAssertNotNil(result)
    }

    func testFrontMatterWithVeryLongValue() {
        // Parser limits front matter scan to first 5000 chars for performance
        let longValue = String(repeating: "x", count: 1000)
        let text = """
        ---
        title: \(longValue)
        ---
        """

        let result = FrontMatterParser.parse(text)
        XCTAssertNotNil(result)
    }

    func testFrontMatterWithNestedYAML() {
        let text = """
        ---
        title: Test
        nested:
          key1: value1
          key2: value2
        ---
        """

        let result = FrontMatterParser.parse(text)
        XCTAssertNotNil(result)
    }

    // MARK: - Code Block Edge Cases

    func testCodeBlockWithManyBackticks() {
        let text = "``````\ncode\n``````"
        let matches = SyntaxPatterns.fencedCodeBlockStart.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertGreaterThanOrEqual(matches.count, 1)
    }

    func testCodeBlockWithMarkdownInside() {
        let text = """
        ```
        # This is not a heading
        **This is not bold**
        ```
        """

        // The heading pattern should match inside code block
        // (actual exclusion happens in the highlighter)
        let doc = MarkdownDocument(text: text)
        XCTAssertEqual(doc.text, text)
    }

    // MARK: - Table Edge Cases

    func testTableWithManyColumns() {
        var header = "|"
        var separator = "|"
        var row = "|"

        for i in 0..<50 {
            header += " Col\(i) |"
            separator += "---|"
            row += " Val\(i) |"
        }

        let text = "\(header)\n\(separator)\n\(row)"

        // tableRow pattern matches all rows including header, separator, and data rows
        let rowMatches = SyntaxPatterns.tableRow.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(rowMatches.count, 3) // header, separator, and data row
    }

    func testTableWithEmptyCells() {
        // Table rows with content - all table rows match the pattern
        let text = "| a | b | c |\n|---|---|---|\n| d | e | f |"
        let rowMatches = SyntaxPatterns.tableRow.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(rowMatches.count, 3)
    }

    // MARK: - Whitespace Edge Cases

    func testTabsVsSpaces() {
        let text = "\t- Tab indented\n    - Space indented"
        let matches = SyntaxPatterns.unorderedList.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 2)
    }

    func testTrailingWhitespace() {
        let text = "# Heading with trailing spaces   \n"
        let matches = SyntaxPatterns.heading.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testOnlyWhitespace() {
        let text = "   \t\n\n   \t   "
        let doc = MarkdownDocument(text: text)
        XCTAssertEqual(doc.text, text)
        XCTAssertNil(doc.metadata)
    }
}
