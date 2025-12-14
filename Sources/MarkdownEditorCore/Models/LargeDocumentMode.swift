import Foundation

public enum LargeDocumentModeSetting: String, CaseIterable, Identifiable, Sendable {
    case auto
    case on
    case off

    public var id: String { rawValue }
}

public enum LargeDocumentMode {
    public static let storageKey = "largeDocumentModeSetting"

    public static let defaultCharacterThreshold = 200_000
    public static let defaultLineThreshold = 5_000

    public static func shouldEnableAutomatically(characters: Int, lines: Int) -> Bool {
        characters >= defaultCharacterThreshold || lines >= defaultLineThreshold
    }
}

