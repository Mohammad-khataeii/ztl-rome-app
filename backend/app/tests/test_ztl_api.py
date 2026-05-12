import json
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

from app.main import app
from app.services.ztl_repository import ZtlRepository

client = TestClient(app)


def test_list_zones_returns_supported_zones() -> None:
    response = client.get("/api/ztl/zones")

    assert response.status_code == 200
    payload = response.json()
    assert len(payload["zones"]) >= 7
    assert any(zone["id"] == "tridente-a1" for zone in payload["zones"])


def test_status_endpoint_accepts_datetime_query() -> None:
    response = client.get("/api/ztl/status", params={"at": "2026-05-12T22:30:00+02:00"})

    assert response.status_code == 200
    payload = response.json()
    assert "zones" in payload
    assert payload["checkedAt"].startswith("2026-05-12T22:30:00")


def test_unknown_zone_returns_clean_404() -> None:
    response = client.get("/api/ztl/zones/does-not-exist")

    assert response.status_code == 404
    assert response.json()["detail"] == "Unknown zone 'does-not-exist'."


def test_missing_geometry_returns_clean_404() -> None:
    response = client.get("/api/ztl/zones/tridente-a1/area")

    assert response.status_code == 404
    assert "unavailable" in response.json()["detail"]


def test_invalid_datetime_returns_422() -> None:
    response = client.get("/api/ztl/status", params={"at": "not-a-date"})

    assert response.status_code == 422
    assert response.json()["detail"] == "Invalid request parameters."


def test_malformed_dataset_fails_fast(tmp_path: Path) -> None:
    data_dir = tmp_path / "rome"
    geojson_dir = data_dir / "geojson"
    geojson_dir.mkdir(parents=True)
    (data_dir / "zones.json").write_text(
        json.dumps(
            {
                "zones": [
                    {
                        "id": "broken",
                        "name": "Broken",
                        "city": "Roma",
                        "type": "nighttime",
                        "timezone": "Europe/Rome",
                        "human_readable_it": "Broken",
                        "human_readable_en": "Broken",
                        "rules": [
                            {
                                "id": "broken-rule",
                                "label_it": "Broken",
                                "label_en": "Broken",
                                "weekdays": [8],
                                "start_time": "23:00:00",
                                "end_time": "03:00:00"
                            }
                        ],
                        "exclusions": [],
                        "restrictions": {
                            "vehicle_classes": [],
                            "known_exemptions": [],
                            "disabled_permit_note": "",
                            "electric_vehicle_note": "",
                            "motorcycles_note": ""
                        },
                        "geometry": {},
                        "sources": [],
                        "disclaimer": "Broken"
                    }
                ]
            }
        ),
        encoding="utf-8",
    )

    with pytest.raises(ValidationError):
        ZtlRepository(data_dir=data_dir)

