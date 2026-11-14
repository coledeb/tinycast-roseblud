import SwiftUI

private typealias BarMotion = Theme.CompactBarMotion

/// tinycast-roseblud: fades in with the compact bar's first glyph, once the capsule has settled.
struct CompactBarRevealFade: ViewModifier {
    let isActive: Bool
    @Environment(PaletteState.self) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRevealed = false

    func body(content: Content) -> some View {
        let shown = !isActive || isRevealed
        content
            // Only the way in fades; collapsing back from a query must hide it at once.
            .animation(reduceMotion || !isRevealed ? nil : fade) {
                $0.opacity(shown ? 1 : 0).blur(radius: shown ? 0 : BarMotion.glyphBlur)
            }
            .task(id: palette.isVisible && isActive) { await followBar() }
    }

    private var fade: Animation {
        .easeOut(duration: BarMotion.glyphFade).delay(BarMotion.revealDelay + BarMotion.glyphDelay)
    }

    /// Mirrors `CompactBar`, which remounts and replays its reveal whenever the window collapses.
    private func followBar() async {
        if palette.isVisible {
            withTransaction(\.disablesAnimations, !isActive) { isRevealed = isActive }
            return
        }
        try? await Task.sleep(for: .seconds(Motion.duration(BarMotion.parkAfterHide)))
        guard !Task.isCancelled else { return }
        withTransaction(\.disablesAnimations, true) { isRevealed = false }
    }
}
