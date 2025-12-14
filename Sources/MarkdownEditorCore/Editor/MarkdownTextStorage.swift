import AppKit

final class MarkdownTextStorage: NSTextStorage, @unchecked Sendable {
    private let backingStore = NSMutableAttributedString()

    override var string: String {
        backingStore.string
    }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        backingStore.attributes(at: location, effectiveRange: range)
    }

    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        backingStore.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range, changeInLength: str.count - range.length)
        endEditing()
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        beginEditing()
        backingStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    override func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
        beginEditing()
        backingStore.addAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    override func removeAttribute(_ name: NSAttributedString.Key, range: NSRange) {
        beginEditing()
        backingStore.removeAttribute(name, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
}
