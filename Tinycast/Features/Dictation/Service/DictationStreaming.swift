import Foundation

/// One dictation's streamed text, Apple's recognizer when it is the engine, and the bubble showing both.
@MainActor
final class DictationStreaming {
    static var usesAppleSpeech: Bool { DictationAppleSpeech.isSelected }

    private let bubble = DictationTranscriptBubble()
    private var transcript = DictationTranscript()
    private var apple: DictationAppleSpeech?

    var isApple: Bool { apple != nil }

    /// Without Apple's recognizer the capture keeps no tap, so a chunked session pays nothing for it.
    func begin(
        apple useApple: Bool, capture: DictationCapture,
        onResult: @escaping (_ text: String, _ isFinal: Bool) -> Void,
        onFailure: @escaping (any Error) -> Void
    ) {
        end()
        guard useApple else {
            capture.onSamples = nil
            return
        }
        let apple = DictationAppleSpeech()
        self.apple = apple
        capture.onSamples = apple.sampleTap
        apple.start(onResult: onResult, onFailure: onFailure)
    }

    func apply(_ text: String, isFinal: Bool) {
        transcript.apply(text, isFinal: isFinal)
        show()
    }

    func takeSettled() -> String { transcript.takeUndelivered() }

    func finish() async { await apple?.finish() }

    func closeBubble() { bubble.close() }

    func end() {
        apple?.cancel()
        apple = nil
        transcript = DictationTranscript()
        bubble.close()
    }

    private func show() {
        guard DictationAppleSpeech.showsLiveTranscript else { return }
        bubble.show(transcript)
    }
}
