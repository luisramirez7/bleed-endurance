from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_healthz():
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_readiness_accepts_phase_label():
    response = client.post(
        "/v1/readiness",
        json={
            "athlete_ref": "a" * 16,
            "day": "2026-07-13",
            "phase": {"phase": "luteal", "cycle_day": 22, "confidence": 0.9},
            "training_load": {"ctl": 70, "atl": 75},
            "recovery": {"hrv": 49, "resting_heart_rate": 52},
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert 0 <= body["score"] <= 100
    assert body["day"] == "2026-07-13"


def test_raw_reproductive_fields_are_rejected():
    """The privacy partition is enforced at the schema boundary: any raw
    reproductive field in the payload is a client bug and must be rejected."""
    response = client.post(
        "/v1/readiness",
        json={
            "athlete_ref": "a" * 16,
            "day": "2026-07-13",
            "phase": {
                "phase": "luteal",
                "cycle_day": 22,
                "confidence": 0.9,
                "menstrual_flow": "heavy",
            },
            "recovery": {"hrv": 49},
        },
    )
    assert response.status_code == 422


def test_identifiable_athlete_ref_shape_is_rejected():
    response = client.post(
        "/v1/readiness",
        json={
            "athlete_ref": "short",
            "day": "2026-07-13",
            "recovery": {"hrv": 49},
        },
    )
    assert response.status_code == 422
