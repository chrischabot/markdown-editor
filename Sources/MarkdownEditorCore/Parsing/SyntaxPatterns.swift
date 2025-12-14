import Foundation

public enum SyntaxPatterns {
    // MARK: - Block Elements

    public static let heading = try! NSRegularExpression(
        pattern: "^(#{1,6})\\s+(.*)$",
        options: .anchorsMatchLines
    )

    public static let blockquote = try! NSRegularExpression(
        pattern: "^(>+)\\s?(.*)$",
        options: .anchorsMatchLines
    )

    public static let unorderedList = try! NSRegularExpression(
        pattern: "^(\\s*)([-*+])\\s+(.*)$",
        options: .anchorsMatchLines
    )

    public static let orderedList = try! NSRegularExpression(
        pattern: "^(\\s*)(\\d+\\.)\\s+(.*)$",
        options: .anchorsMatchLines
    )

    public static let taskListUnchecked = try! NSRegularExpression(
        pattern: "^(\\s*)([-*+])\\s+\\[( )\\]\\s+(.*)$",
        options: .anchorsMatchLines
    )

    public static let taskListChecked = try! NSRegularExpression(
        pattern: "^(\\s*)([-*+])\\s+\\[([xX])\\]\\s+(.*)$",
        options: .anchorsMatchLines
    )

    public static let horizontalRule = try! NSRegularExpression(
        pattern: "^[-*_]{3,}\\s*$",
        options: .anchorsMatchLines
    )

    public static let fencedCodeBlockStart = try! NSRegularExpression(
        pattern: "^(`{3,}|~{3,})(\\w*)\\s*$",
        options: .anchorsMatchLines
    )

    public static let fencedCodeBlockEnd = try! NSRegularExpression(
        pattern: "^(`{3,}|~{3,})\\s*$",
        options: .anchorsMatchLines
    )

    public static let indentedCodeBlock = try! NSRegularExpression(
        pattern: "^(    |\\t)(.*)$",
        options: .anchorsMatchLines
    )

    // MARK: - Table Elements (GFM)

    public static let tableRow = try! NSRegularExpression(
        pattern: "^\\|(.+)\\|\\s*$",
        options: .anchorsMatchLines
    )

    public static let tableSeparator = try! NSRegularExpression(
        pattern: "^\\|[-:|\\s]+\\|\\s*$",
        options: .anchorsMatchLines
    )

    // MARK: - Inline Elements

    public static let boldAsterisk = try! NSRegularExpression(
        pattern: "(\\*\\*)(?=\\S)(.+?)(?<=\\S)(\\*\\*)",
        options: []
    )

    public static let boldUnderscore = try! NSRegularExpression(
        pattern: "(__)(?=\\S)(.+?)(?<=\\S)(__)",
        options: []
    )

    public static let italicAsterisk = try! NSRegularExpression(
        pattern: "(?<![*\\w])(\\*)(?![*\\s])(.+?)(?<![*\\s])(\\*)(?![*\\w])",
        options: []
    )

    public static let italicUnderscore = try! NSRegularExpression(
        pattern: "(?<![_\\w])(_)(?![_\\s])(.+?)(?<![_\\s])(_)(?![_\\w])",
        options: []
    )

    public static let boldItalicAsterisk = try! NSRegularExpression(
        pattern: "(\\*{3})(?=\\S)(.+?)(?<=\\S)(\\*{3})",
        options: []
    )

    public static let boldItalicUnderscore = try! NSRegularExpression(
        pattern: "(_{3})(?=\\S)(.+?)(?<=\\S)(_{3})",
        options: []
    )

    public static let strikethrough = try! NSRegularExpression(
        pattern: "(~~)(?=\\S)(.+?)(?<=\\S)(~~)",
        options: []
    )

    public static let inlineCode = try! NSRegularExpression(
        pattern: "(`+)(.+?)(\\1)",
        options: []
    )

    public static let link = try! NSRegularExpression(
        pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)",
        options: []
    )

    public static let image = try! NSRegularExpression(
        pattern: "!\\[([^\\]]*)\\]\\(([^)]+)\\)",
        options: []
    )

    public static let autolink = try! NSRegularExpression(
        pattern: "<(https?://[^>]+)>",
        options: []
    )

    public static let emailAutolink = try! NSRegularExpression(
        pattern: "<([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})>",
        options: []
    )

    // MARK: - Front Matter

    public static let frontMatterFull = try! NSRegularExpression(
        pattern: "\\A(---(?:\\r\\n|\\n|\\r)[\\s\\S]*?(?:\\r\\n|\\n|\\r)---)(?:\\r\\n|\\n|\\r)?",
        options: []
    )

    public static let frontMatterDelimiter = try! NSRegularExpression(
        pattern: "^---$",
        options: .anchorsMatchLines
    )

    // MARK: - HTML

    public static let htmlTag = try! NSRegularExpression(
        pattern: "</?[a-zA-Z][^>]*>",
        options: []
    )

    public static let htmlComment = try! NSRegularExpression(
        pattern: "<!--[\\s\\S]*?-->",
        options: []
    )

    // MARK: - Escape Sequences

    public static let escapedCharacter = try! NSRegularExpression(
        pattern: "\\\\([\\\\`*_{}\\[\\]()#+\\-.!|])",
        options: []
    )
}

// MARK: - Pattern Matching Result

public struct MarkdownMatch {
    public let range: NSRange
    public let type: MarkdownElementType
    public let captures: [NSRange]

    public var fullRange: NSRange { range }

    public init(range: NSRange, type: MarkdownElementType, captures: [NSRange]) {
        self.range = range
        self.type = type
        self.captures = captures
    }

    public func captureRange(at index: Int) -> NSRange? {
        guard index < captures.count else { return nil }
        let range = captures[index]
        return range.location != NSNotFound ? range : nil
    }
}

public enum MarkdownElementType {
    case heading(level: Int)
    case bold
    case italic
    case boldItalic
    case strikethrough
    case inlineCode
    case codeBlock
    case blockquote
    case unorderedList
    case orderedList
    case taskList(checked: Bool)
    case horizontalRule
    case link
    case image
    case table
    case tableSeparator
    case frontMatter
    case html
    case escaped
}
