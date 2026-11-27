import AppKit

/// tinycast-roseblud: the Run in Terminal fallback, which asks the chosen terminal over Apple
/// events to run the query in a new window.
@MainActor
enum TerminalLauncher {
    static func appURL(_ choice: TerminalChoice) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: choice.bundleID)
    }

    /// The fallback row, named and drawn after the chosen terminal; a missing one keeps the glyph.
    static func entry() -> AppEntry {
        let base = CommandCatalog.makeEntry(.runInTerminal)
        let choice = TerminalChoice.stored()
        let app = appURL(choice)
        var entry = AppEntry(
            id: base.id, name: choice.runTitle, url: app ?? base.url, bundleID: nil,
            kind: base.kind, settingsOwner: base.settingsOwner, subtitle: nil,
            alternateTitles: [base.name])
        entry.iconOverride = app.map { .file(stamp: FileIconStamp.value(for: $0)) }
        return entry
    }

    static func open(_ query: String, core: AppCore) {
        let command = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }
        core.paletteCoordinator.hidePalette(restoreFocus: false)
        let choice = TerminalChoice.stored()
        guard appURL(choice) != nil else {
            return core.showMessage(String(localized: "Couldn't open \(choice.name)"), tone: .danger)
        }
        let source = choice.appleScript(running: command, home: NSHomeDirectory())
        Task {
            guard let failure = await run(source, in: choice) else { return }
            core.showMessage(failure, tone: .danger)
        }
    }

    /// Nil when it ran. A cold terminal answers in seconds, so the send never blocks the main actor.
    private static func run(_ source: String, in choice: TerminalChoice) async -> String? {
        await Task.detached(priority: .userInitiated) {
            var errorInfo: NSDictionary?
            NSAppleScript(source: source)?.executeAndReturnError(&errorInfo)
            guard let errorInfo else { return nil }
            if errorInfo[NSAppleScript.errorNumber] as? Int == -1743 {
                return String(
                    localized: "Allow Tinycast to control \(choice.name) in Privacy & Security → Automation.")
            }
            return String(localized: "Couldn't open \(choice.name)")
        }.value
    }
}
