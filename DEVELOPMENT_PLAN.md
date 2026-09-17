# Conversely — Development Plan

Engineering plan derived from `PRD.md` and `DESIGN.md`. Milestone numbers (M1–M5) match the PRD's suggested milestones; each is expanded here into concrete tasks.

---

## Architecture

- **UI:** SwiftUI, MVVM. Two screens behind a 2-tab bottom bar: **Converse** (default) and **Languages**.
- **Services layer:** on-device frameworks wrapped behind small protocols so they can be mocked in previews/tests:
  - `SpeechRecognitionService` → `SFSpeechRecognizer` (on-device mode only)
  - `TranslationService` → `Translation` framework (`LanguageAvailability`, `downloadLanguageModelIfNeeded`)
  - `SpeechSynthesisService` → `AVSpeechSynthesizer`
  - `AudioCaptureService` → `AVAudioEngine` feeding the recognizer
- **State:** in-memory only, session-scoped. No database, no persistence across launches (per PRD non-goals).
- **Folder layout:**
  ```
  Conversely/
    App/                  entry point, tab navigation, theme tokens
    Features/
      Conversation/        Screen 1 (view + view model + subviews)
      LanguageManagement/  Screen 2 (view + view model + subviews)
    Core/
      Models/              Language, ConversationTurn, LanguagePackStatus
      Services/            protocols + real implementations
    Resources/             Assets.xcassets, Info.plist
  ```

---

## Phase 0 — Project Scaffold (this session)

- [x] Xcode project generated via XcodeGen, iOS 18.0 deployment target (bumped from 17.4 in Phase 1 — see PRD.md correction), SwiftUI lifecycle
- [x] Folder structure above created
- [x] Design tokens from `DESIGN.md` ported into `AppTheme` (Color + typography extensions)
- [x] Static/mock UI for both screens, visually matching `Assets/*/screen.png`, wired to fake in-memory data
- [x] Info.plist permission strings for microphone + speech recognition
- [x] Git repo initialized

**Explicitly not done yet:** no real STT/Translation/TTS wiring. Mic buttons and download buttons currently drive canned mock state so the UI can be reviewed and iterated on before the pipeline work lands.

## Phase 1 (M1) — Core Pipeline Proof of Concept

- [x] `SpeechRecognitionService`: request authorization, verify `supportsOnDeviceRecognition`, stream partial/final results
- [x] `TranslationService`: check `LanguageAvailability.status`, translate string (via `TranslationSession`, vended through `.translationTask` — see PRD.md's deployment-target correction; there is no `downloadLanguageModelIfNeeded` API, a session handles download prompting itself)
- [x] `SpeechSynthesisService`: pick best offline `AVSpeechSynthesisVoice` per locale, speak text
- [x] `AudioCaptureService`: `AVAudioEngine` tap → buffer → recognizer input
- [x] Wired one hardcoded pair (en-US ⇄ vi-VN) end-to-end outside the UI via `PipelineTestRunner`/`PipelineTestHostView` (launch with `--pipeline-test`)

**Findings from running the harness in iOS Simulator (iPhone 17, iOS 26.5 runtime):**

- **The Simulator cannot validate non-English on-device Translation or STT at all.** A coverage sweep across Vietnamese, Spanish, French, German, and Japanese all came back `unsupported` for translation (`TranslationError.Cause.unsupportedLanguagePairing`) and `false` for `supportsOnDeviceRecognition`, each logging `No Assistant asset for language <locale>`. English (`en-US`) STT reports `true`. Confirmed below to be a Simulator-only limitation, not a real gap.
- TTS is confirmed working independent of the above: `SpeechSynthesisService` found and spoke through the `en-US` "Samantha" voice with no crash.
- Speech recognition and microphone authorization both show a one-time interactive system dialog on first run; `simctl privacy grant` covers microphone but has no equivalent for the Speech Recognition TCC service, so first run needs a manual tap (or real-device testing, where the user taps it once naturally).

**Findings from running the harness on a physical device (iPhone 13 Pro, iOS 26.6.2) — supersedes the Simulator caveats above:**

- Project wired for on-device deployment: `CODE_SIGN_STYLE: Automatic` + `DEVELOPMENT_TEAM` in `project.yml`, built/installed/launched via `xcodebuild -allowProvisioningUpdates` + `xcrun devicectl device install app` / `process launch`.
- **PRD §10's "validate Vietnamese specifically" risk is now resolved: confirmed working.** On-device, translation en→vi and vi→en both report `supported` (not `unsupported` as in Simulator), and `supportsOnDeviceRecognition` for `vi-VN` is `true`. The Simulator results were a platform limitation, not a real coverage gap.
- Spanish, French, German, and Japanese all report `supported` for translation on-device too, but `supportsOnDeviceRecognition` is `false` for all four (only English and Vietnamese are `true`) — this looks tied to which languages are enabled for on-device dictation/Siri on this particular device, not a hard framework limitation. **Phase 3's Language Management screen needs to surface this per-component gap clearly** (translation ready but STT not, per PRD §5.2's compound-status requirement) rather than assume "supported" for one component implies all three.
- First real translate call triggered the system's own "Translate — Required Downloads" sheet (English + Vietnamese model packs); that download took ~7 minutes, which is why the raw round-trip timer for that call reads 425.66s — that's download time, not translation latency.
- **Real translation latency, measured post-download: 0.20s (vi→en)** — comfortably inside the <3s target in PRD §9.
- TTS and both permission requests (speech recognition, microphone) resolved cleanly with a real one-time user tap.
- Still open: an actual spoken utterance through the live mic → on-device STT hasn't been exercised yet (the harness only covers Translation/TTS/support-checks); that's naturally covered once Phase 2 wires the real mic button flow into Screen 1.

## Phase 2 (M2) — Conversation Screen, Live Data

- [x] Replace mock `ConversationViewModel` state with the Phase 1 services
- [x] Mic button state machine: Idle → Listening → Processing → Result (+ auto-TTS) → Idle
- [x] Enforce only one side recording at a time
- [x] Chat bubble: original + translated text, replay button re-triggers TTS

**Confirmed working end-to-end on a physical device (iPhone 13 Pro):** live speech → on-device transcription → translation → auto-spoken result, for both directions of a real conversation, with fast (sub-second, per Phase 1's measured 0.20s) translation turnaround. `PipelineTestRunner`/`PipelineTestHostView` from Phase 1 stay in the repo as a standalone diagnostic (reachable only via `--pipeline-test`); the production Conversation screen no longer touches mock data at all. A couple of small polish nitpicks were noted during testing and deliberately deferred to Phase 5.

## Phase 3 (M3) — Language Management Screen, Live Data

- [x] Real per-language status (STT / Translation / TTS availability checks, not mock booleans)
- [x] Download action with real progress reporting (Translation only — see finding below)
- [x] Compound "usable" status: a language only counts as ready when all three legs are present

**API reality check — deviates from PRD §5.2/§6 requirement #7's assumed symmetry, found while implementing:**

Of the three components, only **Translation** can actually be downloaded (`TranslationSession.prepareTranslation()`, shows the system's own download sheet) or has a queryable pairwise status (`LanguageAvailability.status(from:to:)`, checked against English as a fixed pivot since availability is inherently pairwise, not a property of one language). **Speech recognition models and TTS voices are entirely system-managed** — there is no public API to download or delete either from a third-party app; the user manages both in iOS Settings (Dictation languages; Accessibility → Spoken Content → Voices). Consequences:
- Speech/Voice rows can only ever show `.downloaded` or `.unavailable` — never a downloadable `.notDownloaded` state, since there's nothing this app can trigger.
- **Removed the Delete button entirely.** None of the three components can be deleted from this app; a button that didn't actually delete anything would be worse than not having one. A persistent info banner (`openSystemSettings()`) points to Settings → Apps → Translate → Languages for deletion, and to Settings generally for Speech/Voice gaps — there's no public URL scheme to jump straight to another app's Settings page, only to this app's own.
- Storage-size figures shown are still placeholder estimates (PRD §10's "storage footprint" risk remains open) — no public API exposes a pack's real download size before fetching it.

**Bugs found and fixed while testing on-device:**
- Cold launch under-reported an already-installed language (e.g. Vietnamese) as not-downloaded until a manual pull-to-refresh. `LanguageAvailability.status(from:to:)` seems to need a moment to finish warming up right at launch. Fixed with an automatic self-healing recheck ~1.5s after the first pass, so a pull-to-refresh is no longer needed.
- Tapping Download, cancelling the sheet, then tapping Download again for the *same* language did nothing (no sheet). Root cause: `.translationTask` only restarts when its configuration value changes, and the stuck previous session (never resolved after a cancel) left `pendingDownloadConfiguration` unchanged. Fixed by routing through `nil` before every new download request, which reliably forces a retrigger.

**Known limitation, deferred to Phase 5 (low priority):** after that fix, requesting a *different* language re-shows the download sheet correctly, but re-requesting the exact same language a second time in the same app run still doesn't — this now looks like `TranslationSession`/`prepareTranslation()` itself suppressing a repeat prompt for a pair it's already asked about, independent of our retrigger fix. No public API is known to reset that. Narrow edge case (immediately retrying the identical language right after cancelling); not chasing further for now.

## Phase 4 (M4) — Error States & Validation

- [x] Language selector dropdowns now scope to fully-downloaded languages only — an unready language can't be selected at all, replacing the originally-planned "redirect to Language Management when a mic is tapped for an unready language." Prevention beats a reactive redirect: the invalid state (mic tapped for a language that isn't ready) can no longer occur in the first place.
- [x] Each side's dropdown excludes (greys out, doesn't hide) whichever language the *other* side currently has selected, so the same language can never be picked on both sides.
- [x] ~~Warning banners for languages with partial on-device support~~ — **dropped, and the per-component chips with it.** Once the Download button installs the speech asset *and* the translation pack, "partial support" is just "not downloaded yet", which the Download button already fixes; a banner would be warning about a problem the next tap solves. Rows are now binary — ready / downloading / tap to download — and the Speech·Translation·Voice chips are gone, since the user can't act on any one leg individually. The breakdown still exists in `LanguagePackStatus`, where it decides `isFullyReady` and therefore which languages the conversation screen offers. `hasGap` survives as the honest fallback for a leg no download can fix (nothing currently offered is in that state).
- [x] Confirmed correct behavior fully offline — a full en↔fr conversation turn (speech → translation → spoken reply) runs in airplane mode on device, through the iOS 26 `SpeechAnalyzer` path. This closes the PRD's core offline promise for a language installed entirely in-app.

### What download progress can and can't be reported

Three on-device measurements, each of which killed a plausible-looking fix:

- **`AssetInstallationRequest.progress` never moves.** Sampled every second for the length of a real install, it reports `completedUnitCount 0 of 1`, `isIndeterminate == false`, flipping to 1 only on completion. Re-reading the computed `progress` property each tick returns the same object (`sameObject=yes`), so this isn't a stale-handle bug — there is simply no fractional progress to show. The row shows an indeterminate bar; `speechStatus` reports a fraction only if one ever genuinely appears, so this self-corrects if Apple starts populating it.
- **An `AssetInstallationRequest` can't be cancelled.** `Progress.cancel()` plus Swift task cancellation at the 25s mark left `progress.isCancelled == true` while `downloadAndInstall()` ran on and completed at 132.8s, installing the asset. So no cancel button is offered while a speech asset is installing — `LanguagePackStatus.canCancel` is false in that state.
- **The Translation framework has no progress API at all.** Its entire surface is `prepareTranslation()`, `isReady`, and `cancel()`; the percentage lives in the system's own sheet. It also can't be relied on to report completion — `prepareTranslation()` stays suspended indefinitely if the user dismisses the sheet, even while the pack keeps downloading. So a poll (every 5s, capped at 10 minutes) is what promotes a row to Downloaded once the pack lands.

**Resulting design:** since nothing can report a fraction and the speech leg can't be stopped, the row carries a spinner and "Downloading…" while any leg is in flight, and flips to a tick in the Downloaded section once all three are ready. No progress bar, no percentage, no cancel button — each of those would have needed an API that doesn't exist, and `ComponentStatus.downloading` carries no associated value precisely because there's nothing truthful to put in it.

**Implementation note:** `ConversationViewModel` now depends on `LanguageManagementViewModel` (shared instance, injected via `RootTabView`) to read `downloadedPacks` as the source of truth for which languages are selectable — rather than duplicating the real availability-check logic that already lives there. Since they're separate `ObservableObject`s, `ConversationViewModel` forwards `languageManagementViewModel.objectWillChange` to its own so the dropdown list can't go stale (e.g. right after finishing a download on the Languages tab).

### The on-device STT availability problem, diagnosed

Symptom: Spanish's `supportsOnDeviceRecognition` was `false` for a long stretch, then spontaneously became `true`; French/German/Japanese stayed `false` no matter which Settings toggles were tried (keyboard, dictation languages, Siri language). Diagnosed on-device rather than guessed:

- **There are two independent speech asset families, and the app was only looking at the one it can't control.**
  - `SFSpeechRecognizer.supportsOnDeviceRecognition` is a read of the legacy **Assistant** (Siri/dictation) asset — the console prints `No Assistant asset for language xx-XX` when it's missing. No public API installs it; only the system does, in the background, after a Settings change. That's the whole explanation for Spanish: adding its keyboard queued the asset, and it landed silently some time later.
  - iOS 26's **`SpeechTranscriber` + `AssetInventory`** use a *separate* asset family which **is** installable on demand, with real progress (`AssetInstallationRequest.downloadAndInstall()`, `.progress`).
  - Proven distinct: after `downloadAndInstall()` put `fr_FR` into `SpeechTranscriber.installedLocales`, `supportsOnDeviceRecognition("fr-FR")` was *still* `false` and the `No Assistant asset` line still printed.
- **Coverage differs between the two engines**, so neither alone suffices. `SpeechTranscriber` supports 30 locales (de, en, es, fr, it, ja, ko, pt, yue, zh families) and notably **not Vietnamese** — the PRD's flagship language, which works only via the legacy recognizer. `SFSpeechRecognizer` covers more languages but offers no install path.
- **Resolution:** `SpeechRecognitionService` is now hybrid — `SpeechTranscriber`/`SpeechAnalyzer` when it supports the locale and the asset is installed, legacy `SFSpeechRecognizer` otherwise. `SpeechAssetService` wraps `AssetInventory`, and the Language Management Download button now installs the speech asset *and* the Translation pack, so adding a language is entirely in-app. Installed locales are `reserve`d (cap: `maximumReservedLocales`, 5) so the system doesn't reclaim them.
- **Russian has no on-device STT on either engine** (`legacySTT=false`, `SpeechTranscriber` unsupported) while Translation supports it — so it could only ever be a translation target, never a speaking side. Dropped from the offered languages for that reason; the `--language-scan` diagnostic still covers it, so it can be reinstated if Apple ships a `ru` transcriber model.

**Verified on device:** French installed entirely in-app (speech asset via `AssetInventory`, translation pack via the system sheet) and transcribes correctly through the `SpeechAnalyzer` path.

**Also fixed here:** `SFSpeechRecognizer.init`/`supportsOnDeviceRecognition` and `AVSpeechSynthesisVoice.speechVoices()` each block on synchronous work, and were being called from the `@MainActor` view model once per language per refresh — stalling the main thread and tripping the runtime's `unsafeForcedSync called from Swift Concurrent context` diagnostic. Both now hop onto a GCD queue, and the voice catalogue is enumerated once per refresh instead of once per language.

## Phase 5 (M5) — Polish & QA

- [ ] Recording/processing animations on the active mic button
- [ ] Empty-state copy ("Choose your two languages, then tap a mic to start talking.")
- [ ] QA pass across 3–4 language pairs
- [ ] (P1, stretch) UI display-language String Catalog + switcher on Screen 2
- [ ] Carried over from Phase 2: the two small conversation-screen nitpicks noted during device testing
- [ ] Carried over from Phase 3: re-requesting the *same* language immediately after cancelling its download doesn't re-show the system sheet (`prepareTranslation()` suppressing a repeat prompt; no public API to reset it). Lower priority now that the row keeps spinning and self-promotes, so a cancelled download is visibly recoverable by waiting rather than re-tapping.

---

## Out of scope for MVP (per PRD §3)

Auto speaker/language detection · more than 2 languages per session · conversation history persisted across launches · group conversations (3+) · text-input mode · accounts/sync/cloud backup · custom voice tuning UI · camera/photo translate.

## Risks to validate early (per PRD §10)

- On-device STT + offline TTS + Translation framework coverage for the target launch language list — validate Vietnamese specifically, since it's the PRD's worked example.
- Translation framework behavior when both legs of a pair need simultaneous model downloads.
- Per-language storage footprint, so the management screen can show realistic size estimates before download.
