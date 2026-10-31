import SwiftUI

/// Chooses Apple's on-device recognizer over the downloaded models, and the live transcript bubble.
struct DictationAppleSpeechSection: View {
    private enum AssetState { case checking, unsupported, missing, installing, installed }

    @AppStorage(DictationAppleSpeech.engineKey) private var engine = ""
    @AppStorage(DictationAppleSpeech.liveTranscriptKey) private var showsLiveTranscript = true
    @State private var assets = AssetState.checking
    @State private var locale: Locale?
    @State private var installError: String?

    var body: some View {
        Section {
            Picker(selection: $engine) {
                Text("Downloaded model").tag("")
                Text("Apple SpeechAnalyzer").tag("apple")
            } label: {
                SettingsRowTitle(.dictationModel, "Recognizer")
                Text(
                    engine == "apple"
                        ? "Built into macOS: nothing to download, words appear as you speak."
                        : "Parakeet or Qwen, chosen below.")
            }
            if engine == "apple" {
                LabeledContent {
                    switch assets {
                    case .checking, .installing: ProgressView().controlSize(.small)
                    case .missing: Button("Install") { install() }
                    case .unsupported, .installed: EmptyView()
                    }
                } label: {
                    Text(assetTitle)
                    if let detail = installError ?? locale.map(localeDescription) { Text(detail) }
                }
                Toggle(isOn: $showsLiveTranscript) {
                    SettingsRowTitle(.dictationModel, "Show live transcript")
                    Text("Words appear above the microphone as you speak.")
                }
            }
        } header: {
            Text("Recognizer")
        }
        .task(id: engine) { await refresh() }
    }

    private var assetTitle: String {
        switch assets {
        case .checking: String(localized: "Checking Apple's speech model…")
        case .unsupported: String(localized: "Your system language isn't supported")
        case .missing: String(localized: "Not installed")
        case .installing: String(localized: "Installing…")
        case .installed: String(localized: "Installed")
        }
    }

    private func localeDescription(_ locale: Locale) -> String {
        Locale.current.localizedString(forIdentifier: locale.identifier) ?? locale.identifier
    }

    private func refresh() async {
        guard engine == "apple" else { return }
        locale = await DictationAppleSpeech.locale()
        guard locale != nil else {
            assets = .unsupported
            return
        }
        assets = await DictationAppleSpeech.isInstalled() ? .installed : .missing
    }

    private func install() {
        assets = .installing
        installError = nil
        Task {
            do {
                try await DictationAppleSpeech.install()
            } catch {
                installError = error.localizedDescription
            }
            await refresh()
        }
    }
}
