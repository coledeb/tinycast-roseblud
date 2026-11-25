import SwiftUI

/// tinycast-roseblud: Settings → General → Appearance, the launcher's search text size.
/// Two glyph steps, drawn like `InterfaceSizeRow`'s so the rows read as a pair.
struct SearchTextSizeRow: View {
    /// Its own state, written through to the default: an `@AppStorage` write here changed the
    /// launcher but never redrew this row's highlight.
    @State private var size = SearchTextSize.stored

    private static let glyph: [SearchTextSize: CGFloat] = [.small: 11, .large: 14]

    var body: some View {
        SettingsRow(
            title: "Search text size",
            subtitle: String(localized: "The text you type in the search bar, and its prompt."),
            anchor: .generalAppearance
        ) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(SearchTextSize.allCases) { option in
                    segment(option)
                }
            }
        }
    }

    private func segment(_ option: SearchTextSize) -> some View {
        let selected = size == option
        return Button {
            size = option
            UserDefaults.standard.set(option.rawValue, forKey: SearchTextSize.key)
        } label: {
            Text(verbatim: "Aa")
                .font(.system(size: Self.glyph[option] ?? 13, weight: .medium))
                .foregroundStyle(selected ? Color.primary : Color.secondary)
                .settingsOptionSegment(isSelected: selected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.title)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .help(option.title)
    }
}
