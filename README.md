# Conversely

An offline, two-way, two-person spoken-conversation translator for iOS. One person taps their side, speaks, and their words appear translated in a chat bubble on their side, spoken aloud automatically; the other person does the same on their side. Fully offline once language packs are downloaded.

Two screens total: **Converse** (default) and **Languages** (pack management). See `PRD.md` for the full product spec and `DESIGN.md` for the visual design system.

## Requirements

- Xcode 16+ (built/tested with Xcode 26.6)
- iOS 18.0+ deployment target (required by `TranslationSession`/`.translationTask` — see PRD.md's deployment target correction)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

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
    Models/                    Language, ConversationTurn, LanguagePackStatus
    Services/                  (Phase 1+) SFSpeechRecognizer / Translation / AVSpeechSynthesizer wrappers
  Features/
    Conversation/               Screen 1: language selector, chat bubbles, mic buttons
    LanguageManagement/         Screen 2: pack status, download/delete
  Resources/
    Assets.xcassets
Assets/                        reference screen mockups (HTML + rendered PNG), not part of the app target
project.yml                    XcodeGen project spec — source of truth for the Xcode project
DEVELOPMENT_PLAN.md            phased engineering plan (M1-M5)
PRD.md / DESIGN.md             product requirements / design system
```

## Status

**Phase 0 (scaffold) is done:** both screens are built and visually match the mockups in `Assets/`, driven by an in-memory mock view model — tapping a mic button simulates the Idle → Listening → Processing → Result flow with canned transcripts. There is no real speech recognition, translation, or text-to-speech wired up yet; that's Phase 1. See `DEVELOPMENT_PLAN.md` for the full phase breakdown.

## Workflow

Each phase in `DEVELOPMENT_PLAN.md` is built on its own branch (`phase-N-*`), committed incrementally, and merged into `main` only after manual sign-off.
