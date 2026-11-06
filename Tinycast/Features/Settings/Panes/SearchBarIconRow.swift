import SwiftUI

/// tinycast-roseblud: Settings → General → Appearance, the launcher's search bar icon.
struct SearchBarIconRow: View {
    @AppStorage(SearchBarIcon.styleKey) private var style = SearchBarIcon.magnifier
    @AppStorage(SearchBarIcon.emojiKey) private var emoji = SearchBarIcon.defaultEmoji
    @State private var picking = false

    var body: some View {
        LabeledContent {
            HStack(spacing: Theme.Spacing.sm) {
                SearchBarIconTile(isSelected: style == .magnifier, help: "Search icon") {
                    style = .magnifier
                } label: {
                    Image(systemName: PaletteMode.launcher.systemImage)
                        .font(Theme.Typography.headerIcon)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                SearchBarIconTile(isSelected: style == .emoji, help: "Choose an emoji") {
                    style = .emoji
                    picking = true
                } label: {
                    Text(verbatim: shownEmoji).font(Theme.Typography.headerIcon)
                }
                .popover(isPresented: $picking, arrowEdge: .bottom) {
                    SearchBarEmojiPicker { picked in
                        emoji = picked
                        picking = false
                    }
                }
            }
        } label: {
            SettingsRowTitle(.generalAppearance, "Search bar icon")
        }
    }

    private var shownEmoji: String { SearchBarIcon.emoji(in: emoji) ?? SearchBarIcon.defaultEmoji }
}

/// One choice, drawn at the search bar's own icon size; the chosen one sits on a filled tile.
private struct SearchBarIconTile<Label: View>: View {
    let isSelected: Bool
    let help: LocalizedStringKey
    let action: () -> Void
    @ViewBuilder let label: Label

    private static var side: CGFloat { 36 }

    var body: some View {
        Button(action: action) {
            label
                .frame(width: Self.side, height: Self.side)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.barControl, style: .continuous)
                        .fill(isSelected ? Theme.Colors.selection : Color.clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
