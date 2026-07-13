"""API schemas.

Privacy invariant: this service only ever sees the derived cycle phase label
(phase name, cycle day, confidence). Raw reproductive data (flow, basal
temperature, symptoms) is processed on-device and must never appear in any
schema in this module.
"""

from datetime import date
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field


class CyclePhase(str, Enum):
    menstrual = "menstrual"
    follicular = "follicular"
    ovulatory = "ovulatory"
    luteal = "luteal"


class PhaseLabel(BaseModel):
    """The reduced, de-identified phase representation computed on-device."""

    model_config = ConfigDict(extra="forbid")

    phase: CyclePhase
    cycle_day: int = Field(ge=1, le=60)
    confidence: float = Field(ge=0.0, le=1.0)


class TrainingLoad(BaseModel):
    model_config = ConfigDict(extra="forbid")

    ctl: float
    atl: float
    yesterday_load: float = 0.0
    planned_load: float | None = None


class Recovery(BaseModel):
    model_config = ConfigDict(extra="forbid")

    hrv: float | None = None
    resting_heart_rate: float | None = None
    sleep_duration_seconds: float | None = None
    sleep_quality: float | None = Field(default=None, ge=0.0, le=1.0)
    respiratory_rate: float | None = None


class ReadinessRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    # Pseudonymous per-install identifier; never an email or name.
    athlete_ref: str = Field(min_length=8, max_length=64)
    day: date
    phase: PhaseLabel | None = None
    training_load: TrainingLoad | None = None
    recovery: Recovery


class ReadinessDriver(str, Enum):
    cycle_phase = "cyclePhase"
    training_fatigue = "trainingFatigue"
    recovered = "recovered"
    insufficient_data = "insufficientData"


class Recommendation(str, Enum):
    proceed = "proceed"
    hold_plan = "holdPlan"
    reduce_intensity = "reduceIntensity"
    rest = "rest"


class ReadinessResponse(BaseModel):
    score: float = Field(ge=0, le=100)
    phase_adjusted_score: float = Field(ge=0, le=100)
    primary_driver: ReadinessDriver
    recommendation: Recommendation
    confidence: float = Field(ge=0.0, le=1.0)
    day: date
