import Foundation

@main
struct SearchBarIconTest {
    static func main() {
        func check<T: Equatable>(_ actual: T, _ expected: T, _ label: String) {
            guard actual == expected else {
                print("\(label): expected \(String(describing: expected)), got \(String(describing: actual))")
                exit(1)
            }
        }

        check(SearchBarIcon.emoji(in: "🚀"), "🚀", "a lone emoji is kept")
        check(SearchBarIcon.emoji(in: "😀🚀"), "🚀", "a new pick replaces the old one")
        check(SearchBarIcon.emoji(in: "🚀a"), "🚀", "letters typed after it are ignored")
        check(SearchBarIcon.emoji(in: "abc"), nil, "plain text is no emoji")
        check(SearchBarIcon.emoji(in: ""), nil, "nothing is no emoji")
        check(SearchBarIcon.emoji(in: "1"), nil, "a digit is no emoji")
        check(SearchBarIcon.emoji(in: "©"), nil, "a text-style symbol is no emoji")
        check(SearchBarIcon.emoji(in: "❤️"), "❤️", "a variation selector makes one")
        check(SearchBarIcon.emoji(in: "👍🏽"), "👍🏽", "a skin tone stays with its emoji")
        check(SearchBarIcon.emoji(in: "👩‍💻"), "👩‍💻", "a ZWJ sequence is one emoji")
        check(SearchBarIcon.emoji(in: "🇫🇷"), "🇫🇷", "a flag is one emoji")
        check(SearchBarIcon.emoji(in: "1️⃣"), "1️⃣", "a keycap is one emoji")
        check(SearchBarIcon.emoji(in: SearchBarIcon.defaultEmoji), SearchBarIcon.defaultEmoji, "the default is one")
        print("search bar icon tests passed")
    }
}
