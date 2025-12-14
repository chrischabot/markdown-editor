import Foundation
import Yams

public struct FrontMatterParser {
    public struct ParseResult {
        public let frontMatter: FrontMatter
        public let yamlRange: NSRange
        public let contentStartIndex: Int

        public init(frontMatter: FrontMatter, yamlRange: NSRange, contentStartIndex: Int) {
            self.frontMatter = frontMatter
            self.yamlRange = yamlRange
            self.contentStartIndex = contentStartIndex
        }
    }

    public static func parse(_ text: String) -> ParseResult? {
        let nsString = text as NSString

        guard let match = SyntaxPatterns.frontMatterFull.firstMatch(
            in: text,
            range: NSRange(location: 0, length: min(nsString.length, 5000))
        ) else {
            return nil
        }

        let fullRange = match.range
        let yamlContent = nsString.substring(with: fullRange)

        let trimmed = yamlContent
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .dropFirst(3)
            .dropLast(3)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let frontMatter = parseYAML(String(trimmed))

        return ParseResult(
            frontMatter: frontMatter,
            yamlRange: fullRange,
            contentStartIndex: fullRange.upperBound
        )
    }

    private static func parseYAML(_ yaml: String) -> FrontMatter {
        var title: String?
        var date: Date?
        var author: String?
        var tags: [String] = []
        var customFields: [String: String] = [:]

        do {
            if let parsed = try Yams.load(yaml: yaml) as? [String: Any] {
                title = parsed["title"] as? String
                author = parsed["author"] as? String

                if let dateString = parsed["date"] as? String {
                    date = parseDate(dateString)
                } else if let dateValue = parsed["date"] as? Date {
                    date = dateValue
                }

                if let tagArray = parsed["tags"] as? [String] {
                    tags = tagArray
                } else if let tagString = parsed["tags"] as? String {
                    tags = tagString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                }

                for (key, value) in parsed {
                    if !["title", "date", "author", "tags"].contains(key) {
                        if let stringValue = value as? String {
                            customFields[key] = stringValue
                        } else if let intValue = value as? Int {
                            customFields[key] = String(intValue)
                        } else if let boolValue = value as? Bool {
                            customFields[key] = String(boolValue)
                        }
                    }
                }
            }
        } catch {
            for line in yaml.split(separator: "\n") {
                let parts = line.split(separator: ":", maxSplits: 1)
                if parts.count == 2 {
                    let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                    let value = String(parts[1]).trimmingCharacters(in: .whitespaces)

                    switch key.lowercased() {
                    case "title": title = value
                    case "author": author = value
                    case "date": date = parseDate(value)
                    case "tags":
                        tags = value
                            .trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                    default:
                        customFields[key] = value
                    }
                }
            }
        }

        return FrontMatter(
            title: title,
            date: date,
            author: author,
            tags: tags,
            customFields: customFields
        )
    }

    private static func parseDate(_ string: String) -> Date? {
        let formatters: [DateFormatter] = [
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                return f
            }()
        ]

        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }

        return nil
    }
}
