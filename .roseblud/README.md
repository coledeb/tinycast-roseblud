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
| `CHANGES.md` | What this fork adds, written for people installing it. `roseblud-release.yml` puts it at the top of every release's notes (above the install marker, so the in-app update window shows it). |
| `README.intro.md` | The top of the repository's `README.md`: `rebuild.sh` fills its `<!-- roseblud:changes -->` line with `CHANGES.md` and puts sermelipharo's README below it. |
| `notes.sh` | `notes.sh <tag>`: prints a release's notes, `CHANGES.md` above sermelipharo's notes (upstream's while theirs is blocked). |
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
| `patches/0101-search-bar-icon.patch` | Launcher: Settings → General → Appearance → *Search bar icon* picks the search bar's leading icon, the built-in magnifier or any emoji from a searchable picker, kept in plain `rosebludSearchBar…` defaults. The *Quick AI ⇥* hint shows in the compact bar too, since Tab asks Quick AI there as well, fading in once compact shortcuts have slid out (`CompactBarRevealFade`). See `docs/features/palette.md`. |
| `patches/0102-app-menu-rows.patch` | Launcher: the app menu (bottom-left button) shows all five rows, so *Quit Tinycast* is never half-hidden behind the search band (`Theme.Size.appMenuVisibleRows` 4.5 → 5). See `docs/features/palette.md`. |
| `patches/0103-compact-theme-gradient.patch` | Launcher: `CompactBarBackdrop` paints a Raycast theme's `SpaceTheme.backdrop` gradient over the compact bar's glass, masked to its capsule and buttons, since the theme's scrim no longer reaches it. Clear with no theme. See `docs/features/palette.md`. |
| `patches/0104-search-text-size.patch` | Launcher: Settings → General → Appearance → *Search text size* draws the search field's query and prompt at *Large* (upstream's 20pt, the default) or *Small* (17pt), scaled by Interface size, through `SearchTextSize` in a plain `rosebludSearchTextSize` default. The bar's height is unchanged. See `docs/features/palette.md`. |

## Automation

- **`roseblud-sync.yml`**: on every push to `main`, and on a 15-minute schedule that GitHub in practice runs
  hours apart, compares sermelipharo's `main` with `BASE`. On a change, or on a hand-made commit on top of the
  generated one, a Linux job dry-runs the patches; a conflict opens
  the `roseblud-sync` issue and stops. Otherwise an `xcode-27` runner rebuilds `main`, runs `.space/gate.sh`
  (Release build + `Scripts/run-tests.sh`, ignoring harnesses that also fail on the base) and
  force-pushes. On failure nothing is pushed.
- **`roseblud-release.yml`**: twice an hour, for each sermelipharo release tag not yet released here,
  applies the patches to that tag, builds, tests, signs with `Tinycast Cole Self-Signed` and publishes
  the same tag. The version is sermelipharo's, so a patch change reaches installed copies only with
  their next release (or a manual reinstall from a re-run release). When their release is blocked, run it
  by hand with `tag` and `base=main` to build on their `main` instead. `verify-signature.sh` runs as is: sermelipharo's
  `.space` patch 0031 drops upstream's Developer ID demand for self-signed builds. Such a release's
  notes fall back to upstream's and end in `<!-- roseblud:notes-from abue-ammar/tinycast -->`; once
  sermelipharo publishes the tag, the next run swaps in their notes if their tree matches `BASE` (outside
  `.space` and `.github`), or rebuilds on their tag if it does not.

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
