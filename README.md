# Conversely

An offline, two-way, two-person spoken-conversation translator for iOS. One person taps their side, speaks, and their words appear translated in a chat bubble on their side, spoken aloud automatically; the other person does the same on their side. Fully offline once language packs are downloaded.

Two screens total: **Converse** (default) and **Languages** (pack management). See `PRD.md` for the full product spec and `DESIGN.md` for the visual design system.

## Requirements

- Xcode 16+ (built/tested with Xcode 26.6)
- iOS 18.0+ deployment target (required by `TranslationSession`/`.translationTask` — see PRD.md's deployment target correction)
- **iOS 26+ on the device for the full experience.** Installing a language's speech model from inside the app uses `AssetInventory`, which is iOS 26 only. Below that, speech recognition falls back to the legacy `SFSpeechRecognizer`, whose models can only be installed by iOS itself via Settings.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

**A physical device is required for anything language-related.** The Simulator cannot provision non-English on-device ML assets at all: every non-English pair reports translation `unsupported` and on-device speech recognition `false` there, regardless of what the device would do. All language validation in this project was done on an iPhone.

## Getting started

The `.xcodeproj` is generated from `project.yml` and is not committed to git (so it never drifts from the spec, and there's nothing to merge-conflict on).

```sh
xcodegen generate
open Conversely.xcodeproj
```

Then select an iOS Simulator and hit Run. Re-run `xcodegen generate` any time `project.yml` changes, or after pulling changes that touch it.

## Project layout

```
Conversely/
  App/                         entry point, tab navigation, theme tokens (from DESIGN.md)
  Core/
    Models/                    Language, ConversationTurn, LanguagePackStatus, DisplayLanguage
    Services/                  speech recognition, translation, synthesis, audio capture,
                               speech-asset install, UI localization
  Features/
    Conversation/               Screen 1: language selector, chat bubbles, mic buttons
    LanguageManagement/         Screen 2: pack status and download
  Debug/                        diagnostic harnesses, reachable only via launch arguments
  Resources/
    Assets.xcassets
    Localizable.xcstrings       UI String Catalog (English, Vietnamese)
Tools/
  GenerateAppIcon.swift        renders the app icon; re-run after editing it (see below)
Assets/                        reference screen mockups (HTML + rendered PNG), not part of the app target
project.yml                    XcodeGen project spec — source of truth for the Xcode project
DEVELOPMENT_PLAN.md            phased engineering plan (M1-M5) plus the on-device findings behind key decisions
PRD.md / DESIGN.md             product requirements / design system
```

### App icon

The icon is generated rather than hand-exported, so its geometry and colors stay editable and tied to the `DESIGN.md` palette. After editing `Tools/GenerateAppIcon.swift`:

```sh
swift Tools/GenerateAppIcon.swift Conversely/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

Keep artwork inside roughly x/y 170–820 of the 1024 canvas — iOS masks the icon to a rounded square and clips the corners.

### Diagnostics

Two harnesses run outside the production UI, each behind a launch argument:

```sh
--pipeline-test                     # end-to-end STT/translation/TTS for one hardcoded pair
--language-scan                     # per-language report: translation, both speech engines, voice
--language-scan --install=ko-KR     # download one speech asset, logging progress
```

## Status

**The MVP is complete** — all five phases are built and signed off on device. A full conversation turn (speech → transcription → translation → spoken reply) runs entirely on-device, confirmed in airplane mode. Measured translation latency is 0.20s, comfortably inside the PRD's 3s target.

Languages offered: English, Vietnamese, Spanish, French, German, Japanese, Chinese (Simplified). Each is downloadable entirely from inside the app — no Settings detour.

### Things worth knowing before changing this code

- **There are two independent on-device speech engines, and neither alone is enough.** `SpeechTranscriber` (iOS 26) covers ~30 locales and its models are installable from the app; `SFSpeechRecognizer` covers more languages (Vietnamese among them) but its models are system-managed. `SpeechRecognitionService` is hybrid for that reason, and availability is the union of both. Installing a model for one does nothing for the other — verified directly.
- **No download can report a percentage.** `AssetInstallationRequest.progress` sits at `0 of 1` for the entire install, and the Translation framework has no progress API at all. That's why the UI uses a spinner rather than a progress bar; it isn't a shortcut.
- **A speech-model install can't be cancelled** — cancellation is accepted and then ignored by the system.
- **Nothing can be deleted from inside the app.** No public deletion API exists for translation packs, speech models, or voices, which is why the Languages screen has no delete affordance and points at Settings instead.

Each of these was measured on device rather than assumed; `DEVELOPMENT_PLAN.md` records the evidence.

### Not implemented

Per PRD §3, and one deliberate omission: re-requesting a download for the *same* language immediately after cancelling it won't re-show the system sheet. `prepareTranslation()` suppresses a repeat prompt for a pair it has already asked about, with no public API to reset that. The row keeps spinning and promotes itself when the pack lands, so waiting recovers it.

## Workflow

Each phase in `DEVELOPMENT_PLAN.md` was built on its own branch (`feature/*`), committed incrementally, and merged into `main` only after manual sign-off on a physical device.
