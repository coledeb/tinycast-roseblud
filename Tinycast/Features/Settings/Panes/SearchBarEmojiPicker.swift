import SwiftUI

/// tinycast-roseblud: the search bar icon's emoji popover, searched like the Emoji screen.
struct SearchBarEmojiPicker: View {
    let onPick: (String) -> Void
    @Environment(AppCore.self) private var core
    @Environment(AppSettings.self) private var settings
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private static let columnCount = 8
    private static let cell: CGFloat = 32
    private static let height: CGFloat = 300

    private var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(Self.cell), spacing: Theme.Spacing.sm), count: Self.columnCount)
    }

    var body: some View {
        let results = results
        return VStack(spacing: Theme.Spacing.md) {
            // The popover inherits the Settings form's style, which right-aligns its fields.
            TextField("", text: $query, prompt: Text("Search…"))
                .labelsHidden()
                .multilineTextAlignment(.leading)
                .textFieldStyle(.roundedBorder)
                .focused($searchFocused)
                .onSubmit { results.first.map(pick) }
            ScrollView {
                LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
                    ForEach(results) { entry in
                        Button { pick(entry) } label: {
                            Text(verbatim: glyph(entry))
                                .font(.system(size: 22))
                                .frame(width: Self.cell, height: Self.cell)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help(entry.displayName)
                    }
                }
            }
            .overlay {
                if results.isEmpty { Text("No Results").foregroundStyle(.secondary) }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(width: width, height: Self.height)
        .onAppear { searchFocused = true }
    }

    private var width: CGFloat {
        CGFloat(Self.columnCount) * (Self.cell + Theme.Spacing.sm) + Theme.Spacing.md * 2
    }

    /// Symbols and text-style characters share the catalog, but only an emoji may stand in the bar.
    private var results: [EmojiEntry] {
        let index = core.emojiIndex
        let entries =
            query.isEmpty
            ? index.categorySections.flatMap(\.entries) : index.search(query, frequent: core.frequentEmoji)
        return entries.filter { SearchBarIcon.emoji(in: $0.glyph) == $0.glyph }
    }

    private func glyph(_ entry: EmojiEntry) -> String { entry.display(tone: settings.emojiSkinTone) }

    private func pick(_ entry: EmojiEntry) { onPick(glyph(entry)) }
}
