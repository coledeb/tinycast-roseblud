import SwiftUI

/// tinycast-roseblud: About's Stable / Beta picker, below Check for Updates. The main app owns the
/// choice: the pane sends it as a `SettingsAction` and reads it back from `MainAppStatus`.
struct UpdateTrackSection: View {
    @Environment(MainAppLink.self) private var mainApp
    /// Shown until the main app's status catches up, so the picker never flicks back.
    @State private var pending: UpdateTrack?

    var body: some View {
        let updates = mainApp.status.updates
        if updates.updatesItself {
            Section {
                Picker(selection: selection(updates.track)) {
                    Text("Stable").tag(UpdateTrack.stable)
                    Text("Beta").tag(UpdateTrack.beta)
                } label: {
                    SettingsRowTitle(.aboutAbout, "Update Channel")
                    Text(Self.detail(pending ?? updates.track))
                }
            }
            .onChange(of: updates.track) { _, track in
                if pending == track { pending = nil }
            }
        }
    }

    private func selection(_ current: UpdateTrack) -> Binding<UpdateTrack> {
        Binding(
            get: { pending ?? current },
            set: { track in
                pending = track
                mainApp.send(.setUpdateTrack(track))
            })
    }

    private static func detail(_ track: UpdateTrack) -> LocalizedStringKey {
        switch track {
        case .stable:
            "Releases only. Leaving Beta keeps the installed beta until a newer release ships."
        case .beta:
            "Betas built on upstream Tinycast's, and any newer release. Betas share your data and settings."
        }
    }
}
