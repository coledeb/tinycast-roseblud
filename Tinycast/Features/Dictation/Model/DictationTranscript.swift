import Foundation

/// The text of one dictation as it streams in: settled text, the recognizer's current guess, and how
/// much of the settled text has already been delivered.
struct DictationTranscript: Equatable, Sendable {
    private(set) var finalized = ""
    private(set) var volatile = ""
    private var delivered = 0

    var isEmpty: Bool { finalized.isEmpty && volatile.isEmpty }

    /// Settled text not yet taken, without surrounding whitespace.
    var undelivered: String {
        String(finalized.dropFirst(delivered)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// A final result settles its span and drops the guess it replaces; a volatile one replaces the guess.
    mutating func apply(_ text: String, isFinal: Bool) {
        let piece = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isFinal else {
            volatile = piece
            return
        }
        volatile = ""
        finalized = Self.joined(finalized, piece)
    }

    mutating func takeUndelivered() -> String {
        let text = undelivered
        delivered = finalized.count
        return text
    }

    /// The last `limit` characters of settled and guessed text, cut at a word so the bubble never
    /// opens mid-word. `settled` counts how many of them are settled.
    func tail(limit: Int) -> (text: String, settled: Int) {
        let whole = Self.joined(finalized, volatile)
        let settled = min(finalized.count, whole.count)
        guard whole.count > limit else { return (whole, settled) }
        var start = whole.index(whole.endIndex, offsetBy: -limit)
        if let space = whole[start...].firstIndex(where: \.isWhitespace) {
            start = whole.index(after: space)
        }
        let dropped = whole.distance(from: whole.startIndex, to: start)
        return (String(whole[start...]), max(0, settled - dropped))
    }

    private static func joined(_ head: String, _ next: String) -> String {
        guard !head.isEmpty, !next.isEmpty else { return head + next }
        let glued = head.last?.isWhitespace == true || next.first.map { ".,!?;:)]}".contains($0) } == true
        return glued ? head + next : head + " " + next
    }
}
