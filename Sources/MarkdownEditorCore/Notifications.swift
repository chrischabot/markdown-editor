import Foundation

public extension Notification.Name {
    static let formatBold = Notification.Name("formatBold")
    static let formatItalic = Notification.Name("formatItalic")
    static let formatStrikethrough = Notification.Name("formatStrikethrough")
    static let formatCode = Notification.Name("formatCode")
    static let formatHeading = Notification.Name("formatHeading")
    static let formatBlockquote = Notification.Name("formatBlockquote")
    static let formatUnorderedList = Notification.Name("formatUnorderedList")
    static let formatOrderedList = Notification.Name("formatOrderedList")
    static let formatTaskList = Notification.Name("formatTaskList")
    static let formatCodeBlock = Notification.Name("formatCodeBlock")
    static let formatHorizontalRule = Notification.Name("formatHorizontalRule")
    static let insertLink = Notification.Name("insertLink")
    static let insertImage = Notification.Name("insertImage")
    static let insertTable = Notification.Name("insertTable")
    static let showPreview = Notification.Name("showPreview")
}

public enum MarkdownEditorNotificationUserInfoKey {
    public static let headingLevel = "headingLevel"
    public static let linkInsert = "linkInsert"
    public static let imageInsert = "imageInsert"
}
