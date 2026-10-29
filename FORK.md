# Fork notes (coledeb/tinycast-space)

This is a fork of [sermelipharo/tinycast-space](https://github.com/sermelipharo/tinycast-space), itself
a fork of Tinycast (see `README.upstream.md`). Everything in `AGENTS.md` and `docs/` still applies;
this file only records what is specific to this fork.

## Remotes

| Remote     | URL                                                  | Use                     |
| ---------- | ---------------------------------------------------- | ----------------------- |
| `origin`   | https://github.com/coledeb/tinycast-space.git        | push work here          |
| `upstream` | https://github.com/sermelipharo/tinycast-space.git   | pull upstream changes   |

## How this fork is built

`main` is generated, never merged: **sermelipharo's `main` + [`.cole/patches`](.cole/README.md)**,
one commit per patch, rebuilt and tested by `cole-sync.yml` whenever their `main` moves, and released
by `cole-release.yml` for each of their release tags. Their `main` is itself regenerated and
force-pushed, so never `git merge upstream/main`. Work lands as a patch in `.cole/patches`; how to
cut and check one is in [.cole/README.md](.cole/README.md#changing-a-patch).

**Keep patches small against their base.** New code in new files, one- or two-line hooks into
existing ones, per [.space/README.md](.space/README.md#changing-the-patch). Keep fork docs here and in
`docs/plans/` rather than rewriting upstream docs. A behaviour change still updates the affected
upstream doc (e.g. `docs/features/dictation.md`) inside its patch, per `AGENTS.md`'s definition of done.

## Current goal

Add Apple's on-device `SpeechAnalyzer` / `SpeechTranscriber` as a third dictation engine, and show a
live transcript in the dictation bubble. Plan: [docs/plans/apple-speech.md](docs/plans/apple-speech.md).

## Background research (2026-10-28)

Why consider Apple's engine at all, given Tinycast already ships Parakeet and Qwen3-ASR:

| Model                       | LibriSpeech clean | LibriSpeech other | Source                             |
| --------------------------- | ----------------- | ----------------- | ---------------------------------- |
| Apple SpeechAnalyzer        | 2.12%             | 4.56%             | Inscribe benchmark, Mac            |
| Parakeet Ultra              | 1.41%             | 2.98%             | moondream/parakeet-ultra card, GPU |
| Parakeet TDT 0.6B v3 (base) | 1.52%             | 3.13%             | same                               |
| Qwen3-ASR 1.7B              | ~1.3–1.6%         | ~3.4%             | Qwen3-ASR report / community MLX   |

- Apple is somewhat **less accurate** than Parakeet Ultra / Qwen 1.7B on benchmarks (~35–50% more
  errors), but beats every laptop-sized Whisper. Numbers come from different setups, and Tinycast runs
  INT8 / ternary Core ML conversions, so treat them as directional.
- Apple's wins: no model download (system-managed assets), low memory, Neural Engine efficiency,
  fast, and a **true streaming API with volatile (in-progress) and finalized results** — the reason
  word-by-word live text is only feasible with it.

## Decisions

- **Word-by-word live updates are Apple-only.** Parakeet/Qwen must not gain extra preview inference
  passes; in the bubble they show only the text their existing ~2 s chunk passes already produce.
- Apple's engine runs **in the app process**, not in `DictationHelper` (it is a system service and
  does not need the helper's isolation, and the helper's wire protocol is request/response only).
- Model it as an **engine choice** (Parakeet / Qwen / Apple), not as a fake downloadable
  `DictationModel` case — Apple has no repository, revision, or file list.
