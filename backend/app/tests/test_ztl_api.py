import json
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

from app.main import app
from app.services.ztl_repository import ZtlRepository

client = TestClient(app)


def test_city_list_endpoint() -> None:
    response = client.get("/api/cities")
    assert response.status_code == 200
    assert {city["id"] for city in response.json()["cities"]} == {
        "rome",
        "milan",
        "florence",
    }


def test_city_not_found() -> None:
    response = client.get("/api/cities/nope")
    assert response.status_code == 404
    assert response.json()["detail"] == "Unknown city 'nope'."


def test_milan_zones_endpoint() -> None:
    response = client.get("/api/cities/milan/ztl/zones")
    assert response.status_code == 200
    assert len(response.json()["zones"]) == 2


def test_florence_zones_endpoint() -> None:
    response = client.get("/api/cities/florence/ztl/zones")
    assert response.status_code == 200
    assert len(response.json()["zones"]) == 6


def test_rome_map_bundle_has_geometry_and_missing_geometry_zones() -> None:
    response = client.get("/api/cities/rome/ztl/map")
    assert response.status_code == 200
    payload = response.json()
    assert payload["areas"]["type"] == "FeatureCollection"
    assert len(payload["areas"]["features"]) >= 1
    assert "centro-storico-diurna" in {item["zoneId"] for item in payload["missingGeometryZones"]}


def test_legacy_rome_endpoint_still_works() -> None:
    response = client.get("/api/ztl/zones")
    assert response.status_code == 200
    assert any(zone["cityId"] == "rome" for zone in response.json()["zones"])


def test_invalid_datetime_returns_422() -> None:
    response = client.get("/api/cities/rome/ztl/status", params={"at": "not-a-date"})
    assert response.status_code == 422
    assert response.json()["detail"] == "Invalid request parameters."


def test_source_metadata_present_for_city_zone() -> None:
    response = client.get("/api/cities/milan/ztl/zones/milan-area-c")
    assert response.status_code == 200
    source = response.json()["sources"][0]
    assert source["publisher"] == "Comune di Milano"
    assert source["lastVerified"] == "2026-05-12"


def test_malformed_dataset_fails_fast(tmp_path: Path) -> None:
    data_root = tmp_path / "data"
    (data_root / "milan" / "geojson").mkdir(parents=True)
    (data_root / "rome" / "geojson").mkdir(parents=True)
    (data_root / "florence" / "geojson").mkdir(parents=True)
    (data_root / "cities.json").write_text(
        json.dumps(
            {
                "cities": [
                    {
                        "id": "milan",
                        "name": "Milan",
                        "country": "Italy",
                        "timezone": "Europe/Rome",
                        "center": {"latitude": 45.46, "longitude": 9.19},
                        "default_zoom": 11,
                        "enabled": True,
                        "supported_status": "schedule_only",
                        "source_summary": "test",
                        "last_verified": "2026-05-12",
                        "geometry_status": {
                            "has_any_geometry": False,
                            "missing_geometry_reason": "test"
                        }
                    }
                ]
            }
        ),
        encoding="utf-8",
    )
    (data_root / "milan" / "zones.json").write_text(
        json.dumps(
            {
                "zones": [
                    {
                        "id": "broken",
                        "zone_id": "broken",
                        "city_id": "milan",
                        "name": "Broken",
                        "city": "Milan",
                        "type": "paid_access",
                        "timezone": "Europe/Rome",
                        "human_readable_it": "Broken",
                        "human_readable_en": "Broken",
                        "rules": [
                            {
                                "id": "bad",
                                "label_it": "Bad",
                                "label_en": "Bad",
                                "weekdays": [8],
                                "start_time": "07:30:00",
                                "end_time": "19:30:00"
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
                        "map_style": {
                            "fill_color_key": "x",
                            "stroke_color_key": "y",
                            "priority": 1,
                            "visible_by_default": True
                        },
                        "geometry": {
                            "quality": "missing"
                        },
                        "sources": [],
                        "disclaimer": "Broken"
                    }
                ]
            }
        ),
        encoding="utf-8",
    )

    with pytest.raises(ValidationError):
        ZtlRepository(data_root=data_root)
