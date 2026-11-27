import SwiftUI

/// tinycast-roseblud: Settings → Fallbacks, the app the Run in Terminal fallback runs a query in.
struct TerminalFallbackSection: View {
    @AppStorage(TerminalChoice.key) private var choice = TerminalChoice.terminal

    /// Installed ones only, plus the stored choice so a removed app still shows what is set.
    private var options: [TerminalChoice] {
        TerminalChoice.allCases.filter { $0 == choice || TerminalLauncher.appURL($0) != nil }
    }

    var body: some View {
        Section {
            Picker(selection: $choice) {
                ForEach(options) { option in
                    Text(option.name).tag(option)
                }
            } label: {
                SettingsRowTitle(.fallbacksTerminal, "Terminal app")
            }
        } header: {
            SettingsSectionHeader(.fallbacksTerminal)
        } footer: {
            Text("Opens a new window and runs the query there, as if you typed it. The first run asks to let Tinycast control the app.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
