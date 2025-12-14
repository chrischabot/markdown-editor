import SwiftUI
import MarkdownEditorCore

struct AppCommands: Commands {
    @AppStorage(LargeDocumentMode.storageKey) private var largeDocumentModeSettingRaw: String = LargeDocumentModeSetting.auto.rawValue

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

            Divider()

            Picker("Large Document Mode", selection: $largeDocumentModeSettingRaw) {
                Text("Auto").tag(LargeDocumentModeSetting.auto.rawValue)
                Text("On").tag(LargeDocumentModeSetting.on.rawValue)
                Text("Off").tag(LargeDocumentModeSetting.off.rawValue)
            }
        }

        CommandMenu("Format") {
            Group {
                Button("Bold") {
                    EditorCommandRouter.post(.formatBold)
                }
                .keyboardShortcut("b")

                Button("Italic") {
                    EditorCommandRouter.post(.formatItalic)
                }
                .keyboardShortcut("i")

                Button("Strikethrough") {
                    EditorCommandRouter.post(.formatStrikethrough)
                }
                .keyboardShortcut("x", modifiers: [.command, .shift])

                Button("Inline Code") {
                    EditorCommandRouter.post(.formatCode)
                }
                .keyboardShortcut("e")
            }

            Divider()

            Menu("Heading") {
                ForEach(1...6, id: \.self) { level in
                    Button("Heading \(level)") {
                        EditorCommandRouter.post(
                            .formatHeading,
                            userInfo: [MarkdownEditorNotificationUserInfoKey.headingLevel: level]
                        )
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(level)")))
                }

                Divider()

                Button("Remove Heading") {
                    EditorCommandRouter.post(
                        .formatHeading,
                        userInfo: [MarkdownEditorNotificationUserInfoKey.headingLevel: 0]
                    )
                }
                .keyboardShortcut("0")
            }

            Divider()

            Group {
                Button("Blockquote") {
                    EditorCommandRouter.post(.formatBlockquote)
                }
                .keyboardShortcut(".", modifiers: [.command, .shift])

                Button("Bulleted List") {
                    EditorCommandRouter.post(.formatUnorderedList)
                }
                .keyboardShortcut("u", modifiers: [.command, .shift])

                Button("Numbered List") {
                    EditorCommandRouter.post(.formatOrderedList)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                Button("Task List") {
                    EditorCommandRouter.post(.formatTaskList)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }

            Divider()

            Group {
                Button("Code Block") {
                    EditorCommandRouter.post(.formatCodeBlock)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])

                Button("Horizontal Rule") {
                    EditorCommandRouter.post(.formatHorizontalRule)
                }
                .keyboardShortcut("-", modifiers: [.command, .shift])
            }

            Divider()

            Group {
                Button("Insert Link...") {
                    EditorCommandRouter.post(.insertLink)
                }
                .keyboardShortcut("k")

                Button("Insert Image...") {
                    EditorCommandRouter.post(.insertImage)
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])

                Button("Insert Table") {
                    EditorCommandRouter.post(.insertTable)
                }
                .keyboardShortcut("t", modifiers: [.command, .option])
            }
        }
    }
}
