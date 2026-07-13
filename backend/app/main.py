from fastapi import FastAPI

from .engine import compute_readiness
from .schemas import ReadinessRequest, ReadinessResponse

app = FastAPI(
    title="Bleed Backend",
    description=(
        "Readiness computation over derived phase labels and training data. "
        "Raw reproductive health data is processed on-device and never sent here."
    ),
    version="0.1.0",
)


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/v1/readiness", response_model=ReadinessResponse)
def readiness(request: ReadinessRequest) -> ReadinessResponse:
    return compute_readiness(request)
