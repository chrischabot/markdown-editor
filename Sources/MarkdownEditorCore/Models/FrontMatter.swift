import Foundation

public struct FrontMatter: Equatable, Sendable {
    public var title: String?
    public var date: Date?
    public var author: String?
    public var tags: [String]
    public var customFields: [String: String]

    public init(
        title: String? = nil,
        date: Date? = nil,
        author: String? = nil,
        tags: [String] = [],
        customFields: [String: String] = [:]
    ) {
        self.title = title
        self.date = date
        self.author = author
        self.tags = tags
        self.customFields = customFields
    }
}
