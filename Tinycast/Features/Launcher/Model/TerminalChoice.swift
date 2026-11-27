import Foundation

/// tinycast-roseblud: the app the Run in Terminal fallback hands its query to, each one a terminal
/// whose AppleScript can open a window and type into its shell.
enum TerminalChoice: String, CaseIterable, Identifiable, Sendable {
    case terminal = "com.apple.Terminal"
    case ghostty = "com.mitchellh.ghostty"
    case iTerm = "com.googlecode.iterm2"

    static let key = "rosebludFallbackTerminal"

    /// An unset or unknown id reads as Terminal, which every Mac has.
    static func stored(in defaults: UserDefaults = .standard) -> TerminalChoice {
        defaults.string(forKey: key).flatMap(TerminalChoice.init) ?? .terminal
    }

    var id: String { rawValue }
    var bundleID: String { rawValue }

    var name: String {
        switch self {
        case .terminal: "Terminal"
        case .ghostty: "Ghostty"
        case .iTerm: "iTerm"
        }
    }

    var runTitle: String { String(localized: "Run in \(name)") }

    /// Opens a new window and types the query into its shell, as if typed there: the user's own
    /// shell, aliases and history. Terminal and iTerm reuse the window a cold launch opens.
    func appleScript(running command: String, home: String) -> String {
        let text = Self.literal(command)
        let header = """
            set wasRunning to application id "\(bundleID)" is running
            tell application id "\(bundleID)"
                activate
            """
        let body =
            switch self {
            case .terminal:
                """
                    if wasRunning then
                        do script \(text)
                    else
                        do script \(text) in front window
                    end if
                """
            case .ghostty:
                """
                    set config to new surface configuration
                    set initial working directory of config to \(Self.literal(home))
                    set initial input of config to \(text) & linefeed
                    new window with configuration config
                """
            case .iTerm:
                """
                    if wasRunning then create window with default profile
                    tell current session of current window to write text \(text)
                """
            }
        return header + "\n" + body + "\nend tell"
    }

    /// An AppleScript string literal; nothing in the query can end it early.
    private static func literal(_ text: String) -> String {
        let escaped = text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"" + escaped + "\""
    }
}
