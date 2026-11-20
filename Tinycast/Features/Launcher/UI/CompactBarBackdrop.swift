import SwiftUI

private typealias BarMotion = Theme.CompactBarMotion

/// tinycast-roseblud: a Raycast theme's gradient over the compact glass, as the expanded panel has.
struct CompactBarBackdrop: View {
    let commands: [CommandID]
    let selection: CommandID?
    let geometry: CompactBarGeometry
    let revealed: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Rectangle()
            .fill(SpaceTheme.backdrop)
            // One mask over every shape, so where they overlap the gradient still paints only once.
            .mask { shapes }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var shapes: some View {
        ZStack(alignment: .topLeading) {
            Capsule(style: .continuous)
                .frame(width: geometry.capsuleWidth(revealed: revealed))
                .frame(maxHeight: .infinity)
                .animation(
                    reduceMotion ? nil : BarMotion.capsule.delay(BarMotion.revealDelay),
                    value: revealed)
            // A selected button keeps its own tint, which the gradient would otherwise wash out.
            ForEach(commands.indices.filter { commands[$0] != selection }, id: \.self) { index in
                Circle()
                    .frame(width: geometry.diameter, height: geometry.diameter)
                    .opacity(revealed ? 1 : 0)
                    .scaleEffect(revealed ? 1 : BarMotion.parkedScale)
                    .position(revealed ? geometry.center(of: index) : geometry.parked)
                    .animation(travel(index), value: revealed)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func travel(_ index: Int) -> Animation? {
        guard !reduceMotion else { return nil }
        return BarMotion.button.delay(BarMotion.revealDelay + BarMotion.stagger * Double(index))
    }
}
