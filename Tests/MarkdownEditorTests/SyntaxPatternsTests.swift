import XCTest
@testable import MarkdownEditorCore

final class SyntaxPatternsTests: XCTestCase {

    // MARK: - Heading Tests

    func testHeadingLevel1() {
        let text = "# Heading 1"
        let matches = SyntaxPatterns.heading.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testHeadingLevel6() {
        let text = "###### Heading 6"
        let matches = SyntaxPatterns.heading.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testHeadingWithoutSpace() {
        let text = "#NoSpace"
        let matches = SyntaxPatterns.heading.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 0, "Heading requires space after #")
    }

    func testMultipleHeadings() {
        let text = "# H1\n## H2\n### H3"
        let matches = SyntaxPatterns.heading.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 3)
    }

    // MARK: - Bold Tests

    func testBoldAsterisk() {
        let text = "This is **bold** text"
        let matches = SyntaxPatterns.boldAsterisk.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testBoldUnderscore() {
        let text = "This is __bold__ text"
        let matches = SyntaxPatterns.boldUnderscore.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testBoldWithSpacesInside() {
        let text = "**bold with spaces**"
        let matches = SyntaxPatterns.boldAsterisk.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    // MARK: - Italic Tests

    func testItalicAsterisk() {
        // Italic at sentence start
        let text = "*italic* text here"
        let matches = SyntaxPatterns.italicAsterisk.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testItalicUnderscore() {
        // Italic at sentence start
        let text = "_italic_ text here"
        let matches = SyntaxPatterns.italicUnderscore.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    // MARK: - Bold Italic Tests

    func testBoldItalicAsterisk() {
        let text = "This is ***bold italic*** text"
        let matches = SyntaxPatterns.boldItalicAsterisk.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testBoldItalicUnderscore() {
        let text = "This is ___bold italic___ text"
        let matches = SyntaxPatterns.boldItalicUnderscore.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    // MARK: - Strikethrough Tests

    func testStrikethrough() {
        let text = "This is ~~strikethrough~~ text"
        let matches = SyntaxPatterns.strikethrough.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    // MARK: - Inline Code Tests

    func testInlineCode() {
        let text = "This is `code` text"
        let matches = SyntaxPatterns.inlineCode.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testInlineCodeWithDoubleBackticks() {
        let text = "This is ``code with `backtick` inside`` text"
        let matches = SyntaxPatterns.inlineCode.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertGreaterThanOrEqual(matches.count, 1)
    }

    // MARK: - Link Tests

    func testLink() {
        let text = "This is a [link](https://example.com) text"
        let matches = SyntaxPatterns.link.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testLinkWithTitle() {
        let text = "[link](https://example.com \"Title\")"
        let matches = SyntaxPatterns.link.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    // MARK: - Image Tests

    func testImage() {
        let text = "![Alt text](https://example.com/image.png)"
        let matches = SyntaxPatterns.image.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testImageWithEmptyAlt() {
        let text = "![](https://example.com/image.png)"
        let matches = SyntaxPatterns.image.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    // MARK: - List Tests

    func testUnorderedListDash() {
        let text = "- Item 1\n- Item 2"
        let matches = SyntaxPatterns.unorderedList.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 2)
    }

    func testUnorderedListAsterisk() {
        let text = "* Item 1\n* Item 2"
        let matches = SyntaxPatterns.unorderedList.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 2)
    }

    func testUnorderedListPlus() {
        let text = "+ Item 1\n+ Item 2"
        let matches = SyntaxPatterns.unorderedList.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 2)
    }

    func testOrderedList() {
        let text = "1. Item 1\n2. Item 2\n10. Item 10"
        let matches = SyntaxPatterns.orderedList.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 3)
    }

    // MARK: - Task List Tests

    func testTaskListUnchecked() {
        let text = "- [ ] Task 1\n- [ ] Task 2"
        let matches = SyntaxPatterns.taskListUnchecked.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 2)
    }

    func testTaskListChecked() {
        let text = "- [x] Task 1\n- [X] Task 2"
        let matches = SyntaxPatterns.taskListChecked.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 2)
    }

    // MARK: - Blockquote Tests

    func testBlockquote() {
        let text = "> This is a quote"
        let matches = SyntaxPatterns.blockquote.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testNestedBlockquote() {
        let text = ">> Nested quote"
        let matches = SyntaxPatterns.blockquote.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    // MARK: - Code Block Tests

    func testFencedCodeBlockStart() {
        // Test just the opening line
        let text = "```swift"
        let matches = SyntaxPatterns.fencedCodeBlockStart.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testFencedCodeBlockWithTildes() {
        // Test just the opening line
        let text = "~~~python"
        let startMatches = SyntaxPatterns.fencedCodeBlockStart.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(startMatches.count, 1)
    }

    func testFencedCodeBlockStartAndEnd() {
        // Both start and end match the fencedCodeBlockStart pattern
        let text = "```swift\nlet x = 1\n```"
        let matches = SyntaxPatterns.fencedCodeBlockStart.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 2) // Opening and closing both match
    }

    // MARK: - Horizontal Rule Tests

    func testHorizontalRuleDashes() {
        let text = "---"
        let matches = SyntaxPatterns.horizontalRule.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testHorizontalRuleAsterisks() {
        let text = "***"
        let matches = SyntaxPatterns.horizontalRule.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testHorizontalRuleUnderscores() {
        let text = "___"
        let matches = SyntaxPatterns.horizontalRule.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    // MARK: - Table Tests

    func testTableRow() {
        let text = "| Col 1 | Col 2 | Col 3 |"
        let matches = SyntaxPatterns.tableRow.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testTableSeparator() {
        let text = "|---|---|---|"
        let matches = SyntaxPatterns.tableSeparator.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testTableSeparatorWithAlignment() {
        let text = "|:---|:---:|---:|"
        let matches = SyntaxPatterns.tableSeparator.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    // MARK: - Autolink Tests

    func testAutolink() {
        let text = "<https://example.com>"
        let matches = SyntaxPatterns.autolink.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testEmailAutolink() {
        let text = "<test@example.com>"
        let matches = SyntaxPatterns.emailAutolink.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    // MARK: - HTML Tests

    func testHTMLTag() {
        let text = "<div>content</div>"
        let matches = SyntaxPatterns.htmlTag.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 2)
    }

    func testHTMLComment() {
        let text = "<!-- comment -->"
        let matches = SyntaxPatterns.htmlComment.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    // MARK: - Escape Tests

    func testEscapedCharacters() {
        let text = "\\*not italic\\*"
        let matches = SyntaxPatterns.escapedCharacter.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 2)
    }

    // MARK: - Edge Cases

    func testEmptyString() {
        let text = ""
        let matches = SyntaxPatterns.heading.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 0)
    }

    func testUnicodeText() {
        let text = "# 日本語見出し"
        let matches = SyntaxPatterns.heading.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }

    func testBoldWithEmoji() {
        let text = "**bold 🎉 text**"
        let matches = SyntaxPatterns.boldAsterisk.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(matches.count, 1)
    }
}
