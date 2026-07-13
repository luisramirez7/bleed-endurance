# Bleed product and architecture spec

Status: v1, agreed 2026-07-13. This is the source of truth for scope and invariants.

## One-line definition

A phase-aware readiness engine for endurance athletes who menstruate. It fuses menstrual cycle phase (from HealthKit) with training load (from intervals.icu) to produce a daily readiness score and recommendation that correctly distinguishes cycle-driven biometric shifts from training-driven fatigue.

## MVP scope

Position broad ("all endurance athletes who menstruate"), validate narrow. The pipes are sport-agnostic (intervals.icu already normalizes load, HRV, and sleep across sports), but the fusion model is tuned and validated on cycling first, where our own data and domain knowledge are.

## Privacy-partitioned hybrid architecture (hard invariant)

Menstrual and reproductive data is the most sensitive category the app will ever handle, and reproductive health data is politically fraught in some jurisdictions. That drives architecture, not just policy.

- **On-device, never leaves the phone in identifiable form:** all raw HealthKit reproductive data (`menstrualFlow`, basal and wrist temperature, symptoms, ovulation tests). Cycle phase estimation runs locally.
- **Backend, pseudonymized:** training load, HRV and RHR trends, and the derived phase label (for example "luteal, day 3, confidence 0.8"). The heavier readiness model and any cohort baselining run on this reduced, de-identified representation.

The phone answers "what phase am I in" from the sensitive raw data. The backend answers "given your phase label, load, and recovery, here is your readiness." Backend schemas forbid unknown fields so a client bug that leaks raw reproductive data is rejected at the boundary.

## Tech stack

iOS app (native):

- Swift 6, strict concurrency
- SwiftUI first, UIKit only if a chart needs it
- Observation framework (`@Observable`) for state
- HealthKit for the reproductive and recovery backbone
- SwiftData for local persistence
- Swift Charts; budget for a custom Canvas renderer only if power-curve views hit its ceiling
- BGTaskScheduler for background sync and overnight readiness computation
- async/await URLSession for the intervals.icu client

Backend:

- Python, FastAPI (chosen over Node because the readiness model may grow toward real ML, and pandas/numpy/scikit are right there)
- Postgres, with row-level encryption on anything remotely identifiable
- intervals.icu ingestion runs server-side on a schedule so training data and phase labels meet in one place

Training data ingestion:

- intervals.icu API for the MVP: FTP, CTL/ATL/form, power curve, plus wellness (HRV, sleep). Worth confirming whether its wellness data is rich enough to shrink the HealthKit surface for v1, leaving HealthKit primarily for reproductive data.
- Strava and TrainingPeaks later, behind the common `TrainingDataSource` protocol from day one. TrainingPeaks API approval can be slow; do not block the MVP on it.

## Core data model

- `CyclePhaseEstimate`: phase, cycleDay, confidence, source (logged or inferred), date. Computed on-device.
- `RecoverySnapshot`: hrv, rhr, sleepDuration, sleepQuality, respiratoryRate, date.
- `TrainingLoadSnapshot`: ctl, atl, form, yesterdayLoad, plannedLoad, date. From intervals.icu.
- `ReadinessScore`: score, phaseAdjustedScore, primaryDriver, recommendation, confidence, date. The output object users open the app to see.
- `UserBaseline`: per-user rolling baselines for HRV and RHR stratified by cycle phase. This is the secret sauce: baselines that know your luteal HRV runs lower than your follicular HRV.

## The fusion logic (the actual IP)

The readiness engine's job is disambiguation:

1. Establish phase-stratified baselines. Do not compare today's HRV to a flat 60-day mean; compare it to your typical HRV for this phase. A luteal HRV dip versus your luteal baseline is neutral; the same absolute number versus your follicular baseline would be alarming.
2. Compute a raw recovery deviation, then attribute it: how much of today's deviation is explained by expected phase effects versus residual (which is the training and life signal)?
3. The recommendation keys off the residual, not the raw number. "HRV down 15% but about 12% of that is expected for late luteal, treat as mild, hold plan" versus "HRV down 15%, phase-neutral, on top of a hard block, back off."

That attribution step is what generic platforms do not do. Everything else in the app is table stakes; this is the reason to exist.

Rules-based first. Do not reach for ML until there is data and the rules are demonstrably insufficient.

## Build sequence

1. HealthKit reproductive and recovery read layer, plus the local cycle phase estimator (logged period to phase, temperature as a refinement later). Validate against real cycle and recovery data.
2. intervals.icu client and `TrainingLoadSnapshot` ingestion. Dogfood against our own training data.
3. Phase-stratified baselines and readiness engine v1, rules-based.
4. The one screen that matters: today's readiness and the why. Ship this before history, trends, or settings.
5. Backend and privacy partition, then Strava and TrainingPeaks sources as approvals land.

## Open questions

- Map exactly which wellness, HRV, and sleep fields the intervals.icu API exposes versus HealthKit, and decide which source owns each data point. If intervals.icu wellness is rich enough, HealthKit's v1 surface shrinks to primarily reproductive data.
- `yesterdayLoad` and `plannedLoad` need the intervals.icu activities and events endpoints; the wellness endpoint only carries CTL and ATL.
