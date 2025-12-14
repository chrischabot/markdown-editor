import SwiftUI
import MarkdownEditorCore

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Close") {
                NSApp.sendAction(#selector(NSWindow.performClose(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("w")
        }

        CommandMenu("View") {
            Button("Show Preview") {
                NotificationCenter.default.post(name: .showPreview, object: nil)
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
        }

        CommandMenu("Format") {
            Group {
                Button("Bold") {
                    NotificationCenter.default.post(name: .formatBold, object: nil)
                }
                .keyboardShortcut("b")

                Button("Italic") {
                    NotificationCenter.default.post(name: .formatItalic, object: nil)
                }
                .keyboardShortcut("i")

                Button("Strikethrough") {
                    NotificationCenter.default.post(name: .formatStrikethrough, object: nil)
                }
                .keyboardShortcut("x", modifiers: [.command, .shift])

                Button("Inline Code") {
                    NotificationCenter.default.post(name: .formatCode, object: nil)
                }
                .keyboardShortcut("e")
            }

            Divider()

            Menu("Heading") {
                ForEach(1...6, id: \.self) { level in
                    Button("Heading \(level)") {
                        NotificationCenter.default.post(name: .formatHeading, object: level)
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(level)")))
                }

                Divider()

                Button("Remove Heading") {
                    NotificationCenter.default.post(name: .formatHeading, object: 0)
                }
                .keyboardShortcut("0")
            }

            Divider()

            Group {
                Button("Blockquote") {
                    NotificationCenter.default.post(name: .formatBlockquote, object: nil)
                }
                .keyboardShortcut(".", modifiers: [.command, .shift])

                Button("Bulleted List") {
                    NotificationCenter.default.post(name: .formatUnorderedList, object: nil)
                }
                .keyboardShortcut("u", modifiers: [.command, .shift])

                Button("Numbered List") {
                    NotificationCenter.default.post(name: .formatOrderedList, object: nil)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                Button("Task List") {
                    NotificationCenter.default.post(name: .formatTaskList, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }

            Divider()

            Group {
                Button("Code Block") {
                    NotificationCenter.default.post(name: .formatCodeBlock, object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])

                Button("Horizontal Rule") {
                    NotificationCenter.default.post(name: .formatHorizontalRule, object: nil)
                }
                .keyboardShortcut("-", modifiers: [.command, .shift])
            }

            Divider()

            Group {
                Button("Insert Link...") {
                    NotificationCenter.default.post(name: .insertLink, object: nil)
                }
                .keyboardShortcut("k")

                Button("Insert Image...") {
                    NotificationCenter.default.post(name: .insertImage, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])

                Button("Insert Table") {
                    NotificationCenter.default.post(name: .insertTable, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .option])
            }
        }
    }
}
