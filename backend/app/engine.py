"""Server-side readiness computation.

Mirrors BleedCore's ReadinessEngine for now. Once cohort baselining exists the
two implementations diverge: on-device stays self-contained for offline use,
while this one gains population priors. Keep the rule shapes in sync until
then; the Swift tests in BleedCore are the reference behavior.

v1 note: the server has no per-user baselines yet (no persistence layer), so
this module exposes the same pure function shape and the API returns an
insufficient-data response until baselines land.
"""

from .schemas import (
    ReadinessDriver,
    ReadinessRequest,
    ReadinessResponse,
    Recommendation,
)


def compute_readiness(request: ReadinessRequest) -> ReadinessResponse:
    # TODO(baselines): load phase-stratified baselines from Postgres and run
    # the attribution logic (raw z-score vs phase-stratum z-score).
    return ReadinessResponse(
        score=50,
        phase_adjusted_score=50,
        primary_driver=ReadinessDriver.insufficient_data,
        recommendation=Recommendation.hold_plan,
        confidence=0.2,
        day=request.day,
    )
