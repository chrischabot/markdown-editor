import SwiftUI
import AppKit

struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    var onStatsUpdate: @MainActor (Int, Int, Int) -> Void
    var largeDocumentMode: Bool

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = MarkdownNSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = !largeDocumentMode
        textView.isGrammarCheckingEnabled = !largeDocumentMode

        textView.font = NSFont.systemFont(ofSize: MarkdownStyles.baseFontSize)
        textView.textColor = .labelColor
        textView.backgroundColor = .textBackgroundColor
        textView.insertionPointColor = .labelColor

        textView.textContainerInset = NSSize(width: 40, height: 24)

        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        let textStorage = MarkdownTextStorage()
        textView.layoutManager?.replaceTextStorage(textStorage)

        scrollView.documentView = textView

        context.coordinator.textView = textView
        context.coordinator.highlighter = SyntaxHighlighter(textView: textView)
        context.coordinator.highlighter?.setLargeDocumentMode(largeDocumentMode)
        context.coordinator.largeDocumentMode = largeDocumentMode
        context.coordinator.setupNotifications()

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        if context.coordinator.largeDocumentMode != largeDocumentMode {
            context.coordinator.largeDocumentMode = largeDocumentMode
            context.coordinator.highlighter?.setLargeDocumentMode(largeDocumentMode)

            textView.isContinuousSpellCheckingEnabled = !largeDocumentMode
            textView.isGrammarCheckingEnabled = !largeDocumentMode
        }

        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            context.coordinator.highlighter?.highlightAll()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextView
        weak var textView: NSTextView?
        var highlighter: SyntaxHighlighter?
        private nonisolated(unsafe) var notificationObservers: [Any] = []
        var largeDocumentMode: Bool = false

        // Stats throttling
        private var statsWorkItem: DispatchWorkItem?
        private var statsDebounceDelay: TimeInterval { largeDocumentMode ? 0.6 : 0.25 }

        init(_ parent: MarkdownTextView) {
            self.parent = parent
        }

        func setupNotifications() {
            guard let textView else { return }

            let notifications: [Notification.Name] = [
                .formatBold, .formatItalic, .formatStrikethrough, .formatCode,
                .formatBlockquote, .formatUnorderedList, .formatOrderedList, .formatTaskList,
                .formatCodeBlock, .formatHorizontalRule, .insertTable
            ]

            for name in notifications {
                let observer = NotificationCenter.default.addObserver(
                    forName: name,
                    object: textView,
                    queue: .main
                ) { [weak self] notification in
                    let notificationName = notification.name
                    MainActor.assumeIsolated {
                        self?.handleFormatNotification(name: notificationName)
                    }
                }
                notificationObservers.append(observer)
            }

            let headingObserver = NotificationCenter.default.addObserver(
                forName: .formatHeading,
                object: textView,
                queue: .main
            ) { [weak self] notification in
                let level = notification.userInfo?[MarkdownEditorNotificationUserInfoKey.headingLevel] as? Int
                MainActor.assumeIsolated {
                    guard let self = self,
                          let textView = self.textView,
                          let level = level else { return }
                    self.setHeading(in: textView, level: level)
                }
            }
            notificationObservers.append(headingObserver)

            let linkObserver = NotificationCenter.default.addObserver(
                forName: .insertLink,
                object: textView,
                queue: .main
            ) { [weak self] notification in
                let link = notification.userInfo?[MarkdownEditorNotificationUserInfoKey.linkInsert] as? LinkInsert
                MainActor.assumeIsolated {
                    guard let self = self,
                          let textView = self.textView else { return }
                    if let link = link {
                        self.insertLink(in: textView, text: link.text, url: link.url)
                    } else {
                        // Insert with selected text or placeholder
                        self.insertLinkWithSelection(in: textView)
                    }
                }
            }
            notificationObservers.append(linkObserver)

            let imageObserver = NotificationCenter.default.addObserver(
                forName: .insertImage,
                object: textView,
                queue: .main
            ) { [weak self] notification in
                let image = notification.userInfo?[MarkdownEditorNotificationUserInfoKey.imageInsert] as? ImageInsert
                MainActor.assumeIsolated {
                    guard let self = self,
                          let textView = self.textView else { return }
                    if let image = image {
                        self.insertImage(in: textView, alt: image.altText, url: image.url)
                    } else {
                        // Insert with selected text or placeholder
                        self.insertImageWithSelection(in: textView)
                    }
                }
            }
            notificationObservers.append(imageObserver)
        }

        private func handleFormatNotification(name: Notification.Name) {
            guard let textView = textView else { return }

            switch name {
            case .formatBold:
                wrapSelection(in: textView, with: "**")
            case .formatItalic:
                wrapSelection(in: textView, with: "*")
            case .formatStrikethrough:
                wrapSelection(in: textView, with: "~~")
            case .formatCode:
                wrapSelection(in: textView, with: "`")
            case .formatBlockquote:
                prefixLine(in: textView, with: "> ")
            case .formatUnorderedList:
                prefixLine(in: textView, with: "- ")
            case .formatOrderedList:
                prefixLine(in: textView, with: "1. ")
            case .formatTaskList:
                prefixLine(in: textView, with: "- [ ] ")
            case .formatCodeBlock:
                insertCodeBlock(in: textView)
            case .formatHorizontalRule:
                insertHorizontalRule(in: textView)
            case .insertTable:
                insertTable(in: textView)
            default:
                break
            }
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            scheduleStatsUpdate(textView.string)
        }

        private func scheduleStatsUpdate(_ text: String) {
            // Cancel any pending stats update
            statsWorkItem?.cancel()

            // Schedule new stats update with debounce
            let workItem = DispatchWorkItem { [weak self] in
                Task { @MainActor in
                    self?.updateStats(text)
                }
            }
            statsWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + statsDebounceDelay, execute: workItem)
        }

        private func updateStats(_ text: String) {
            let lines = text.components(separatedBy: .newlines).count
            let words = text.split { $0.isWhitespace || $0.isNewline }.count
            let characters = text.count
            parent.onStatsUpdate(words, lines, characters)
        }

        // MARK: - Formatting Actions

        private func wrapSelection(in textView: NSTextView, with marker: String) {
            guard let range = textView.selectedRanges.first?.rangeValue else { return }

            let selectedText = (textView.string as NSString).substring(with: range)
            let wrappedText = "\(marker)\(selectedText)\(marker)"

            textView.insertText(wrappedText, replacementRange: range)

            let newSelection = NSRange(
                location: range.location + marker.utf16.count,
                length: selectedText.utf16.count
            )
            textView.setSelectedRange(newSelection)
        }

        private func prefixLine(in textView: NSTextView, with prefix: String) {
            guard let range = textView.selectedRanges.first?.rangeValue else { return }

            let string = textView.string as NSString
            let lineRange = string.lineRange(for: range)
            let lineContent = string.substring(with: lineRange)

            let existingPrefixPatterns = ["^#{1,6}\\s+", "^>\\s*", "^[-*+]\\s+", "^\\d+\\.\\s+", "^[-*+]\\s+\\[[ xX]\\]\\s+"]

            var cleanLine = lineContent
            for pattern in existingPrefixPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: cleanLine, range: NSRange(location: 0, length: cleanLine.utf16.count)) {
                    cleanLine = (cleanLine as NSString).replacingCharacters(in: match.range, with: "")
                    break
                }
            }

            let newLine = prefix + cleanLine
            textView.insertText(newLine, replacementRange: lineRange)
        }

        private func setHeading(in textView: NSTextView, level: Int) {
            guard let range = textView.selectedRanges.first?.rangeValue else { return }

            let string = textView.string as NSString
            let lineRange = string.lineRange(for: range)
            var lineContent = string.substring(with: lineRange)

            if let regex = try? NSRegularExpression(pattern: "^#{1,6}\\s+"),
               let match = regex.firstMatch(in: lineContent, range: NSRange(location: 0, length: lineContent.utf16.count)) {
                lineContent = (lineContent as NSString).replacingCharacters(in: match.range, with: "")
            }

            let newLine: String
            if level > 0 {
                let hashes = String(repeating: "#", count: level)
                newLine = "\(hashes) \(lineContent)"
            } else {
                newLine = lineContent
            }

            textView.insertText(newLine, replacementRange: lineRange)
        }

        private func insertCodeBlock(in textView: NSTextView) {
            guard let range = textView.selectedRanges.first?.rangeValue else { return }

            let selectedText = (textView.string as NSString).substring(with: range)
            let codeBlock = "```\n\(selectedText)\n```"

            textView.insertText(codeBlock, replacementRange: range)

            textView.setSelectedRange(NSRange(location: range.location + 4, length: selectedText.utf16.count))
        }

        private func insertHorizontalRule(in textView: NSTextView) {
            guard let range = textView.selectedRanges.first?.rangeValue else { return }

            let string = textView.string as NSString
            let lineRange = string.lineRange(for: range)

            let needsLeadingNewline = lineRange.location > 0
            let rule = (needsLeadingNewline ? "\n" : "") + "---\n"

            textView.insertText(rule, replacementRange: NSRange(location: lineRange.upperBound, length: 0))
        }

        private func insertLink(in textView: NSTextView, text: String, url: String) {
            guard let range = textView.selectedRanges.first?.rangeValue else { return }

            let linkMarkdown = "[\(text)](\(url))"
            textView.insertText(linkMarkdown, replacementRange: range)
        }

        private func insertLinkWithSelection(in textView: NSTextView) {
            guard let range = textView.selectedRanges.first?.rangeValue else { return }

            let selectedText = (textView.string as NSString).substring(with: range)
            let linkText = selectedText.isEmpty ? "link text" : selectedText
            let linkMarkdown = "[\(linkText)](url)"
            textView.insertText(linkMarkdown, replacementRange: range)

            // Select the URL placeholder so user can type the actual URL
            let urlStart = range.location + linkText.utf16.count + 3 // [text](
            let urlLength = 3 // "url"
            textView.setSelectedRange(NSRange(location: urlStart, length: urlLength))
        }

        private func insertImage(in textView: NSTextView, alt: String, url: String) {
            guard let range = textView.selectedRanges.first?.rangeValue else { return }

            let imageMarkdown = "![\(alt)](\(url))"
            textView.insertText(imageMarkdown, replacementRange: range)
        }

        private func insertImageWithSelection(in textView: NSTextView) {
            guard let range = textView.selectedRanges.first?.rangeValue else { return }

            let selectedText = (textView.string as NSString).substring(with: range)
            let altText = selectedText.isEmpty ? "image description" : selectedText
            let imageMarkdown = "![\(altText)](url)"
            textView.insertText(imageMarkdown, replacementRange: range)

            // Select the URL placeholder so user can type the actual URL
            let urlStart = range.location + altText.utf16.count + 4 // ![alt](
            let urlLength = 3 // "url"
            textView.setSelectedRange(NSRange(location: urlStart, length: urlLength))
        }

        private func insertTable(in textView: NSTextView) {
            guard let range = textView.selectedRanges.first?.rangeValue else { return }

            let table = """
            | Header 1 | Header 2 | Header 3 |
            |----------|----------|----------|
            | Cell 1   | Cell 2   | Cell 3   |
            | Cell 4   | Cell 5   | Cell 6   |
            """

            textView.insertText(table, replacementRange: range)
        }

        func removeObservers() {
            for observer in notificationObservers {
                NotificationCenter.default.removeObserver(observer)
            }
            notificationObservers.removeAll()
        }

        deinit {
            let observers = notificationObservers
            for observer in observers {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

class MarkdownNSTextView: NSTextView {
    @MainActor
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "b":
                NotificationCenter.default.post(name: .formatBold, object: nil)
                return true
            case "i":
                if event.modifierFlags.contains(.shift) {
                    NotificationCenter.default.post(name: .insertImage, object: nil)
                } else {
                    NotificationCenter.default.post(name: .formatItalic, object: nil)
                }
                return true
            case "k":
                NotificationCenter.default.post(name: .insertLink, object: nil)
                return true
            case "e":
                NotificationCenter.default.post(name: .formatCode, object: nil)
                return true
            case "1", "2", "3", "4", "5", "6":
                if let level = Int(event.charactersIgnoringModifiers ?? "") {
                    NotificationCenter.default.post(name: .formatHeading, object: level)
                }
                return true
            case "0":
                NotificationCenter.default.post(name: .formatHeading, object: 0)
                return true
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}
