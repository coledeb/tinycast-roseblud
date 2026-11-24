import Foundation

/// tinycast-roseblud: which releases a stable build takes, picked under About → Check for Updates.
/// Beta takes prereleases as well as releases, so a release that supersedes the last beta still
/// arrives as the newest version; Stable takes releases only. Saved by the main app in the plain
/// `rosebludUpdateChannel` default. See docs/features/updates.md.
enum UpdateTrack: String, CaseIterable, Identifiable, Codable, Sendable {
    case stable
    case beta

    static let defaultsKey = "rosebludUpdateChannel"

    /// Unset or unreadable is Stable, so nobody follows betas without choosing to.
    init(saved value: String?) {
        self = value.flatMap(Self.init(rawValue:)) ?? .stable
    }

    var id: String { rawValue }
}

extension ReleaseChannel {
    /// The channel a check filters by: a stable build following betas takes both streams.
    /// Upstream's beta app and local builds keep their own rules whatever the track says.
    func following(_ track: UpdateTrack) -> ReleaseChannel {
        self == .stable && track == .beta ? .stableAndBeta : self
    }
}
