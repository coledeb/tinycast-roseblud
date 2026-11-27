# .roseblud

Everything that makes this fork differ from [sermelipharo/tinycast-space](https://github.com/sermelipharo/tinycast-space),
which is itself upstream Tinycast + [`.space/patches`](../.space/README.md). `main` is never edited by
hand beyond this folder and `docs/plans/`: it is regenerated as *sermelipharo's main + these
patches*, one commit per patch (titled after it, its row below as the message), then one commit with
this folder and the rewrites.

| File | What it does |
| --- | --- |
| `rebuild.sh` | `rebuild.sh <base-sha> <subject>`: checks out the base, carries this fork's own files over, applies the patches in name order with `git apply --3way`, one commit each, then commits the rest. `ROSEBLUD_CHECK=1` skips the derived files (Linux dry run); `ROSEBLUD_REFRESH=1` re-cuts each patch from its commit so its context and blob ids match today's base. |
| `check.sh` | Dry-runs this checkout's patches on a throwaway worktree of sermelipharo's current `main` (or a given base), before a push. |
| `CHANGES.md` | What this fork adds, written for people installing it: the whole list, one `- **Title.**` entry per feature, not a per-release log. `notes.sh` works out what is new in each release from it. |
| `README.intro.md` | The top of the repository's `README.md`: `rebuild.sh` fills its `<!-- roseblud:changes -->` line with `CHANGES.md` and puts sermelipharo's README below it. |
| `notes.sh` | `notes.sh <tag>`: prints a release's notes: the `CHANGES.md` entries added or reworded since this fork's previous release (the highest released tag below `<tag>`, compared with that tag's `CHANGES.md`), the whole list folded in a `<details>` below them, then sermelipharo's notes (upstream's while theirs is blocked). With no earlier `CHANGES.md` to compare, the whole list is shown open. |
| `beta-notes.sh` | `beta-notes.sh <tag> <commit>`: prints a beta's notes in upstream's beta layout: a line on what it is built from, upstream's *What's Changed* for the same tag, then an install block (channel, version, bundle id, commit, how to switch to Beta). Bare `#123` points at upstream's PR, as in `notes.sh`. |
| `gate.sh` | `gate.sh <base-sha>`: Release build + `Scripts/run-tests.sh`, run by both workflows instead of sermelipharo's `.space/gate.sh`. It blocks when the runner exits without a verdict, and waives a harness that keeps failing only when the same harness also fails on `<base>` (run there with this fork's `Scripts/run-tests.sh`, so both sides get the same runner fixes); one `<base>` lacks (this fork's own) always blocks. |
| `report.sh` | Opens / closes the `roseblud-sync` or `roseblud-release` issue. |
| `scrub.sh` | Run by `rebuild.sh` (not under `ROSEBLUD_CHECK`): rewrites `#123`, `owner/repo#123`, `GH-123` and issue / PR URLs to plain "issue 123" in every commit message not on upstream's `main`, then fails if any are left. GitHub posts "referenced this issue" on the cited issue for every new commit SHA pushed, and each rebuild re-pushes sermelipharo's commits under new SHAs, so without it every sync and release posts on abue-ammar/tinycast's issues. `scrub.sh --check` only checks. |
| `BASE` | The sermelipharo commit `main` was last built from. |

Rewrites in `rebuild.sh` (not patches, because they edit sermelipharo's own lines): every
`sermelipharo/tinycast-space` in the Swift sources becomes `coledeb/tinycast-roseblud`, so the updater,
About and Changelog read this fork's releases; `README.md` gets `README.intro.md` on top and its Releases and Issues links pointed here; About's "✨ Space Edition" chip says "🌹 Roseblud Edition" and its GitHub label "Roseblud Edition"; the launcher's search prompt uses `textSecondary` instead of `textTertiary` (brighter and crisper, as in Raycast; same size), and the rebuild fails if that line moves.

## Patches

Numbered from `0100` so they never read as sermelipharo's.

| File | What it does |
| --- | --- |
| `patches/0100-apple-speech.patch` | Dictation: Apple's on-device `SpeechTranscriber` as a third recognizer (Settings → Dictation → Recognizer), fed from a sample tap on `DictationCapture`, running in the app; live insertion pastes only finalized results. A live transcript bubble above the capsule shows settled and dimmed in-progress words, with Apple only. See `docs/features/dictation.md`. |
| `patches/0101-search-bar-icon.patch` | Launcher: Settings → General → Appearance → *Search bar icon* picks the search bar's leading icon, the built-in magnifier or any emoji from a searchable picker, kept in plain `rosebludSearchBar…` defaults. See `docs/features/palette.md`. |
| `patches/0102-app-menu-rows.patch` | Launcher: the app menu (bottom-left button) grows to fit all its rows and separators, so *Quit Tinycast* is never hidden below the fold (one `visibleRows:` line in `RootPaletteView`). See `docs/features/palette.md`. |
| `patches/0103-compact-theme-gradient.patch` | Launcher: `CompactBarBackdrop` paints a Raycast theme's `SpaceTheme.backdrop` gradient over the compact bar's glass and `panelScrim`, masked to its capsule and buttons, so it stacks as the expanded panel does. Clear with no theme. See `docs/features/palette.md`. |
| `patches/0104-search-text-size.patch` | Launcher: Settings → General → Appearance → *Search text size* draws the search field's query and prompt at *Large* (upstream's 20pt, the default) or *Small* (17pt), scaled by Interface size, through `SearchTextSize` in a plain `rosebludSearchTextSize` default. The bar's height is unchanged. See `docs/features/palette.md`. |
| `patches/0105-compact-quick-ai-hint.patch` | Launcher: the *Quick AI ⇥* hint shows in the compact bar too, since Tab asks Quick AI there as well, fading in once compact shortcuts have slid out (`CompactBarRevealFade`). See `docs/features/palette.md`. |
| `patches/0106-runner-crash-line.patch` | Tests: `Scripts/run-tests.sh` keeps only the last line of a harness's time file, so a crash's `Trace/BPT trap` message can't split its FAIL line in two; the extra line made `report()` count one result too many and end the run as "harness dispatch failed", with no verdict for `gate.sh` to retry or waive. |
| `patches/0107-theme-expand-flash.patch` | Launcher: under a Raycast theme, the expanded panel's gradient (`SpaceThemeBackdrop`) appears at once as the window snaps open on the first keystroke, rather than fading in over 0.3 s and showing bare grey glass first; collapsing still fades it out. |
| `patches/0108-release-update-channel.patch` | Updates: recognize the fork’s shipped `com.tinycast.app` bundle as stable, while keeping development and unknown ids out of the updater; retain bundle and signature verification. See `docs/features/updates.md`. |
| `patches/0109-run-in-terminal.patch` | Launcher: a *Run in Terminal* fallback runs the query in a new window of the terminal picked in Settings → Fallbacks (Terminal, Ghostty or iTerm, via `TerminalChoice`), named and drawn after it (*Run in Ghostty*, with its icon), by typing it into a new window over AppleScript (`TerminalLauncher`). See `docs/features/launcher.md`. |
| `patches/0111-update-channel.patch` | Updates: Settings → About → *Update Channel* (`UpdateTrackSection`, below Check for Updates) picks Stable or Beta, saved by the main app as `UpdateTrack` in a plain `rosebludUpdateChannel` default (the pane sends `SettingsAction.setUpdateTrack` and reads `MainAppStatus.Updates.track`, as PR 1966's process rules ask). Beta widens `.stable` to `.stableAndBeta` (`ReleaseChannel.following`), which takes prereleases and releases alike, so the newest version wins and a release that supersedes the installed beta is offered; leaving Beta never downgrades, and drops a cached beta offer at once. The feed is read 100 releases deep. See `docs/features/updates.md`. |

## Automation

- **`roseblud-sync.yml`**: on every push to `main`, and on a 15-minute schedule that GitHub in practice runs
  hours apart, compares sermelipharo's `main` with `BASE`. On a change, or on a hand-made commit on top of the
  generated one, a Linux job dry-runs the patches; a conflict opens
  the `roseblud-sync` issue and stops. Otherwise an `xcode-27` runner rebuilds `main`, runs `.roseblud/gate.sh`
  (see `gate.sh` above) and
  force-pushes. On failure nothing is pushed.
- **`roseblud-release.yml`**: twice an hour, for each sermelipharo release tag not yet released here,
  applies the patches to that tag, builds, tests, signs with `Tinycast Cole Self-Signed` and publishes
  the same tag, moving it only from the commit it saw (`--force-with-lease`). A re-release replaces the
  existing release's assets, title and notes in place and never deletes it, so a failed upload leaves
  the previous assets up. The version is sermelipharo's, so a patch change reaches installed copies only with
  their next release (or a manual reinstall from a re-run release). When their release is blocked, run it
  by hand with `tag` and `base=main` to build on their `main` instead. `verify-signature.sh` runs as is: sermelipharo's
  `.space` patch 0031 drops upstream's Developer ID demand for self-signed builds. Such a release's
  notes fall back to upstream's and end in `<!-- roseblud:notes-from abue-ammar/tinycast -->`; once
  sermelipharo publishes the tag, the next run swaps in their notes if their tree matches `BASE` (outside
  `.space` and `.github`), or rebuilds on their tag if it does not.
- **`roseblud-beta.yml`**: twice an hour, takes upstream's newest beta (`vX.Y.Z-beta.N`, a prerelease on
  abue-ammar/tinycast; sermelipharo publishes none) and releases it here as the same tag. It skips a beta
  already released here, one superseded by upstream's newest release, and waits while `main` is not a
  generated build or its `.space/UPSTREAM` does not yet contain the beta (GitHub's compare API). It then
  builds that exact `main` commit, already tested by the sync's `gate.sh`, as upstream versions betas
  (`MARKETING_VERSION` the tag, build number its beta counter), signs it, and publishes
  `Tinycast-<version>.dmg` and `.zip` as **Tinycast Beta `<version>` · Roseblud Edition**, a prerelease and never
  Latest, as upstream does. Unlike upstream's separate *Tinycast Beta* app, the bundle id and name stay
  `com.tinycast.app` / *Tinycast*: patch 0111's *Update Channel* picker lets one app follow either stream.
  The tag moves only from the commit it saw, a re-release edits the prerelease in place, and a failure
  opens the `roseblud-beta` issue. Run it by hand with `tag` to re-release one.

**Nothing here posts upstream.** Every workflow writes only to this repository, and reads upstream
through read-only API calls and fetches. Commit messages lose their issue references in `scrub.sh`, so no
pushed commit lands on an upstream issue's timeline. A beta's tag points at a commit `main` already
carries; a release's at commits `rebuild.sh` scrubbed. Release notes keep upstream's credits and links.

sermelipharo's `space-*.yml` and upstream's workflows come back with every sync, so they stay
**disabled in this repository's Actions settings**: `space-sync` would rebuild `main` from upstream and
drop this layer.

Secrets: `ROSEBLUD_PUSH_TOKEN` (fine-grained token for this repository: Contents + Workflows read/write),
`SIGNING_P12_BASE64` and `SIGNING_P12_PASSWORD` (the `Tinycast Cole Self-Signed` identity; never
rotate it casually, since installed copies only accept updates signed with the same certificate).

## Changing a patch

1. Start from the current `main`; each patch is a commit there.
2. Change the code on top (for a new patch, on top of `main`), commit, and cut the file:
   `git diff --full-index <from> <to> -- . ':!Tinycast.xcodeproj' ':!Tinycast/Resources/RaycastRuntime.generated.js' ':!.roseblud' > .roseblud/patches/01NN-name.patch`
3. Add or update its row above and its user-facing line in `CHANGES.md`, run `.roseblud/check.sh` (a dry run on a throwaway worktree of
   sermelipharo's current `main`), then commit and push. The push starts the sync, which rebuilds `main` with it.

Shape patches the way [`.space/README.md`](../.space/README.md#changing-the-patch) explains: new code in
new files, hunks in upstream files kept to a hook of a line or two, `extension`s after a type for
`private` members, no long SwiftUI modifier chains, no wall-clock timing in tests.
