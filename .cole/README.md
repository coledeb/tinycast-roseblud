# .cole

Everything that makes this fork differ from [sermelipharo/tinycast-space](https://github.com/sermelipharo/tinycast-space),
which is itself upstream Tinycast + [`.space/patches`](../.space/README.md). `main` is never edited by
hand beyond this folder, `FORK.md` and `docs/plans/`: it is regenerated as *sermelipharo's main + these
patches*, one commit per patch (titled after it, its row below as the message), then one commit with
this folder and the rewrites.

| File | What it does |
| --- | --- |
| `rebuild.sh` | `rebuild.sh <base-sha> <subject>`: checks out the base, carries this fork's own files over, applies the patches in name order with `git apply --3way`, one commit each, then commits the rest. `COLE_CHECK=1` skips the derived files (Linux dry run); `COLE_REFRESH=1` re-cuts each patch from its commit so its context and blob ids match today's base. |
| `check.sh` | Dry-runs this checkout's patches on a throwaway worktree of sermelipharo's current `main` (or a given base), before a push. |
| `report.sh` | Opens / closes the `cole-sync` or `cole-release` issue. |
| `BASE` | The sermelipharo commit `main` was last built from. |

Rewrites in `rebuild.sh` (not patches, because they edit sermelipharo's own lines): every
`sermelipharo/tinycast-space` in the Swift sources becomes `coledeb/tinycast-space`, so the updater,
About and Changelog read this fork's releases; `AGENTS.md` gets its pointer to `FORK.md`.

## Patches

Numbered from `0100` so they never read as sermelipharo's.

| File | What it does |
| --- | --- |

## Automation

- **`cole-sync.yml`**: every 15 minutes, compares sermelipharo's `main` with `BASE`. On a change, or on
  a hand-made commit on top of the generated one, a Linux job dry-runs the patches; a conflict opens
  the `cole-sync` issue and stops. Otherwise an `xcode-27` runner rebuilds `main`, runs `.space/gate.sh`
  (Release build + `Scripts/run-tests.sh`, ignoring harnesses that also fail on the base) and
  force-pushes. On failure nothing is pushed.
- **`cole-release.yml`**: twice an hour, for each sermelipharo release tag not yet released here,
  applies the patches to that tag, builds, tests, signs with `Tinycast Cole Self-Signed` and publishes
  the same tag. The version is sermelipharo's, so a patch change reaches installed copies only with
  their next release (or a manual reinstall from a re-run release).

sermelipharo's `space-*.yml` and upstream's workflows come back with every sync, so they stay
**disabled in this repository's Actions settings**: `space-sync` would rebuild `main` from upstream and
drop this layer.

Secrets: `COLE_PUSH_TOKEN` (fine-grained token for this repository: Contents + Workflows read/write),
`SIGNING_P12_BASE64` and `SIGNING_P12_PASSWORD` (the `Tinycast Cole Self-Signed` identity; never
rotate it casually, since installed copies only accept updates signed with the same certificate).

## Changing a patch

1. Start from the current `main`; each patch is a commit there.
2. Change the code on top (for a new patch, on top of `main`), commit, and cut the file:
   `git diff --full-index <from> <to> -- . ':!Tinycast.xcodeproj' ':!Tinycast/Resources/RaycastRuntime.generated.js' ':!.cole' > .cole/patches/01NN-name.patch`
3. Add or update its row above, run `.cole/check.sh` (a dry run on a throwaway worktree of
   sermelipharo's current `main`), then commit and push. The next sync rebuilds `main` with it.

Shape patches the way [`.space/README.md`](../.space/README.md#changing-the-patch) explains: new code in
new files, hunks in upstream files kept to a hook of a line or two, `extension`s after a type for
`private` members, no long SwiftUI modifier chains, no wall-clock timing in tests.
