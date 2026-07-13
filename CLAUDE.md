# Bleed: working agreements

## Prose style

- Never use em-dashes in prose, and never use "--" as a substitute. Use commas, periods, or parentheses. This applies to docs, comments, commit messages, and chat output.

## Pace

- Development time does not matter. Never cut scope, skip tests, or pick a shortcut to save time. Prefer the thorough route.

## Hard architectural invariants

1. **Privacy partition.** Raw reproductive HealthKit data (menstrual flow, basal body temperature, symptoms, ovulation tests) never leaves the device. Phase estimation runs on-device. Only the derived phase label (phase, cycle day, confidence) plus training and recovery data may be sent to the backend, pseudonymized. Backend schemas use `extra="forbid"` so unexpected fields are rejected at the boundary; keep it that way.
2. **Attribution is the product.** Readiness compares biometrics to phase-stratified baselines and keys recommendations off the residual deviation, not the raw number. Do not regress to flat baselines.
3. **Rules before ML.** The readiness engine stays rules-based until real user data shows the rules are insufficient.
4. **Sources behind protocols.** All training data providers implement `TrainingDataSource` (BleedCore). intervals.icu is first; Strava and TrainingPeaks are additive later.

## Stack and layout

- `BleedCore/`: Swift 6 package, platform-independent domain logic. All engine logic and its tests live here, runnable with `swift test` on macOS (no simulator needed).
- `ios/`: SwiftUI app, Swift 6 strict concurrency, `@Observable` for state, SwiftData for persistence, HealthKit, BGTaskScheduler. The Xcode project is generated: edit `ios/project.yml`, run `xcodegen generate`, never hand-edit the `.xcodeproj` (it is gitignored).
- `backend/`: Python FastAPI, Pydantic v2, Postgres. Tests with pytest (`backend/.venv/bin/pytest`).
- The server-side engine (`backend/app/engine.py`) mirrors `BleedCore`'s `ReadinessEngine`. If you change rule shapes in one, update the other; the Swift tests are the reference behavior.

## Design system: Bloom

The visual language lives in the Claude Design project "Bleed Bloom" (`https://claude.ai/design/p/c8c02249-6264-431e-a1dc-2e8eaa1f402b`, read with the DesignSync tool). Its readme.md is the governing doc. The Swift implementation is `ios/Bleed/Theme/BloomTheme.swift`.

- Voice: warm, encouraging, a touch cheeky, never clinical. The app surface uses phase nicknames (Bleed, Rise, Peak, Wind-down), never the clinical names.
- Type: Baloo 2 for headings and every numeral, Nunito for body and labels (bundled in `ios/Bleed/Resources/Fonts`, registered via UIAppFonts). No other families.
- Colour: warm plum-brown ink `#3A2A33` on blush cream `#FBEFEC`, phase colours warm to cool (orange, amber, blue, purple). Shadows are purple-tinted, never grey. No gradient backgrounds.
- Shape: generously rounded (cards 22, tiles 16, chips full pill). The sparkle `✦` is the only glyph-emoji allowed.
- Numbers are the point: never hide the unadjusted score next to the phase-adjusted one.
- The cycle wheel (`CycleWheelView`) is the signature object and doubles as the brand mark.

## Validation targets

- Tune and validate on cycling first (the user's own data and domain), keep the pipes sport-agnostic.
