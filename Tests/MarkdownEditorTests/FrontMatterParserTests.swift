import XCTest
@testable import MarkdownEditorCore

final class FrontMatterParserTests: XCTestCase {

    // MARK: - Valid Front Matter Tests

    func testValidFrontMatterWithAllFields() {
        let markdown = """
        ---
        title: My Blog Post
        author: John Doe
        date: 2024-01-15
        tags: [swift, ios, macos]
        ---

        # Content starts here
        """

        let result = FrontMatterParser.parse(markdown)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.frontMatter.title, "My Blog Post")
        XCTAssertEqual(result?.frontMatter.author, "John Doe")
        XCTAssertEqual(result?.frontMatter.tags, ["swift", "ios", "macos"])
        XCTAssertNotNil(result?.frontMatter.date)
    }

    func testValidFrontMatterMinimal() {
        let markdown = """
        ---
        title: Simple
        ---

        Content
        """

        let result = FrontMatterParser.parse(markdown)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.frontMatter.title, "Simple")
    }

    func testFrontMatterWithCustomFields() {
        let markdown = """
        ---
        title: Post
        custom_field: custom_value
        draft: true
        ---

        Content
        """

        let result = FrontMatterParser.parse(markdown)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.frontMatter.customFields["custom_field"], "custom_value")
        XCTAssertEqual(result?.frontMatter.customFields["draft"], "true")
    }

    // MARK: - Date Parsing Tests

    func testDateFormatYYYYMMDD() {
        let markdown = """
        ---
        date: 2024-06-15
        ---
        """

        let result = FrontMatterParser.parse(markdown)
        XCTAssertNotNil(result?.frontMatter.date)
    }

    func testDateFormatWithTime() {
        let markdown = """
        ---
        date: 2024-06-15 14:30:00
        ---
        """

        let result = FrontMatterParser.parse(markdown)
        XCTAssertNotNil(result?.frontMatter.date)
    }

    func testDateFormatISO8601() {
        let markdown = """
        ---
        date: 2024-06-15T14:30:00Z
        ---
        """

        let result = FrontMatterParser.parse(markdown)
        XCTAssertNotNil(result?.frontMatter.date)
    }

    // MARK: - No Front Matter Tests

    func testNoFrontMatter() {
        let markdown = "# Just a heading\n\nSome content"
        let result = FrontMatterParser.parse(markdown)
        XCTAssertNil(result)
    }

    func testFrontMatterNotAtStart() {
        let markdown = """
        Some content first

        ---
        title: This shouldn't be parsed
        ---
        """

        let result = FrontMatterParser.parse(markdown)
        XCTAssertNil(result)
    }

    // MARK: - Edge Cases

    func testEmptyFrontMatter() {
        // Empty front matter (no content between delimiters) doesn't match the regex
        // The regex requires at least some content between the ---
        let markdown = """
        ---
        ---

        Content
        """

        let result = FrontMatterParser.parse(markdown)
        // Empty front matter is not valid - regex requires content between delimiters
        XCTAssertNil(result)
    }

    func testFrontMatterWithUnicodeCharacters() {
        let markdown = """
        ---
        title: 日本語タイトル
        author: Müller
        tags: [émoji, 中文]
        ---
        """

        let result = FrontMatterParser.parse(markdown)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.frontMatter.title, "日本語タイトル")
        XCTAssertEqual(result?.frontMatter.author, "Müller")
    }

    func testFrontMatterWithSpecialCharactersInValues() {
        let markdown = """
        ---
        title: "Title with: colon"
        author: Name (with parens)
        ---
        """

        let result = FrontMatterParser.parse(markdown)
        XCTAssertNotNil(result)
    }

    func testFrontMatterWithEmptyValues() {
        let markdown = """
        ---
        title:
        author:
        ---
        """

        let result = FrontMatterParser.parse(markdown)
        XCTAssertNotNil(result)
    }

    func testFrontMatterTagsAsCommaSeparatedString() {
        let markdown = """
        ---
        tags: swift, ios, macos
        ---
        """

        let result = FrontMatterParser.parse(markdown)
        XCTAssertNotNil(result)
        XCTAssertFalse(result?.frontMatter.tags.isEmpty ?? true)
    }

    func testVeryLongFrontMatter() {
        var yaml = "---\n"
        for i in 0..<100 {
            yaml += "field\(i): value\(i)\n"
        }
        yaml += "---\n\nContent"

        let result = FrontMatterParser.parse(yaml)
        XCTAssertNotNil(result)
    }

    func testFrontMatterYamlRange() {
        let markdown = """
        ---
        title: Test
        ---

        Content
        """

        let result = FrontMatterParser.parse(markdown)
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!.yamlRange.length, 0)
        XCTAssertEqual(result!.yamlRange.location, 0)
    }

    // MARK: - Malformed Input Tests

    func testMalformedYAML() {
        let markdown = """
        ---
        title: [unclosed bracket
        author: test
        ---
        """

        // Should still parse with fallback
        let result = FrontMatterParser.parse(markdown)
        XCTAssertNotNil(result)
    }

    func testFrontMatterWithOnlyOpeningDelimiter() {
        let markdown = """
        ---
        title: test
        No closing delimiter
        """

        let result = FrontMatterParser.parse(markdown)
        XCTAssertNil(result)
    }

    func testEmptyString() {
        let result = FrontMatterParser.parse("")
        XCTAssertNil(result)
    }

    func testWhitespaceOnlyString() {
        let result = FrontMatterParser.parse("   \n\n   \t")
        XCTAssertNil(result)
    }
}
