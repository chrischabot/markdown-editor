import SwiftUI
import AppKit
import MarkdownEditorCore

@main
struct MarkdownEditorApp: App {
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document)
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
        .commands {
            AppCommands()
        }
        .defaultSize(width: 900, height: 700)
    }
}
