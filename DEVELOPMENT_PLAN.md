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

- [ ] Redirect to Language Management (with the missing pack highlighted) when a mic is tapped for an unready language
- [ ] Warning banners for languages with partial on-device support
- [ ] Confirm correct behavior fully offline (airplane mode test)

## Phase 5 (M5) — Polish & QA

- [ ] Recording/processing animations on the active mic button
- [ ] Empty-state copy ("Choose your two languages, then tap a mic to start talking.")
- [ ] QA pass across 3–4 language pairs
- [ ] (P1, stretch) UI display-language String Catalog + switcher on Screen 2

---

## Out of scope for MVP (per PRD §3)

Auto speaker/language detection · more than 2 languages per session · conversation history persisted across launches · group conversations (3+) · text-input mode · accounts/sync/cloud backup · custom voice tuning UI · camera/photo translate.

## Risks to validate early (per PRD §10)

- On-device STT + offline TTS + Translation framework coverage for the target launch language list — validate Vietnamese specifically, since it's the PRD's worked example.
- Translation framework behavior when both legs of a pair need simultaneous model downloads.
- Per-language storage footprint, so the management screen can show realistic size estimates before download.
