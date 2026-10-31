import SwiftUI

/// tinycast-roseblud: `panelScrim` split so the compact glass keeps a rim near the expanded panel's.
@MainActor enum CompactBarScrim {
    struct Colors {
        let tint: Color
        let cover: Color
    }

    /// Measured against the expanded rim: more hides the glass's rim, less outshines the panel's.
    private nonisolated static let rimCover = 0.40

    private static var cached: (revision: Int, colors: Colors)?

    /// Rebuilt only on a theme change: a new `Color` in a tint restarts the glass and stalls the reveal.
    static var current: Colors {
        let revision = SpaceTheme.revision.value
        if let cached, cached.revision == revision { return cached.colors }
        let colors = Colors(tint: color { tintAlpha(for: $0) }, cover: color { coverAlpha(for: $0) })
        cached = (revision, colors)
        return colors
    }

    /// A washed button in Dark drops the scrim's mask, so it drops the tint too.
    static func buttonGlass(isWashed: Bool) -> Glass {
        Glass.regular.tint(isWashed ? nil : current.tint).interactive()
    }

    private static func color(alpha: @escaping @Sendable (Double) -> Double) -> Color {
        Color(
            nsColor: NSColor(name: nil) { appearance in
                let scrim = scrim(in: appearance)
                return scrim.withAlphaComponent(alpha(scrim.alphaComponent))
            })
    }

    /// `Theme.Colors.panelScrim`'s values, which a `Color` will not hand back per appearance.
    private nonisolated static func scrim(in appearance: NSAppearance) -> NSColor {
        SpaceTheme.ink(.background, in: appearance, dark: 0.40, light: 0.55)
            ?? (appearance.isDark ? .srgbInk(0, alpha: 0.40) : .srgbInk(1, alpha: 0.55))
    }

    private nonisolated static func coverAlpha(for alpha: Double) -> Double {
        min(alpha, rimCover)
    }

    /// What the cover leaves over: layered together, the two land on the scrim's own alpha.
    private nonisolated static func tintAlpha(for alpha: Double) -> Double {
        let cover = coverAlpha(for: alpha)
        return cover < 1 ? 1 - (1 - alpha) / (1 - cover) : 0
    }
}
