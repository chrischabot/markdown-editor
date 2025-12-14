import SwiftUI
import WebKit

/// A view that renders Markdown as HTML in a WebView
public struct PreviewView: View {
    let markdown: String
    let title: String

    public init(markdown: String, title: String = "Preview") {
        self.markdown = markdown
        self.title = title
    }

    public var body: some View {
        WebView(html: MarkdownRenderer.render(markdown))
            .frame(minWidth: 500, minHeight: 400)
            .background(Color(nsColor: .textBackgroundColor))
    }
}

struct WebView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.isTextInteractionEnabled = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}

/// Controller for opening preview in a new window
@MainActor
public final class PreviewWindowController {
    private var window: NSWindow?

    public static let shared = PreviewWindowController()

    private init() {}

    public func showPreview(markdown: String, title: String) {
        // Close existing preview window if open
        window?.close()

        let previewView = PreviewView(markdown: markdown, title: title)
        let hostingView = NSHostingView(rootView: previewView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        newWindow.title = "Preview: \(title)"
        newWindow.contentView = hostingView
        newWindow.center()
        newWindow.setFrameAutosaveName("MarkdownPreview")
        newWindow.isReleasedWhenClosed = false

        // Position to the right of the key window if possible
        if let keyWindow = NSApp.keyWindow {
            let keyFrame = keyWindow.frame
            let newX = keyFrame.maxX + 20
            let newY = keyFrame.origin.y
            newWindow.setFrameOrigin(NSPoint(x: newX, y: newY))
        }

        newWindow.makeKeyAndOrderFront(nil)
        self.window = newWindow
    }

    public func updatePreview(markdown: String) {
        guard let window = window, window.isVisible else { return }

        let previewView = PreviewView(markdown: markdown, title: window.title.replacingOccurrences(of: "Preview: ", with: ""))
        let hostingView = NSHostingView(rootView: previewView)
        window.contentView = hostingView
    }

    public var isVisible: Bool {
        window?.isVisible ?? false
    }

    public func close() {
        window?.close()
        window = nil
    }
}
