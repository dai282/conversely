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

- [x] Xcode project generated via XcodeGen, iOS 17.4 deployment target, SwiftUI lifecycle
- [x] Folder structure above created
- [x] Design tokens from `DESIGN.md` ported into `AppTheme` (Color + typography extensions)
- [x] Static/mock UI for both screens, visually matching `Assets/*/screen.png`, wired to fake in-memory data
- [x] Info.plist permission strings for microphone + speech recognition
- [x] Git repo initialized

**Explicitly not done yet:** no real STT/Translation/TTS wiring. Mic buttons and download buttons currently drive canned mock state so the UI can be reviewed and iterated on before the pipeline work lands.

## Phase 1 (M1) — Core Pipeline Proof of Concept

- [ ] `SpeechRecognitionService`: request authorization, verify `supportsOnDeviceRecognition`, stream partial/final results
- [ ] `TranslationService`: check `LanguageAvailability.status`, trigger `downloadLanguageModelIfNeeded`, translate string
- [ ] `SpeechSynthesisService`: pick best offline `AVSpeechSynthesisVoice` per locale, speak text
- [ ] `AudioCaptureService`: `AVAudioEngine` tap → buffer → recognizer input
- [ ] Wire one hardcoded pair (en-US ⇄ vi-VN) end-to-end outside the UI (unit test or debug harness) and confirm the <3s STT→translation latency target from PRD §9

## Phase 2 (M2) — Conversation Screen, Live Data

- [ ] Replace mock `ConversationViewModel` state with the Phase 1 services
- [ ] Mic button state machine: Idle → Listening → Processing → Result (+ auto-TTS) → Idle
- [ ] Enforce only one side recording at a time
- [ ] Chat bubble: original + translated text, replay button re-triggers TTS

## Phase 3 (M3) — Language Management Screen, Live Data

- [ ] Real per-language status (STT / Translation / TTS availability checks, not mock booleans)
- [ ] Download / delete actions with real progress reporting
- [ ] Compound "usable" status: a language only counts as ready when all three legs are present

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
