import SwiftUI
import UniformTypeIdentifiers

public struct MarkdownDocument: FileDocument {
    public static var readableContentTypes: [UTType] { [.markdown, .plainText] }
    public static var writableContentTypes: [UTType] { [.markdown] }

    public var text: String {
        didSet {
            if text.hasPrefix("---") {
                metadata = FrontMatterParser.parse(text)?.frontMatter
            } else {
                metadata = nil
            }
        }
    }
    public var metadata: FrontMatter?

    public init(text: String = "") {
        self.text = text
        self.metadata = FrontMatterParser.parse(text)?.frontMatter
    }

    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        self.text = string
        self.metadata = FrontMatterParser.parse(string)?.frontMatter
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}

public extension UTType {
    static var markdown: UTType {
        UTType(importedAs: "net.daringfireball.markdown", conformingTo: .plainText)
    }
}
