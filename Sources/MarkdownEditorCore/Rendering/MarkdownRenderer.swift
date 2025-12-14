import Foundation

/// Converts Markdown text to HTML for preview rendering
public enum MarkdownRenderer {

    public static func render(_ markdown: String) -> String {
        let html = convertToHTML(markdown)
        return wrapInHTMLDocument(html)
    }

    private static func convertToHTML(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: "\n")
        var html: [String] = []
        var inCodeBlock = false
        var codeBlockContent: [String] = []
        var codeBlockLanguage = ""
        var inList = false
        var listType = ""

        for (index, line) in lines.enumerated() {
            // Handle fenced code blocks
            if line.hasPrefix("```") || line.hasPrefix("~~~") {
                if inCodeBlock {
                    // End code block
                    let code = escapeHTML(codeBlockContent.joined(separator: "\n"))
                    if codeBlockLanguage.isEmpty {
                        html.append("<pre><code>\(code)</code></pre>")
                    } else {
                        html.append("<pre><code class=\"language-\(codeBlockLanguage)\">\(code)</code></pre>")
                    }
                    codeBlockContent = []
                    codeBlockLanguage = ""
                    inCodeBlock = false
                } else {
                    // Start code block
                    closeListIfNeeded(&html, &inList, &listType)
                    inCodeBlock = true
                    let prefix = line.hasPrefix("```") ? "```" : "~~~"
                    codeBlockLanguage = String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                }
                continue
            }

            if inCodeBlock {
                codeBlockContent.append(line)
                continue
            }

            // Empty line
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                closeListIfNeeded(&html, &inList, &listType)
                html.append("")
                continue
            }

            // Horizontal rule
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if isHorizontalRule(trimmed) {
                closeListIfNeeded(&html, &inList, &listType)
                html.append("<hr>")
                continue
            }

            // Headings
            if let (level, content) = parseHeading(line) {
                closeListIfNeeded(&html, &inList, &listType)
                let processedContent = processInlineMarkdown(content)
                html.append("<h\(level)>\(processedContent)</h\(level)>")
                continue
            }

            // Blockquote
            if line.hasPrefix(">") {
                closeListIfNeeded(&html, &inList, &listType)
                var content = String(line.dropFirst())
                if content.hasPrefix(" ") {
                    content = String(content.dropFirst())
                }
                let processedContent = processInlineMarkdown(content)
                html.append("<blockquote><p>\(processedContent)</p></blockquote>")
                continue
            }

            // Task lists
            if let (checked, content) = parseTaskListItem(line) {
                if !inList || listType != "task" {
                    closeListIfNeeded(&html, &inList, &listType)
                    html.append("<ul class=\"task-list\">")
                    inList = true
                    listType = "task"
                }
                let checkboxState = checked ? "checked disabled" : "disabled"
                let processedContent = processInlineMarkdown(content)
                html.append("<li class=\"task-list-item\"><input type=\"checkbox\" \(checkboxState)> \(processedContent)</li>")
                continue
            }

            // Unordered list
            if let content = parseUnorderedListItem(line) {
                if !inList || listType != "ul" {
                    closeListIfNeeded(&html, &inList, &listType)
                    html.append("<ul>")
                    inList = true
                    listType = "ul"
                }
                let processedContent = processInlineMarkdown(content)
                html.append("<li>\(processedContent)</li>")
                continue
            }

            // Ordered list
            if let content = parseOrderedListItem(line) {
                if !inList || listType != "ol" {
                    closeListIfNeeded(&html, &inList, &listType)
                    html.append("<ol>")
                    inList = true
                    listType = "ol"
                }
                let processedContent = processInlineMarkdown(content)
                html.append("<li>\(processedContent)</li>")
                continue
            }

            // Table detection
            if line.contains("|") && isTableRow(line) {
                closeListIfNeeded(&html, &inList, &listType)
                let tableHTML = parseTable(lines, startingAt: index)
                if !tableHTML.isEmpty {
                    html.append(tableHTML)
                    // Skip the remaining table rows (handled by parseTable)
                    continue
                }
            }

            // Regular paragraph
            closeListIfNeeded(&html, &inList, &listType)
            let processedLine = processInlineMarkdown(line)
            html.append("<p>\(processedLine)</p>")
        }

        closeListIfNeeded(&html, &inList, &listType)

        return html.joined(separator: "\n")
    }

    private static func closeListIfNeeded(_ html: inout [String], _ inList: inout Bool, _ listType: inout String) {
        if inList {
            switch listType {
            case "ul", "task":
                html.append("</ul>")
            case "ol":
                html.append("</ol>")
            default:
                break
            }
            inList = false
            listType = ""
        }
    }

    private static func isHorizontalRule(_ line: String) -> Bool {
        let stripped = line.replacingOccurrences(of: " ", with: "")
        if stripped.count < 3 { return false }
        let chars = Set(stripped)
        return chars.count == 1 && (chars.contains("-") || chars.contains("*") || chars.contains("_"))
    }

    private static func parseHeading(_ line: String) -> (Int, String)? {
        let pattern = "^(#{1,6})\\s+(.+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }

        guard let hashRange = Range(match.range(at: 1), in: line),
              let contentRange = Range(match.range(at: 2), in: line) else {
            return nil
        }

        let level = line[hashRange].count
        let content = String(line[contentRange])
        return (level, content)
    }

    private static func parseTaskListItem(_ line: String) -> (Bool, String)? {
        let pattern = "^[-*+]\\s+\\[([ xX])\\]\\s+(.*)$"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }

        guard let checkRange = Range(match.range(at: 1), in: line),
              let contentRange = Range(match.range(at: 2), in: line) else {
            return nil
        }

        let checked = line[checkRange] != " "
        let content = String(line[contentRange])
        return (checked, content)
    }

    private static func parseUnorderedListItem(_ line: String) -> String? {
        let pattern = "^[-*+]\\s+(.*)$"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let contentRange = Range(match.range(at: 1), in: line) else {
            return nil
        }
        // Exclude task list items
        if line.contains("[ ]") || line.contains("[x]") || line.contains("[X]") {
            return nil
        }
        return String(line[contentRange])
    }

    private static func parseOrderedListItem(_ line: String) -> String? {
        let pattern = "^\\d+\\.\\s+(.*)$"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let contentRange = Range(match.range(at: 1), in: line) else {
            return nil
        }
        return String(line[contentRange])
    }

    private static func isTableRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("|") && trimmed.hasSuffix("|")
    }

    private static func parseTable(_ lines: [String], startingAt startIndex: Int) -> String {
        var tableLines: [String] = []
        for i in startIndex..<lines.count {
            let line = lines[i]
            if isTableRow(line) || isTableSeparator(line) {
                tableLines.append(line)
            } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                break
            } else {
                break
            }
        }

        guard tableLines.count >= 2 else { return "" }

        var html = "<table>\n"

        // Header row
        let headerCells = parseTableCells(tableLines[0])
        html += "<thead><tr>"
        for cell in headerCells {
            html += "<th>\(processInlineMarkdown(cell))</th>"
        }
        html += "</tr></thead>\n"

        // Body rows (skip separator if present)
        let bodyStartIndex = isTableSeparator(tableLines[1]) ? 2 : 1
        if bodyStartIndex < tableLines.count {
            html += "<tbody>\n"
            for i in bodyStartIndex..<tableLines.count {
                let cells = parseTableCells(tableLines[i])
                html += "<tr>"
                for cell in cells {
                    html += "<td>\(processInlineMarkdown(cell))</td>"
                }
                html += "</tr>\n"
            }
            html += "</tbody>\n"
        }

        html += "</table>"
        return html
    }

    private static func isTableSeparator(_ line: String) -> Bool {
        let stripped = line.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "|", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: ":", with: "")
        return stripped.isEmpty
    }

    private static func parseTableCells(_ line: String) -> [String] {
        var cells = line.components(separatedBy: "|")
        // Remove empty first and last elements from | delimiters
        if cells.first?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            cells.removeFirst()
        }
        if cells.last?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            cells.removeLast()
        }
        return cells.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private static func processInlineMarkdown(_ text: String) -> String {
        var result = escapeHTML(text)

        // Images: ![alt](url)
        result = result.replacingOccurrences(
            of: "!\\[([^\\]]*)\\]\\(([^)]+)\\)",
            with: "<img src=\"$2\" alt=\"$1\">",
            options: .regularExpression
        )

        // Links: [text](url)
        result = result.replacingOccurrences(
            of: "\\[([^\\]]+)\\]\\(([^)]+)\\)",
            with: "<a href=\"$2\">$1</a>",
            options: .regularExpression
        )

        // Bold italic: ***text*** or ___text___
        result = result.replacingOccurrences(
            of: "\\*\\*\\*([^*]+)\\*\\*\\*",
            with: "<strong><em>$1</em></strong>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "___([^_]+)___",
            with: "<strong><em>$1</em></strong>",
            options: .regularExpression
        )

        // Bold: **text** or __text__
        result = result.replacingOccurrences(
            of: "\\*\\*([^*]+)\\*\\*",
            with: "<strong>$1</strong>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "__([^_]+)__",
            with: "<strong>$1</strong>",
            options: .regularExpression
        )

        // Italic: *text* or _text_
        result = result.replacingOccurrences(
            of: "\\*([^*]+)\\*",
            with: "<em>$1</em>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "(?<![\\w])_([^_]+)_(?![\\w])",
            with: "<em>$1</em>",
            options: .regularExpression
        )

        // Strikethrough: ~~text~~
        result = result.replacingOccurrences(
            of: "~~([^~]+)~~",
            with: "<del>$1</del>",
            options: .regularExpression
        )

        // Inline code: `code`
        result = result.replacingOccurrences(
            of: "`([^`]+)`",
            with: "<code>$1</code>",
            options: .regularExpression
        )

        // Autolinks: <https://...>
        result = result.replacingOccurrences(
            of: "&lt;(https?://[^&]+)&gt;",
            with: "<a href=\"$1\">$1</a>",
            options: .regularExpression
        )

        return result
    }

    private static func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func wrapInHTMLDocument(_ body: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                :root {
                    color-scheme: light dark;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
                    font-size: 16px;
                    line-height: 1.6;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 40px 24px;
                    color: var(--text-color);
                    background: var(--bg-color);
                }
                @media (prefers-color-scheme: dark) {
                    :root {
                        --text-color: #e6edf3;
                        --bg-color: #0d1117;
                        --code-bg: #161b22;
                        --border-color: #30363d;
                        --link-color: #58a6ff;
                        --blockquote-color: #8b949e;
                    }
                }
                @media (prefers-color-scheme: light) {
                    :root {
                        --text-color: #1f2328;
                        --bg-color: #ffffff;
                        --code-bg: #f6f8fa;
                        --border-color: #d0d7de;
                        --link-color: #0969da;
                        --blockquote-color: #656d76;
                    }
                }
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 24px;
                    margin-bottom: 16px;
                    font-weight: 600;
                    line-height: 1.25;
                }
                h1 { font-size: 2em; border-bottom: 1px solid var(--border-color); padding-bottom: 0.3em; }
                h2 { font-size: 1.5em; border-bottom: 1px solid var(--border-color); padding-bottom: 0.3em; }
                h3 { font-size: 1.25em; }
                h4 { font-size: 1em; }
                h5 { font-size: 0.875em; }
                h6 { font-size: 0.85em; color: var(--blockquote-color); }
                p { margin-top: 0; margin-bottom: 16px; }
                a { color: var(--link-color); text-decoration: none; }
                a:hover { text-decoration: underline; }
                code {
                    font-family: ui-monospace, SFMono-Regular, SF Mono, Menlo, Consolas, monospace;
                    font-size: 85%;
                    background: var(--code-bg);
                    padding: 0.2em 0.4em;
                    border-radius: 6px;
                }
                pre {
                    background: var(--code-bg);
                    padding: 16px;
                    overflow: auto;
                    border-radius: 6px;
                    margin-bottom: 16px;
                }
                pre code {
                    background: none;
                    padding: 0;
                    font-size: 85%;
                    line-height: 1.45;
                }
                blockquote {
                    margin: 0 0 16px 0;
                    padding: 0 1em;
                    color: var(--blockquote-color);
                    border-left: 0.25em solid var(--border-color);
                }
                blockquote p { margin-bottom: 0; }
                ul, ol {
                    margin-top: 0;
                    margin-bottom: 16px;
                    padding-left: 2em;
                }
                li { margin-top: 0.25em; }
                li + li { margin-top: 0.25em; }
                ul.task-list {
                    list-style: none;
                    padding-left: 0;
                }
                .task-list-item {
                    display: flex;
                    align-items: baseline;
                    gap: 0.5em;
                }
                .task-list-item input[type="checkbox"] {
                    margin: 0;
                }
                hr {
                    height: 0.25em;
                    padding: 0;
                    margin: 24px 0;
                    background-color: var(--border-color);
                    border: 0;
                    border-radius: 2px;
                }
                table {
                    border-collapse: collapse;
                    width: 100%;
                    margin-bottom: 16px;
                }
                th, td {
                    padding: 6px 13px;
                    border: 1px solid var(--border-color);
                }
                th {
                    font-weight: 600;
                    background: var(--code-bg);
                }
                tr:nth-child(even) {
                    background: var(--code-bg);
                }
                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 6px;
                }
                del { color: var(--blockquote-color); }
            </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }
}
