# Markdown Editor - Implementation Plan

## Overview

A macOS markdown editor built with Swift 6 and SwiftUI featuring:
- Inline live rendering (see raw markdown AND rendered formatting simultaneously)
- Liquid glass UI style similar to Apple Notes
- Complete markdown toolbar with all standard formatting options
- YAML front matter support
- High performance with large documents

---

## Architecture Decision: Custom NSTextView with TextKit 1

**Why TextKit 1 over TextKit 2:**
- TextKit 2 still has significant bugs (scrolling issues, viewport problems)
- TextKit 1's NSTextStorage/NSLayoutManager are mature and well-documented
- Proven patterns exist for real-time syntax highlighting
- Better cursor position preservation

**Why NOT pure SwiftUI TextEditor:**
- Limited markdown support (no headings, code blocks, tables)
- No access to underlying text storage for fine-grained styling
- Performance concerns with large documents

---

## Project Structure

```
MarkdownEditor/
├── Package.swift
├── Sources/
│   └── MarkdownEditor/
│       ├── App/
│       │   ├── MarkdownEditorApp.swift      # @main, DocumentGroup, CLI focus fix
│       │   ├── AppCommands.swift            # Menu bar commands
│       │   └── AppConstants.swift           # Shortcuts, constants
│       │
│       ├── Models/
│       │   ├── MarkdownDocument.swift       # FileDocument conformance
│       │   ├── MarkdownElement.swift        # Parsed element types
│       │   └── EditorState.swift            # Selection, scroll state
│       │
│       ├── Views/
│       │   ├── ContentView.swift            # Main document view
│       │   ├── EditorView.swift             # Editor container
│       │   ├── ToolbarView.swift            # Formatting toolbar
│       │   └── StatusBarView.swift          # Word count, line info
│       │
│       ├── Editor/
│       │   ├── MarkdownTextView.swift       # NSViewRepresentable wrapper
│       │   ├── MarkdownNSTextView.swift     # Custom NSTextView subclass
│       │   ├── MarkdownTextStorage.swift    # Custom NSTextStorage
│       │   ├── SyntaxHighlighter.swift      # Real-time styling engine
│       │   └── CursorManager.swift          # Cursor preservation
│       │
│       ├── Parsing/
│       │   ├── MarkdownParser.swift         # Parser coordinator
│       │   ├── FrontMatterParser.swift      # YAML front matter
│       │   └── SyntaxPatterns.swift         # Regex patterns
│       │
│       └── Styling/
│           ├── Theme.swift                  # Theme protocol
│           ├── MarkdownStyles.swift         # Element styles
│           └── GlassEffect.swift            # Liquid glass styling
```

---

## Complete Markdown Syntax Support

### Block Elements
| Element | Syntax | Shortcut |
|---------|--------|----------|
| Heading 1-6 | `# ` to `###### ` | Cmd+1 to Cmd+6 |
| Blockquote | `> text` | Cmd+Shift+. |
| Unordered List | `- item` | Cmd+Shift+U |
| Ordered List | `1. item` | Cmd+Shift+O |
| Task List | `- [ ] item` | Cmd+Shift+T |
| Code Block | ` ```lang ``` ` | Cmd+Shift+C |
| Horizontal Rule | `---` | Cmd+Shift+- |
| Table | `| col | col |` | Cmd+Option+T |

### Inline Elements
| Element | Syntax | Shortcut |
|---------|--------|----------|
| Bold | `**text**` | Cmd+B |
| Italic | `*text*` | Cmd+I |
| Bold+Italic | `***text***` | Cmd+Shift+B |
| Strikethrough | `~~text~~` | Cmd+Shift+X |
| Inline Code | `` `code` `` | Cmd+E |
| Link | `[text](url)` | Cmd+K |
| Image | `![alt](url)` | Cmd+Shift+I |

### Front Matter
```yaml
---
title: My Document
date: 2025-01-01
tags: [markdown, editor]
---
```

# this is a test

## CLI Keyboard Focus Fix

When running via `swift run`, keyboard input goes to terminal instead of the app. Fix:

```swift
@main
struct MarkdownEditorApp: App {
    init() {
        #if os(macOS)
        NSApplication.shared.setActivationPolicy(.regular)
        #endif
    }

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document)
                #if os(macOS)
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
                #endif
        }
    }
}
```

---

## Editor Rendering Strategy

The key technical challenge: show raw markdown syntax while applying visual formatting.

### Implementation Approach

1. **NSTextStorage Subclass** - Stores the raw text and coordinates highlighting
2. **Notification-Based Highlighting** - Apply styles via `NSText.didChangeNotification`, NOT during `processEditing()` (causes cursor issues)
3. **Visible Range Optimization** - For large documents, only highlight visible range + buffer
4. **Cursor Preservation** - Save/restore selection around highlight operations

### Style Application

```swift
// Headings: Show # but render text large
"# Title" → # is dimmed gray, "Title" is 32pt bold

// Bold: Show ** but render text bold
"**text**" → ** is dimmed gray, "text" is bold

// All markdown delimiters are visible but dimmed
```

---

## Implementation Phases

### Phase 1: Project Setup
- [ ] Create Swift Package with macOS app target
- [ ] Set up DocumentGroup with MarkdownDocument
- [ ] Implement CLI keyboard focus fix
- [ ] Basic window with placeholder editor

### Phase 2: Editor Core
- [ ] Create MarkdownTextStorage (NSTextStorage subclass)
- [ ] Create MarkdownNSTextView (NSTextView subclass)
- [ ] Build MarkdownTextView (NSViewRepresentable wrapper)
- [ ] Wire up two-way text binding

### Phase 3: Syntax Highlighting
- [ ] Implement SyntaxPatterns with all regex
- [ ] Create SyntaxHighlighter with notification-based updates
- [ ] Add heading styles (h1-h6)
- [ ] Add inline styles (bold, italic, code, strikethrough)
- [ ] Add block styles (lists, blockquotes, code blocks)
- [ ] Add front matter highlighting
- [ ] Implement cursor position preservation

### Phase 4: Toolbar & Commands
- [ ] Create ToolbarView with liquid glass style
- [ ] Add all formatting buttons
- [ ] Implement keyboard shortcuts
- [ ] Add Format menu with all options

### Phase 5: Polish
- [ ] Status bar (word count, line numbers)
- [ ] Performance optimization for large documents
- [ ] Theme support (respects system light/dark)
- [ ] Table syntax support

---

## Dependencies

| Package | Purpose |
|---------|---------|
| swift-markdown | AST parsing (Apple) |
| Yams | YAML front matter parsing |

---

## Performance Critical Points

1. **Use Swift for NSTextStorage** - Despite Obj-C recommendations, we'll use Swift with careful optimization
2. **Incremental highlighting** - Only re-highlight changed ranges
3. **Visible range optimization** - For docs > 5000 lines, only highlight visible + buffer
4. **Batch attribute changes** - Always wrap in `beginEditing()`/`endEditing()`
5. **Avoid highlighting in processEditing()** - Use notification-based approach
