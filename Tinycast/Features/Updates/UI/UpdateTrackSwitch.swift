import Foundation

extension AppCore {
    /// tinycast-roseblud: About's channel picker, applied in the main app, which owns the updater.
    /// Saves the choice, lets the checker drop a cached offer the new track refuses, then checks at
    /// once, so the answer (an update, or "up to date") shows right after the switch.
    func setUpdateTrack(_ track: UpdateTrack) {
        UserDefaults.standard.set(track.rawValue, forKey: UpdateTrack.defaultsKey)
        guard updateChecker.track != track else { return }
        updateChecker.track = track
        updateCoordinator.checkForUpdates()
    }
}
