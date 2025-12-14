import XCTest
import UniformTypeIdentifiers
@testable import MarkdownEditorCore

final class MarkdownDocumentTests: XCTestCase {

    // MARK: - Initialization Tests

    func testDefaultInitialization() {
        let doc = MarkdownDocument()
        XCTAssertEqual(doc.text, "")
        XCTAssertNil(doc.metadata)
    }

    func testInitializationWithText() {
        let doc = MarkdownDocument(text: "# Hello World")
        XCTAssertEqual(doc.text, "# Hello World")
    }

    func testInitializationWithFrontMatter() {
        let text = """
        ---
        title: Test Document
        ---

        # Content
        """
        let doc = MarkdownDocument(text: text)
        XCTAssertNotNil(doc.metadata)
        XCTAssertEqual(doc.metadata?.title, "Test Document")
    }

    // MARK: - Content Type Tests

    func testReadableContentTypes() {
        let types = MarkdownDocument.readableContentTypes
        XCTAssertTrue(types.contains(.markdown))
        XCTAssertTrue(types.contains(.plainText))
    }

    func testWritableContentTypes() {
        let types = MarkdownDocument.writableContentTypes
        XCTAssertTrue(types.contains(.markdown))
    }

    // MARK: - Text Content Tests

    func testDocumentPreservesContent() {
        let text = "Test content with **bold** and *italic*"
        let doc = MarkdownDocument(text: text)
        XCTAssertEqual(doc.text, text)
    }

    func testDocumentPreservesUnicode() {
        let text = "Unicode: 日本語 🎉 émoji"
        let doc = MarkdownDocument(text: text)
        XCTAssertEqual(doc.text, text)
    }

    func testDocumentPreservesEmptyContent() {
        let doc = MarkdownDocument(text: "")
        XCTAssertEqual(doc.text, "")
    }

    // MARK: - Front Matter Integration Tests

    func testFrontMatterParsedOnInit() {
        let text = """
        ---
        title: From File
        author: Test Author
        ---

        Content here
        """
        let doc = MarkdownDocument(text: text)

        XCTAssertEqual(doc.metadata?.title, "From File")
        XCTAssertEqual(doc.metadata?.author, "Test Author")
    }

    func testNoFrontMatterReturnsNilMetadata() {
        let text = "# Just a heading\n\nNo front matter here."
        let doc = MarkdownDocument(text: text)
        XCTAssertNil(doc.metadata)
    }

    // MARK: - Edge Cases

    func testVeryLargeDocument() {
        let largeText = String(repeating: "This is a line of text.\n", count: 10000)
        let doc = MarkdownDocument(text: largeText)
        XCTAssertEqual(doc.text.count, largeText.count)
    }

    func testDocumentWithOnlyWhitespace() {
        let doc = MarkdownDocument(text: "   \n\n\t\t  \n")
        XCTAssertEqual(doc.text, "   \n\n\t\t  \n")
        XCTAssertNil(doc.metadata)
    }

    func testDocumentWithSpecialCharacters() {
        let text = "Special: <>&\"'\\`*_{}[]()#+-.!"
        let doc = MarkdownDocument(text: text)
        XCTAssertEqual(doc.text, text)
    }

    func testDocumentWithNullCharacter() {
        let text = "Text with\0null character"
        let doc = MarkdownDocument(text: text)
        XCTAssertEqual(doc.text, text)
    }

    func testDocumentWithVariousLineEndings() {
        let text = "Line1\nLine2\r\nLine3\rLine4"
        let doc = MarkdownDocument(text: text)
        XCTAssertEqual(doc.text, text)
    }

    // MARK: - UTType Extension Tests

    func testMarkdownUTType() {
        let type = UTType.markdown
        XCTAssertTrue(type.conforms(to: .plainText))
    }
}
