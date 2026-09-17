# Product Requirements Document: Offline Duo-Language Translator (MVP)

**Version:** 1.0 (MVP)
**Platform:** iOS 18.0+ (see note below)
**Author:** Product/Founder
**Status:** Draft

> **Deployment target correction (Phase 1, DEVELOPMENT_PLAN.md):** this doc originally targeted iOS 17.4+, reflecting the `Translation` framework's earliest availability. In practice, 17.4 only ships the system-sheet `.translationPresentation` UI, which doesn't return translated text to the app. Getting a string back to render in our own bubble UI and feed to our own TTS — which this product requires — needs the session-based `TranslationSession`/`.translationTask` API, which the SDK marks iOS 18.0+. Bumped accordingly; iOS 18 is over two years old as of this writing; the reduction in addressable devices is negligible.

---

## 1. Overview

A single-screen iOS app that lets two people speaking different languages hold a face-to-face conversation. One person taps their side, speaks, and their words appear translated (with original) in a chat bubble on their side, spoken aloud automatically. The other person does the same on their side. Fully offline once language packs are downloaded.

**Core principle:** minimal surface area. Two screens total.

---

## 2. Goals

- Enable a real-time, offline, two-way spoken conversation between two languages.
- Zero learning curve — no settings menus, no onboarding flow beyond picking two languages.
- Reliable turn-taking via manual speaker toggle (not automatic language detection — see rationale below).
- Works fully offline after initial model downloads.

## 3. Non-Goals (explicitly out of scope for MVP)

- Automatic speaker/language detection (no "just talk and it figures out who's speaking"). Manual toggle only.
- Support for more than 2 languages in a single session.
- Conversation history persistence across app launches.
- Multi-turn/group conversations (3+ participants).
- Text-only input mode (typing instead of speaking).
- Accounts, sync, cloud backup.
- Custom voice selection / voice tuning UI.
- Camera/text translation (photo translate).

---

## 4. Users & Core Use Case

**Primary user:** Two people, physically together, who don't share a language — travelers, hosts, businesspeople, healthcare/service settings.

**Core flow:**
1. Person A opens app, sets Language A (e.g., English) and Language B (e.g., Vietnamese) via two selectors.
2. Person A taps the left mic button, speaks "Hello."
3. App transcribes in English, translates to Vietnamese, shows both in one bubble on the left, speaks the Vietnamese translation aloud.
4. Person B taps the right mic button, speaks in Vietnamese.
5. App transcribes in Vietnamese, translates to English, shows both in one bubble on the right, speaks the English translation aloud.
6. Conversation continues, alternating taps.

---

## 5. Screens

### 5.1 Screen 1 — Main Conversation Screen (primary/default screen)

**Layout:**
- Top bar: two language selectors side by side (e.g., `🇺🇸 English ⇄ 🇻🇳 Tiếng Việt`), tapping either opens a language picker (see 5.2 for pack dependency).
- Center: scrollable chat-bubble feed, left-aligned bubbles for Language A speaker, right-aligned for Language B speaker.
- Each bubble contains:
  - Original transcribed text (smaller/secondary style)
  - Translated text (primary style)
  - A small speaker icon to replay TTS of the translation
- Bottom: two large mic buttons — one left-aligned (tied to Language A), one right-aligned (tied to Language B). Only one can be actively recording at a time.

**Interaction states per mic button:**
- Idle → Listening (tap to start) → Processing (transcribing/translating, brief spinner in bubble) → Result rendered + auto-TTS playback → Idle.
- Tap-to-talk only for MVP (press to start, press again or auto-stop on silence to end). No push-to-hold requirement, but auto-stop-on-silence (VAD) is a "nice to have" — see 8.2.
- If a required language pack isn't downloaded, tapping mic prompts a redirect to Screen 2 with the relevant pack highlighted, rather than failing silently.

**Empty state:** Simple prompt — "Choose your two languages, then tap a mic to start talking."

### 5.2 Screen 2 — Language & Model Management

Accessed via a small settings/gear icon on Screen 1 (top corner) or automatically when a needed pack is missing.

**Contents:**
- List of all supported languages, each row showing:
  - Language name
  - Status: Not Downloaded / Downloading (progress bar) / Downloaded
  - Download / Delete button
- Two sub-components bundled per language (abstracted from user as a single "download" action):
  - Translation model (Apple `Translation` framework language pack)
  - Speech recognition (STT) support — flagged if on-device recognition isn't available for that locale
  - TTS voice — flagged if no offline voice is installed for that locale (deep-link to iOS Settings > Accessibility > Spoken Content > Voices if needed)
- A note/banner if a selected language lacks full on-device support for one of the three components (STT, translation, or TTS), since coverage varies by language.

This screen is purely functional — no theming, no extras.

---

## 6. Functional Requirements

| # | Requirement | Priority |
|---|---|---|
| 1 | User can select two languages from a supported list via two selectors on Screen 1 | P0 |
| 2 | Tapping left/right mic records audio and runs on-device STT using the locale assigned to that side | P0 |
| 3 | Transcribed text is translated on-device to the other selected language | P0 |
| 4 | Result displayed as one bubble containing original + translated text, aligned to the side that spoke | P0 |
| 5 | Translated text is automatically spoken aloud via on-device TTS immediately after translation | P0 |
| 6 | Each bubble has a replay button to re-trigger TTS playback of the translation | P0 |
| 7 | Language pack management screen lists download status and allows download/delete per language | P0 |
| 8 | App detects and warns if a selected language lacks on-device STT, translation, or TTS support | P0 |
| 9 | App functions with no network connection once required packs are downloaded | P0 |
| 10 | Conversation feed persists only for the current session (cleared on app relaunch) | P1 |
| 11 | Auto-stop recording on silence detection (VAD) instead of requiring a second tap | P2 |
| 12 | Visual "recording" and "processing" states on the active mic button | P0 |
| 13 | App UI (labels, buttons, screen titles) can be displayed in one of 5–10 pre-translated display languages, independent of the conversation languages selected | P1 |
| 14 | User can manually switch display language via a switcher on Screen 2; default is auto-selected from device locale on first launch | P1 |

---

## 6.1 UI Display Language (P1 — separate from conversation languages)

**Important distinction:** the conversation-language packs (STT, `Translation` framework, TTS voices) translate *spoken content* between two people. They are a different system from the app's own UI text (button labels, screen titles, empty states, settings copy) and cannot be reused to localize the interface. UI localization is handled the standard iOS way, via a `String Catalog`.

**Approach:**
- Hardcode pre-translated strings for the app's full UI text (estimated well under 50 strings — mic button states, two selector labels, "Download," "Delete," "Downloaded," "Not Downloaded," empty-state copy, error/warning banners, settings screen labels) into a `String Catalog` covering the initial 5–10 target display languages.
- No runtime translation, no dependency on which conversation-language packs are downloaded — display language and conversation languages are fully decoupled. A user could run the UI in French while translating between English and Vietnamese, for example.
- **Default behavior:** on first launch, display language auto-matches the device's system locale if it falls within the supported list; otherwise falls back to English.
- **Manual override:** a simple language switcher (list or picker) added to Screen 2 (Language & Model Management), letting the user pick a display language independent of the auto-detected default.
- Because this is a small, fixed string set, translations can be sourced once (professional/manual translation or reviewed MT) rather than machine-translated at runtime — avoids awkward phrasing on short imperative UI labels.

**Scope note:** this does not require an additional screen. It's one addition to Screen 2 (a "Display Language" row/picker) plus the underlying String Catalog work, which is a one-time build-time task rather than an ongoing runtime feature.

---

## 7. Technical Approach (iOS-native, offline-first)

| Function | Framework | Notes |
|---|---|---|
| Speech-to-text | `SFSpeechRecognizer` (on-device mode) | Must check `supportsOnDeviceRecognition` per locale before allowing selection |
| Translation | `Translation` framework, `TranslationSession`/`.translationTask` (iOS 18.0+) | `LanguageAvailability.status(from:to:)` to check availability; a session vended via `.translationTask` handles on-device model download prompting |
| Text-to-speech | `AVSpeechSynthesizer` | Use best available offline voice per locale (`AVSpeechSynthesisVoice`) |
| Audio capture | `AVAudioEngine` | Feeds buffer to `SFSpeechRecognizer`; also basis for future VAD (P2) |
| UI | SwiftUI | Single main view + one settings/list view |
| Persistence | In-memory only (session-scoped) for MVP; no local DB needed |

**Language pack dependency chain:** a language is only "usable" once all three of STT, translation, and TTS are available on-device for it. The management screen should reflect this compound status clearly rather than three separate toggles.

---

## 8. Explicit MVP Simplifications & Rationale

1. **Manual speaker toggle, not auto-detection.** Blind language ID on short spoken phrases is unreliable with on-device tools; a toggle is faster to build and more trustworthy in practice.
2. **No conversation history persistence.** Reduces scope (no storage layer, no privacy/data-retention questions for MVP).
3. **Tap-to-talk over full VAD.** Silence-detection auto-stop is a fast follow, not a blocker — manual tap-again-to-stop is an acceptable fallback for v1.
4. **Two languages per session only.** Keeps UI to two selectors and two bubble alignments; no speaker-attribution complexity.

---

## 9. Success Metrics (MVP)

- Time from cold launch to first successful translated bubble < 15 seconds (assuming packs pre-downloaded).
- STT-to-spoken-translation latency target: < 3 seconds for a short sentence, on-device, no network.
- Crash-free session rate > 99%.
- % of supported language pairs where all three components (STT/translation/TTS) are available on-device (used to set realistic launch language list — don't advertise a language pair if one leg is missing).

---

## 10. Open Questions / Risks

- **Language coverage gaps:** Not all languages have on-device STT or high-quality offline TTS voices. The initial supported-language list should be curated to pairs with full on-device support (validate Vietnamese specifically, since it's the example case).
- **Storage footprint:** Each language pack (STT + translation + voice) can be sizable; management screen should show approximate size before download.
- **Silence/turn-taking edge cases:** Overlapping speech or background noise may degrade STT accuracy — no mitigation planned for MVP beyond manual mic control.
- **App Store review:** On-device only, first-party frameworks — low risk. Minimum OS requirement is iOS 18.0+ (see correction at top of doc), which does not meaningfully cut addressable devices given its age at time of writing.

---

## 11. Milestones (suggested)

1. **M1:** Core STT → Translation → TTS pipeline working for one hardcoded language pair (proof of concept, no UI polish).
2. **M2:** Screen 1 built — mic buttons, bubbles, language selectors, tap-to-talk flow.
3. **M3:** Screen 2 built — pack management, download/delete, compound status indicator.
4. **M4:** Error states, offline validation, gap warnings (missing STT/TTS/translation per language).
5. **M5:** Polish pass — recording/processing states, replay button, empty state, basic QA across 3–4 language pairs.
