import AVFoundation
import Speech

/// Apple's on-device recognizer for one dictation: captured samples in, volatile and final text out.
/// It runs in the app, not the helper: the analyzer is a system service with no model of ours to isolate.
@MainActor
final class DictationAppleSpeech {
    enum Failure: LocalizedError {
        case unsupportedLocale
        case notInstalled
        case audioFormat

        var errorDescription: String? {
            switch self {
            case .unsupportedLocale:
                String(localized: "Apple's speech recognition doesn't support your system language.")
            case .notInstalled: String(localized: "Install Apple's speech model in Dictation settings first.")
            case .audioFormat: String(localized: "Couldn't start Apple's speech recognition.")
            }
        }
    }

    static let engineKey = "rosebludDictationEngine"
    static let liveTranscriptKey = "rosebludDictationLiveTranscript"
    static var isSelected: Bool { UserDefaults.standard.string(forKey: engineKey) == "apple" }
    static var showsLiveTranscript: Bool {
        UserDefaults.standard.object(forKey: liveTranscriptKey) as? Bool ?? true
    }

    /// Called on the capture queue; the stream holds samples until the analyzer knows its format.
    nonisolated let sampleTap: @Sendable (UnsafeBufferPointer<Float>) -> Void
    private let samples: AsyncStream<[Float]>
    private let sampleSink: AsyncStream<[Float]>.Continuation
    private var task: Task<Void, Never>?
    private var analyzer: SpeechAnalyzer?

    init() {
        let (samples, sink) = AsyncStream.makeStream(of: [Float].self)
        self.samples = samples
        sampleSink = sink
        sampleTap = { sink.yield(Array($0)) }
    }

    static func locale() async -> Locale? {
        await SpeechTranscriber.supportedLocale(equivalentTo: .current)
    }

    static func isInstalled() async -> Bool {
        guard let locale = await locale() else { return false }
        let wanted = locale.identifier(.bcp47)
        return await SpeechTranscriber.installedLocales.contains { $0.identifier(.bcp47) == wanted }
    }

    static func install() async throws {
        guard let locale = await locale() else { throw Failure.unsupportedLocale }
        let module = SpeechTranscriber(locale: locale, preset: .transcription)
        try await AssetInventory.assetInstallationRequest(supporting: [module])?.downloadAndInstall()
    }

    /// `onResult` receives each result in order; a final one settles its span of audio.
    func start(
        onResult: @escaping (_ text: String, _ isFinal: Bool) -> Void,
        onFailure: @escaping (any Error) -> Void
    ) {
        let samples = samples
        task = Task { [weak self] in
            do {
                guard let locale = await Self.locale() else { throw Failure.unsupportedLocale }
                guard await Self.isInstalled() else { throw Failure.notInstalled }
                let transcriber = SpeechTranscriber(
                    locale: locale, transcriptionOptions: [],
                    reportingOptions: [.volatileResults, .fastResults], attributeOptions: [])
                guard
                    let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])
                else { throw Failure.audioFormat }
                let analyzer = SpeechAnalyzer(modules: [transcriber])
                guard let self, !Task.isCancelled else { return }
                self.analyzer = analyzer
                try await analyzer.prepareToAnalyze(in: format)
                let (inputs, inputSink) = AsyncStream.makeStream(of: AnalyzerInput.self)
                try await analyzer.start(inputSequence: inputs)
                async let fed: Void = Self.feed(samples, into: inputSink, format: format, analyzer: analyzer)
                for try await result in transcriber.results {
                    onResult(String(result.text.characters), result.isFinal)
                }
                try await fed
            } catch {
                guard !Task.isCancelled, !(error is CancellationError) else { return }
                onFailure(error)
            }
        }
    }

    /// Ends the input and waits for the analyzer to settle every result still pending.
    func finish() async {
        sampleSink.finish()
        await task?.value
    }

    func cancel() {
        sampleSink.finish()
        task?.cancel()
        task = nil
        guard let analyzer else { return }
        self.analyzer = nil
        Task { await analyzer.cancelAndFinishNow() }
    }

    @concurrent
    private static func feed(
        _ samples: AsyncStream<[Float]>, into sink: AsyncStream<AnalyzerInput>.Continuation,
        format: AVAudioFormat, analyzer: SpeechAnalyzer
    ) async throws {
        guard
            let source = AVAudioFormat(
                commonFormat: .pcmFormatFloat32, sampleRate: Double(DictationWire.sampleRate),
                channels: 1, interleaved: false)
        else { throw Failure.audioFormat }
        let converter = source == format ? nil : AVAudioConverter(from: source, to: format)
        for await chunk in samples {
            guard let buffer = pcmBuffer(chunk, format: source) else { continue }
            guard let converter else {
                sink.yield(AnalyzerInput(buffer: buffer))
                continue
            }
            if let converted = convert(buffer, with: converter) { sink.yield(AnalyzerInput(buffer: converted)) }
        }
        sink.finish()
        try await analyzer.finalizeAndFinishThroughEndOfInput()
    }

    private nonisolated static func pcmBuffer(_ samples: [Float], format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard !samples.isEmpty,
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
            let channel = buffer.floatChannelData?[0]
        else { return nil }
        samples.withUnsafeBufferPointer { channel.update(from: $0.baseAddress!, count: samples.count) }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        return buffer
    }

    private nonisolated static func convert(
        _ buffer: AVAudioPCMBuffer, with converter: AVAudioConverter
    ) -> AVAudioPCMBuffer? {
        let ratio = converter.outputFormat.sampleRate / converter.inputFormat.sampleRate
        let capacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up)) + 1
        guard let output = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: capacity)
        else { return nil }
        let input = OneShotInput(buffer)
        var error: NSError?
        let status = converter.convert(to: output, error: &error) { _, outStatus in input.next(outStatus) }
        guard status != .error, output.frameLength > 0 else { return nil }
        return output
    }
}

/// Hands the converter one buffer, then reports no data until the next call, so it keeps its state.
private final class OneShotInput: @unchecked Sendable {
    private var buffer: AVAudioPCMBuffer?

    init(_ buffer: AVAudioPCMBuffer) { self.buffer = buffer }

    func next(_ status: UnsafeMutablePointer<AVAudioConverterInputStatus>) -> AVAudioBuffer? {
        guard let buffer else {
            status.pointee = .noDataNow
            return nil
        }
        self.buffer = nil
        status.pointee = .haveData
        return buffer
    }
}
