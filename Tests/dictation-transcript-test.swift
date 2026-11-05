import Foundation

@main
struct DictationTranscriptTest {
    static func main() {
        func check<T: Equatable>(_ actual: T, _ expected: T, _ label: String) {
            guard actual == expected else {
                print("\(label): expected \(expected), got \(actual)")
                exit(1)
            }
        }

        var transcript = DictationTranscript()
        check(transcript.isEmpty, true, "starts empty")
        transcript.apply(" Hello", isFinal: false)
        check(transcript.volatile, "Hello", "a guess is trimmed")
        check(transcript.undelivered, "", "a guess is never deliverable")
        transcript.apply("Hello there", isFinal: false)
        check(transcript.volatile, "Hello there", "a newer guess replaces the last")
        transcript.apply("Hello there.", isFinal: true)
        check(transcript.finalized, "Hello there.", "a final result settles")
        check(transcript.volatile, "", "settling drops the guess")
        transcript.apply("How", isFinal: false)
        check(transcript.tail(limit: 100).text, "Hello there. How", "tail joins settled and guess")
        check(transcript.tail(limit: 100).settled, 12, "settled count stops at the guess")

        check(transcript.takeUndelivered(), "Hello there.", "settled text is taken once")
        check(transcript.takeUndelivered(), "", "taking again yields nothing")
        transcript.apply("How are you", isFinal: true)
        transcript.apply(", friend?", isFinal: true)
        check(transcript.finalized, "Hello there. How are you, friend?", "punctuation glues without a space")
        check(transcript.takeUndelivered(), "How are you, friend?", "only the new span is taken")

        var long = DictationTranscript()
        long.apply("one two three four five six", isFinal: true)
        long.apply("seven", isFinal: false)
        let tail = long.tail(limit: 12)
        check(tail.text, "six seven", "a tail starts at a whole word")
        check(tail.settled, 3, "the tail's settled count shifts with the cut")

        print("Dictation transcript passed")
    }
}
