# Markdown Editor

A fast, lightweight markdown editor for macOS that bridges the gap between raw markup and rendered output.

## Philosophy

Markdown is powerful but abstract. When you type `**bold**` or `# Heading`, you're working with symbols that represent formatting rather than seeing the formatting itself. This cognitive translation—mapping markup characters to their visual result—adds friction to the writing process.

This editor takes a different approach: **inline rendering**. As you type, the markdown syntax transforms visually in place. Headings appear larger, bold text becomes bold, code gets monospaced styling. You're still writing markdown (the underlying text remains pure markdown), but you see a representation of the final output as you write.

This isn't a split-pane editor where you write on one side and preview on the other. It's a single unified view where the act of writing and the result of writing occupy the same space. The goal is to let you focus on your thoughts, not on mentally parsing markup syntax.

## Design Principles

**Speed above all.** Every keystroke should feel instant. The editor uses:
- Debounced syntax highlighting (~60fps, 16ms delay) to avoid blocking input
- Incremental highlighting that only processes changed regions
- Throttled statistics updates to prevent unnecessary recalculation
- Native TextKit for hardware-accelerated text rendering

**Lightweight.** No Electron, no web views for editing, no heavy frameworks. Built with Swift and AppKit's native text system (TextKit 1) wrapped in SwiftUI. The binary is small and launches instantly.

**Familiar editing.** Standard macOS text editing behaviors work as expected—spell check, grammar check, find/replace, undo/redo, and all the keyboard shortcuts you already know.

## Features

### Inline Syntax Styling
- **Headings** (H1-H6) render at appropriate sizes with visual weight
- **Bold**, *italic*, and ***bold italic*** text displays with proper styling
- ~~Strikethrough~~ appears struck through
- `Inline code` uses monospace font with subtle background
- Code blocks get distinct styling with language indicators
- Blockquotes show with left border and muted color
- Lists (bulleted, numbered, task) display with proper indentation
- Tables render with aligned columns
- Links and images are visually distinct
- YAML front matter gets special dimmed treatment

### Formatting Tools
- Toolbar with quick-access formatting buttons
- Full Format menu with keyboard shortcuts
- Smart list continuation (press Enter to continue lists)
- Heading level picker

### Preview
- Full rendered preview in a separate window (Shift+Cmd+P)
- GitHub-flavored markdown styling
- Automatic dark/light mode support
- Real HTML rendering via WebKit

### Standard Features
- Multi-document support with tabs
- Native macOS file handling (save, open, recent files)
- Word, line, and character count in status bar
- Standard text editing (spell check, find/replace, etc.)

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Bold | Cmd+B |
| Italic | Cmd+I |
| Inline Code | Cmd+E |
| Insert Link | Cmd+K |
| Insert Image | Shift+Cmd+I |
| Heading 1-6 | Cmd+1 through Cmd+6 |
| Remove Heading | Cmd+0 |
| Blockquote | Shift+Cmd+. |
| Bulleted List | Shift+Cmd+U |
| Numbered List | Shift+Cmd+O |
| Task List | Shift+Cmd+T |
| Code Block | Shift+Cmd+C |
| Horizontal Rule | Shift+Cmd+- |
| Insert Table | Option+Cmd+T |
| Show Preview | Shift+Cmd+P |

## System Requirements

- **macOS 14.0** (Sonoma) or later
- Apple Silicon or Intel Mac
- Built with Swift 6 and strict concurrency checking

## Building

```bash
# Debug build
swift build

# Release build
swift build -c release

# Run tests
swift test

# Run the app
.build/release/MarkdownEditor
```

## License

MIT License. See [LICENSE](LICENSE) for details.
