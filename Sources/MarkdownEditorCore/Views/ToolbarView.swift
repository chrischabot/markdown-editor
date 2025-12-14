import SwiftUI

struct ToolbarView: View {
    @Binding var text: String
    @State private var showingLinkSheet = false
    @State private var showingImageSheet = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ToolbarGroup {
                    HeadingMenu()
                }

                ToolbarDivider()

                ToolbarGroup {
                    ToolbarButton(icon: "bold", tooltip: "Bold (⌘B)") {
                        NotificationCenter.default.post(name: .formatBold, object: nil)
                    }
                    ToolbarButton(icon: "italic", tooltip: "Italic (⌘I)") {
                        NotificationCenter.default.post(name: .formatItalic, object: nil)
                    }
                    ToolbarButton(icon: "strikethrough", tooltip: "Strikethrough (⇧⌘X)") {
                        NotificationCenter.default.post(name: .formatStrikethrough, object: nil)
                    }
                    ToolbarButton(icon: "chevron.left.forwardslash.chevron.right", tooltip: "Inline Code (⌘E)") {
                        NotificationCenter.default.post(name: .formatCode, object: nil)
                    }
                }

                ToolbarDivider()

                ToolbarGroup {
                    ToolbarButton(icon: "list.bullet", tooltip: "Bulleted List (⇧⌘U)") {
                        NotificationCenter.default.post(name: .formatUnorderedList, object: nil)
                    }
                    ToolbarButton(icon: "list.number", tooltip: "Numbered List (⇧⌘O)") {
                        NotificationCenter.default.post(name: .formatOrderedList, object: nil)
                    }
                    ToolbarButton(icon: "checklist", tooltip: "Task List (⇧⌘T)") {
                        NotificationCenter.default.post(name: .formatTaskList, object: nil)
                    }
                }

                ToolbarDivider()

                ToolbarGroup {
                    ToolbarButton(icon: "text.quote", tooltip: "Blockquote (⇧⌘.)") {
                        NotificationCenter.default.post(name: .formatBlockquote, object: nil)
                    }
                    ToolbarButton(icon: "curlybraces", tooltip: "Code Block (⇧⌘C)") {
                        NotificationCenter.default.post(name: .formatCodeBlock, object: nil)
                    }
                    ToolbarButton(icon: "minus", tooltip: "Horizontal Rule (⇧⌘-)") {
                        NotificationCenter.default.post(name: .formatHorizontalRule, object: nil)
                    }
                }

                ToolbarDivider()

                ToolbarGroup {
                    ToolbarButton(icon: "link", tooltip: "Insert Link (⌘K)") {
                        showingLinkSheet = true
                    }
                    ToolbarButton(icon: "photo", tooltip: "Insert Image (⇧⌘I)") {
                        showingImageSheet = true
                    }
                    ToolbarButton(icon: "tablecells", tooltip: "Insert Table (⌥⌘T)") {
                        NotificationCenter.default.post(name: .insertTable, object: nil)
                    }
                }

                Spacer()

                ToolbarGroup {
                    ToolbarButton(icon: "eye", tooltip: "Preview (⇧⌘P)") {
                        NotificationCenter.default.post(name: .showPreview, object: text)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.bar)
        .sheet(isPresented: $showingLinkSheet) {
            LinkInsertSheet(isPresented: $showingLinkSheet)
        }
        .sheet(isPresented: $showingImageSheet) {
            ImageInsertSheet(isPresented: $showingImageSheet)
        }
    }
}

private struct HeadingMenu: View {
    var body: some View {
        Menu {
            ForEach(1...6, id: \.self) { level in
                Button("Heading \(level)") {
                    NotificationCenter.default.post(name: .formatHeading, object: level)
                }
            }
            Divider()
            Button("Paragraph") {
                NotificationCenter.default.post(name: .formatHeading, object: 0)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "textformat.size")
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundStyle(.primary)
            .frame(height: 28)
            .padding(.horizontal, 8)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .help("Heading Style")
    }
}

private struct ToolbarGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 2) {
            content
        }
    }
}

private struct ToolbarDivider: View {
    var body: some View {
        Divider()
            .frame(height: 20)
            .padding(.horizontal, 6)
    }
}

private struct ToolbarButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 28, height: 28)
                .background(.quaternary.opacity(0.001))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

private struct LinkInsertSheet: View {
    @Binding var isPresented: Bool
    @State private var linkText = ""
    @State private var linkURL = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Insert Link")
                .font(.headline)

            TextField("Link Text", text: $linkText)
                .textFieldStyle(.roundedBorder)

            TextField("URL", text: $linkURL)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Insert") {
                    let link = LinkInsert(text: linkText, url: linkURL)
                    NotificationCenter.default.post(name: .insertLink, object: link)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(linkText.isEmpty || linkURL.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}

private struct ImageInsertSheet: View {
    @Binding var isPresented: Bool
    @State private var altText = ""
    @State private var imageURL = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Insert Image")
                .font(.headline)

            TextField("Alt Text", text: $altText)
                .textFieldStyle(.roundedBorder)

            TextField("Image URL", text: $imageURL)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Insert") {
                    let image = ImageInsert(altText: altText, url: imageURL)
                    NotificationCenter.default.post(name: .insertImage, object: image)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(imageURL.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}

public struct LinkInsert: Sendable {
    public let text: String
    public let url: String

    public init(text: String, url: String) {
        self.text = text
        self.url = url
    }
}

public struct ImageInsert: Sendable {
    public let altText: String
    public let url: String

    public init(altText: String, url: String) {
        self.altText = altText
        self.url = url
    }
}
