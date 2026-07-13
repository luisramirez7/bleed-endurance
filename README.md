# Bleed

Endurance training for anyone who menstruates.

Bleed is a phase-aware readiness engine. It fuses menstrual cycle phase (estimated on-device from HealthKit) with training load (from intervals.icu) to produce a daily readiness score and recommendation that correctly distinguishes cycle-driven biometric shifts from training-driven fatigue.

## The core idea

Generic readiness tools compare today's HRV to a flat rolling mean, so a normal luteal-phase dip looks like fatigue. Bleed keeps phase-stratified baselines: today's HRV is compared to your typical HRV for this phase. The recovery deviation is then attributed, splitting it into the part explained by the expected phase effect and the residual. Recommendations key off the residual, because that is the actual training and life-stress signal.

## Privacy architecture

This is a hard invariant, not a feature:

- **On-device only:** all raw reproductive HealthKit data (menstrual flow, basal temperature, symptoms). Cycle phase estimation runs locally.
- **Backend (pseudonymized):** training load, recovery trends, and the derived phase label only (for example "luteal, day 22, confidence 0.9"). The backend schemas reject any payload containing raw reproductive fields.

## Repository layout

| Path | What it is |
|---|---|
| `BleedCore/` | Swift package: domain models, cycle phase estimator, readiness engine, intervals.icu client. Platform-independent, tested with `swift test`. |
| `ios/` | The iOS app (SwiftUI, Swift 6). Xcode project is generated from `ios/project.yml` with XcodeGen. |
| `backend/` | FastAPI service for readiness computation over de-identified data. |
| `docs/` | Product and architecture spec. |

## Development

### Core package

```sh
cd BleedCore
swift test
```

### iOS app

```sh
brew install xcodegen
cd ios
xcodegen generate
open Bleed.xcodeproj
```

The generated `.xcodeproj` is not committed; regenerate it after changing `project.yml`.

### Backend

```sh
cd backend
python3 -m venv .venv
.venv/bin/pip install -e '.[dev]'
.venv/bin/pytest
.venv/bin/uvicorn app.main:app --reload
```

Or with Docker: `docker compose up` (API on :8000, Postgres 16).
