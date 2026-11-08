import Foundation

/// tinycast-roseblud: what the launcher's search bar shows at its left, before the query.
enum SearchBarIcon: String, CaseIterable, Sendable {
    case magnifier
    case emoji

    static let styleKey = "rosebludSearchBarIcon"
    static let emojiKey = "rosebludSearchBarEmoji"
    static let defaultEmoji = "😀"

    /// The last emoji in `text`, so a new pick typed after the old one replaces it.
    static func emoji(in text: String) -> String? {
        text.last(where: isEmoji).map(String.init)
    }

    /// A lone scalar like `©` or `1` is only an emoji with presentation; a sequence is one outright.
    private static func isEmoji(_ character: Character) -> Bool {
        let scalars = character.unicodeScalars
        guard let first = scalars.first, first.properties.isEmoji else { return false }
        return first.properties.isEmojiPresentation || scalars.count > 1
    }
}
