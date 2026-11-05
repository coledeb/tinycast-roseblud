import AppKit
import SwiftUI

@MainActor
@Observable
private final class DictationBubbleState {
    var text = ""
    var settled = 0
}

private struct DictationBubbleView: View {
    let state: DictationBubbleState

    var body: some View {
        Text(attributed)
            .font(Theme.Typography.rowTitle)
            .lineLimit(DictationTranscriptBubble.maximumLines)
            .truncationMode(.head)
            .frame(width: DictationTranscriptBubble.textWidth, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.md)
            .glassEffect(.regular, in: .rect(cornerRadius: Theme.Radius.dialog))
            .accessibilityLabel("Dictation transcript")
            .accessibilityValue(state.text)
    }

    /// Settled words read as text; the recognizer's current guess stays dimmed until it settles.
    private var attributed: AttributedString {
        let split = state.text.index(state.text.startIndex, offsetBy: min(state.settled, state.text.count))
        var settled = AttributedString(state.text[..<split])
        settled.foregroundColor = Theme.Colors.textPrimary
        var guess = AttributedString(state.text[split...])
        guess.foregroundColor = Theme.Colors.textSecondary
        return settled + guess
    }
}

private final class DictationBubblePanel: NSPanel, AnimatedPanel {
    init(content: NSView) {
        super.init(
            contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered,
            defer: false)
        contentView = content
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        ignoresMouseEvents = true
        followMotion()
    }

    // The capsule keeps key focus: Return and Escape belong to it.
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// The live transcript above the dictation capsule: the last few lines, growing upward from it.
@MainActor
final class DictationTranscriptBubble {
    static let textWidth: CGFloat = 340
    static let maximumLines = 3
    static let tailCharacters = 180

    private let state = DictationBubbleState()
    private var panel: DictationBubblePanel?
    private var hosting: NSView?

    func show(_ transcript: DictationTranscript) {
        let tail = transcript.tail(limit: Self.tailCharacters)
        guard !tail.text.isEmpty else { return close() }
        state.text = tail.text
        state.settled = tail.settled
        let panel = panel ?? makePanel()
        guard let hosting, let frame = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame else { return }
        hosting.layoutSubtreeIfNeeded()
        let size = hosting.fittingSize
        // The capsule is centred at a tenth of the screen's height; the bubble sits just above it.
        let capsuleTop = frame.minY + frame.height * 0.1 + Theme.Size.dictationPanel.height / 2
        panel.setFrame(
            NSRect(
                x: frame.midX - size.width / 2, y: capsuleTop + Theme.Spacing.md,
                width: size.width, height: size.height),
            display: true)
        if !panel.isVisible { panel.orderFrontRegardless() }
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
        hosting = nil
    }

    private func makePanel() -> DictationBubblePanel {
        let hosting = NSHostingView(rootView: DictationBubbleView(state: state).motionScope())
        let panel = DictationBubblePanel(content: hosting)
        self.hosting = hosting
        self.panel = panel
        return panel
    }
}
