import SwiftUI

/// tinycast-roseblud: the launcher's leading icon, its mode symbol or the emoji chosen in Settings.
struct LauncherSearchIcon: View {
    let systemImage: String
    @AppStorage(SearchBarIcon.styleKey) private var style = SearchBarIcon.magnifier
    @AppStorage(SearchBarIcon.emojiKey) private var emoji = SearchBarIcon.defaultEmoji
    @Environment(\.metrics) private var metrics

    var body: some View {
        switch style {
        case .magnifier:
            Image(systemName: systemImage)
                .font(metrics.typography.headerIcon)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
        case .emoji:
            // A hand-edited default could hold anything, and the bar must never show text.
            Text(verbatim: SearchBarIcon.emoji(in: emoji) ?? SearchBarIcon.defaultEmoji)
                .font(metrics.typography.headerIcon)
                .accessibilityHidden(true)
        }
    }
}
