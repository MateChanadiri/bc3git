import Foundation

/// Labels for the Apple Music-style shell that the generated `L10n` table (Android's strings.xml)
/// has no key for. English is the default value; add translations to Localizable.xcstrings.
enum AppleMusicText {
    static var new: String { String(localized: "New") }
    static var radio: String { String(localized: "Radio") }
    static var favorites: String { String(localized: "Favorites") }
    static var radioIntro: String { String(localized: "Start a station from a song you play") }
}
