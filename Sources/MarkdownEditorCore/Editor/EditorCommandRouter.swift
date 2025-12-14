import AppKit

@MainActor
public enum EditorCommandRouter {
    public static func post(_ name: Notification.Name, userInfo: [AnyHashable: Any]? = nil) {
        NotificationCenter.default.post(name: name, object: targetTextView(), userInfo: userInfo)
    }

    private static func targetTextView() -> MarkdownNSTextView? {
        if let view = NSApp.keyWindow?.firstResponder as? MarkdownNSTextView {
            return view
        }

        if let contentView = NSApp.keyWindow?.contentView, let found = findMarkdownTextView(in: contentView) {
            return found
        }

        if let mainContentView = NSApp.mainWindow?.contentView, let found = findMarkdownTextView(in: mainContentView) {
            return found
        }

        return nil
    }

    private static func findMarkdownTextView(in view: NSView) -> MarkdownNSTextView? {
        if let textView = view as? MarkdownNSTextView {
            return textView
        }

        for subview in view.subviews {
            if let found = findMarkdownTextView(in: subview) {
                return found
            }
        }

        return nil
    }
}

