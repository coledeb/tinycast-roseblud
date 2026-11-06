import AppKit
import SwiftUI

/// tinycast-roseblud: how large the launcher's query and prompt are drawn; an unset key reads as `.large`.
enum SearchTextSize: String, CaseIterable, Identifiable, Sendable {
    case small
    case large

    static let key = "rosebludSearchTextSize"

    static var stored: SearchTextSize {
        UserDefaults.standard.string(forKey: key).flatMap(SearchTextSize.init) ?? .large
    }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small: String(localized: "Small")
        case .large: String(localized: "Large")
        }
    }

    /// `.large` is upstream's own size, so the default changes nothing.
    private var basePoints: CGFloat {
        switch self {
        case .small: 17
        case .large: Theme.Typography.searchFieldSize
        }
    }

    /// Follows Interface size the way `InterfaceMetrics.Typography.searchFieldSize` does.
    func points(_ metrics: InterfaceMetrics) -> CGFloat { metrics.scaled(basePoints) }

    func font(_ metrics: InterfaceMetrics) -> Font {
        self == .large ? metrics.typography.searchField : .system(size: points(metrics), weight: .regular)
    }

    @MainActor func nsFont(_ metrics: InterfaceMetrics) -> NSFont {
        self == .large
            ? metrics.typography.searchFieldNSFont
            : NSFont.systemFont(ofSize: points(metrics), weight: .regular)
    }
}
