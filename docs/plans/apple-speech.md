# Plan: Apple SpeechAnalyzer engine + live transcript bubble

Status: not started. Context and decisions: [FORK.md](../../FORK.md). Read
[docs/features/dictation.md](../features/dictation.md) (invariants) before touching dictation code.

## How dictation works today

- `Service/DictationCapture` records 16 kHz mono Float32 via `AVCaptureSession`; `snapshot()` /
  `stop()` return the samples so far. `onLevels` drives the waveform.
- `Service/DictationCoordinator` (~400 lines) owns the session: phases `idle/starting/listening/
  transcribing/stopping`, a `token` UUID that invalidates stale async work, push-to-talk vs toggle,
  `TextInjector` delivery, clipboard destinations.
- **Live insertion** (`settings.dictationLiveInsertion`): every 2 s, `flushLiveChunk` transcribes
  audio since `liveOffset` when it ends in a pause (see `Model/DictationAudioChunks`), strips echo,
  appends to `liveText` and pastes it. `accept()` transcribes the remaining tail.
- Inference runs in the sandboxed `DictationHelper` process (`Helper/`), driven by
  `Service/DictationWorker` over a length-prefixed JSON + raw-samples pipe (`DictationWire`). One
  request → one result; no streaming.
- `DictationModel` (`Model/`) lists Parakeet Ultra/Redux and Qwen 0.6B/1.7B with pinned Hugging Face
  repos; `DictationModelStore` downloads, deletes and routes `transcribe` to the worker.
- `UI/DictationPanel` is a fixed-size Liquid Glass capsule (`Theme.Size.dictationPanel`) showing a
  21-band waveform, then a processing wave. State: `DictationDisplayState { phase, levels }`.
- Deployment target is already macOS 26, so `SpeechAnalyzer` needs no availability gating.

## Work items

### 1. Engine choice + settings
- Add an engine/family preference covering Parakeet, Qwen and Apple (likely extend
  `DictationModel.Family` or add a sibling type; keep `DictationModel` for downloadable variants).
- New prefs need a `SettingsFileKey` + `SettingsFileSchema` binding, backup coverage
  (`Features/Backup/Model/SettingsBackupCoverage.swift`), search keywords
  (`SettingsSearchCatalog`), and localized strings in all eight languages (`./Scripts/sync-strings.sh`).
- Settings pane (`Settings/DictationSettingsView`): Apple row shows system asset status and an
  install button instead of download/size/delete.
- `hasModel` / `begin()` checks must treat Apple as "installed" when its locale assets are.

### 2. Apple recognizer service (in-app)
- New service (e.g. `Service/DictationSpeechAnalyzer.swift`): `SpeechTranscriber` for the chosen
  locale (map `DictationLanguage` → `Locale`; check `SpeechTranscriber.supportedLocales` /
  `installedLocales`), with volatile results and punctuation enabled.
- Assets: `AssetInventory.assetInstallationRequest(supporting:)` → `downloadAndInstall()`.
- Audio: tap `DictationCapture`'s sample buffers (add a callback alongside `onLevels`), convert to
  `SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith:)` with `AVAudioConverter`, yield
  `AnalyzerInput` into an `AsyncStream`. Conversion stays off-main (capture queue).
- Results: consume `transcriber.results`; keep `finalized` text and current `volatile` text.
- Finish: `finalizeAndFinishThroughEndOfInput()` on accept; cancel the analyzer on cancel.
- Verify whether sandboxed use needs `NSSpeechRecognitionUsageDescription` / authorization; add it
  to `Info.plist` (and the permissions UI) only if required.

### 3. Coordinator integration
- Branch the session on engine: Apple uses the streaming path; Parakeet/Qwen keep the chunk path
  unchanged. Preserve every invariant: token checks after each suspension, cancel/Escape inserts
  nothing, push-to-talk release, the 5-minute limit, ducking and cues.
- Live insertion with Apple: paste **finalized** results only (never volatile text), reusing the
  `liveText` / `stripEcho` / `DictationTextFormatter` flow. On accept, paste whatever finalized
  text has not been delivered.

### 4. Live transcript bubble
- New pref "Show live transcript" (default on? decide), independent of live insertion.
- `DictationDisplayState` gains `committedText` and `volatileText`; coordinator updates them.
  - Apple: committed = finalized, volatile = current volatile result → word-by-word.
  - Parakeet/Qwen: committed = text from existing ~2 s chunk passes; no volatile text and **no extra
    inference**. If live insertion is off, the chunk loop may run for display only, at the same cadence.
- Panel: grow from the capsule into a rounded rect (max ~2–3 lines, width capped), showing the tail
  of the text; volatile text dimmed. Keep the waveform. Resize around the same bottom anchor; follow
  `docs/ui.md` and `Theme` tokens (add sizes to `Theme`, not literals). Respect Reduce Motion.
  Panel remains nonactivating; Return/Escape still accept/cancel.

### 5. Tests + docs
- Harnesses live in `Tests/` (one Swift file each, no XCTest): `dictation-test.swift`,
  `dictation-worker-test.swift`, `dictation-field-test.swift`. Add coverage for display-state text
  assembly and engine selection/settings round-trip.
- Update `docs/features/dictation.md` (engines, bubble invariants) in the same commit.

## Definition of done (from AGENTS.md)
`./Scripts/run-tests.sh` passes · Debug build has no new warnings · `./Scripts/lint.sh` clean ·
no AppKit/SwiftUI imports under `Features/*/Model/` · docs updated · `xcodegen generate` if
`project.yml` changed.

## Suggested order
Bubble first (items 4 + its tests) using Parakeet/Qwen chunk text — small, visible, self-contained.
Then items 1–3 for Apple, which plugs volatile text into the same bubble.
