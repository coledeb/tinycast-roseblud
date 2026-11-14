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
        guard let hosting, let capsule = capsuleFrame() else { return }
        hosting.layoutSubtreeIfNeeded()
        let size = hosting.fittingSize
        panel.setFrame(
            NSRect(
                x: capsule.midX - size.width / 2, y: capsule.maxY + Theme.Spacing.md,
                width: size.width, height: size.height),
            display: true)
        if !panel.isVisible { panel.orderFrontRegardless() }
    }

    /// The capsule's own frame, so the bubble stays on its display even if focus moves to another;
    /// failing that, where the capsule is placed: centred at a tenth of the main screen's height.
    private func capsuleFrame() -> NSRect? {
        let size = Theme.Size.dictationPanel
        if let window = NSApp.windows.first(where: { $0 !== panel && $0.isVisible && $0.frame.size == size }) {
            return window.frame
        }
        guard let frame = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame else { return nil }
        return NSRect(
            x: frame.midX - size.width / 2, y: frame.minY + frame.height * 0.1 - size.height / 2,
            width: size.width, height: size.height)
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
