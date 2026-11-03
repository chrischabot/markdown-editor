# Markdown Editor

Markdown Editor is a small native macOS app for people who write notes, documentation or posts in Markdown and would rather see the structure of a document as they type than keep glancing across at a preview pane. Plain Markdown makes you translate symbols in your head, where `**` means bold and `##` means a section heading, and split-pane editors answer by putting the result somewhere else on the screen. This editor applies the formatting to the text you are typing: a heading grows to heading size with its `#` dimmed, bold text turns bold with its asterisks still visible, and a fenced code block takes on a monospaced font and a tinted background, all in the one view where you are writing.

The markers stay in the text, so you can always see and change exactly what will be saved, and because the styling exists only in the editor, the file on disk is the same plain UTF-8 Markdown you typed.

## Install

Download `MarkdownEditor.dmg` from the [latest release](https://github.com/chrischabot/markdown-editor/releases/latest), open it and drag the app to Applications. The app is signed and notarized, and it needs macOS 14 (Sonoma) or later on Apple Silicon. The release contains no Intel build, so on an Intel Mac you will need to [build from source](#development). It runs in the App Sandbox, where it can open and save the files you choose and has no network entitlement.

## Usage

Open a UTF-8 `.md`, `.markdown`, `.mdown`, `.mkd` or `.txt` file, or start a new document, and each one gets its own window with the usual macOS open, save and recent-file handling. Beyond headings and emphasis, the editor strikes through checked tasks, gives link text the link colour while dimming the URL, sets blockquotes in muted, indented italics and shows YAML front matter in monospaced purple. Because it only restyles the text, some elements stop short of their rendered form: table rows keep their proportional spacing with dimmed pipes rather than lining up in columns, and an image stays a line of styled text.

The toolbar and the Format menu write the same Markdown you could type yourself: Bold wraps the selection in `**`, and a list command adds its marker to the start of the current line. They insert markup rather than toggling it, and on a multi-line selection a list command marks only the first line.

| Action | Shortcut |
|--------|----------|
| Bold, italic | Cmd+B, Cmd+I |
| Strikethrough | Shift+Cmd+X |
| Inline code | Cmd+E |
| Heading 1 to 6, remove heading | Cmd+1 to Cmd+6, Cmd+0 |
| Blockquote | Shift+Cmd+. |
| Bulleted, numbered, task list | Shift+Cmd+U, Shift+Cmd+O, Shift+Cmd+T |
| Code block | Shift+Cmd+C |
| Horizontal rule | Shift+Cmd+- |
| Link, image | Cmd+K, Shift+Cmd+I |
| Table | Option+Cmd+T |
| Preview | Shift+Cmd+P |

Spell and grammar checking, the find bar and undo come from the standard macOS text view, while smart quotes, smart dashes, text replacement and autocorrect are switched off so that the editor doesn't rewrite your markup. The status bar keeps a running count of lines, words and characters.

### Preview

Shift+Cmd+P opens a snapshot of the document in a separate WebKit window, styled after GitHub with light and dark variants. It doesn't follow your edits, so press the shortcut again to refresh it. With several documents open, the preview can show a different document; use it with one document open. The HTML comes from a small line-by-line converter rather than a CommonMark or GFM parser, which makes the preview a quick look and not a prediction of what your publishing pipeline will produce: hard-wrapped lines become separate paragraphs, indented list items fall out of their lists, front matter appears as body text and tables repeat once per row. Images are unreliable too, because the page has no base URL for relative paths and the sandboxed release cannot fetch remote ones.

## How it works

The app is a SwiftUI `DocumentGroup` around a TextKit 1 `NSTextView` with a custom `NSTextStorage`, chosen because styling text in place needs direct access to the text storage, which SwiftUI's `TextEditor` doesn't offer. There is no Electron and no web view on the editing side, and the whole v0.2 disk image comes to under a megabyte.

After each edit, `SyntaxHighlighter` waits 16 ms so that a burst of keystrokes collapses into a single pass. It then runs regular expressions over the edited lines plus a small buffer, or over the visible text when TextKit doesn't report an edited range, and applies the resulting fonts, colours and paragraph styles to the text storage. The debounce and the limited range reduce repeated highlighting work on the main thread. Code fences are the exception to that limit, because knowing whether a line sits inside a block means scanning down from the top of the document.

That scan grows with the length of the file, and so does continuous spell checking, which is why very large documents get a mode of their own. At 200,000 characters or 5,000 lines the app switches to Large Document Mode and says so in the status bar: the debounce rises to 50 ms, the highlighted ranges shrink, the fence scan looks back at most 50,000 characters, the counts update less often, and spell and grammar checking turn off. A code block opened further back than that limit can lose its code styling. View > Large Document Mode overrides the automatic choice.

## Development

Building from source needs a Swift 6 toolchain, which comes with Xcode 16 or later.

```bash
git clone https://github.com/chrischabot/markdown-editor.git
cd markdown-editor
swift build -c release          # optimized build
.build/release/MarkdownEditor   # launch it from the terminal
swift run MarkdownEditor        # or build and launch a debug copy
swift test                      # run the XCTest suite
```

The app sets its own activation policy on launch, so a copy started from the terminal still takes keyboard focus. The tests exercise the syntax patterns, front matter parser and document model. Most changes start in `Sources/MarkdownEditorCore`: `Parsing/SyntaxPatterns.swift` decides what gets recognized, `Styling/MarkdownStyles.swift` decides how it looks, `Editor/SyntaxHighlighter.swift` connects the two and `Rendering/MarkdownRenderer.swift` produces the preview. [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) records the original design reasoning, including the choice of TextKit 1 over TextKit 2, though the code has moved on from it in places.

`Scripts/build-dmg.sh` turns the binary into a real app: it wraps it in a bundle with `Sources/Info.plist`, which declares the Markdown file types, signs it with the sandbox entitlements, then notarizes and packages the result. It is set up for the project's own Developer ID and notarytool keychain profile, so change `SIGNING_IDENTITY` and `NOTARIZATION_PROFILE` at the top of the script before running it.

## Project background

- [Markdown editor project overview](https://chabot.dev/projects/#markdown-editor) on Chris Chabot’s site.

## License

[MIT](LICENSE). Front matter parsing uses [Yams](https://github.com/jpsim/Yams) by JP Simard, also under the MIT license.
