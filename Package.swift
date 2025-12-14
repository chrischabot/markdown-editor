// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MarkdownEditor",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.4.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.0")
    ],
    targets: [
        .target(
            name: "MarkdownEditorCore",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Yams", package: "Yams")
            ],
            path: "Sources/MarkdownEditorCore"
        ),
        .executableTarget(
            name: "MarkdownEditor",
            dependencies: [
                "MarkdownEditorCore"
            ],
            path: "Sources/MarkdownEditor"
        ),
        .testTarget(
            name: "MarkdownEditorTests",
            dependencies: [
                "MarkdownEditorCore",
                .product(name: "Yams", package: "Yams")
            ],
            path: "Tests/MarkdownEditorTests"
        )
    ]
)
