import json
from datetime import datetime, time
from pathlib import Path
from typing import Optional
from zoneinfo import ZoneInfo

DATA_DIR = Path(__file__).parent / "data" / "rome"
ROME_TZ = ZoneInfo("Europe/Rome")


def load_geojson(filename: str) -> dict:
    with (DATA_DIR / filename).open(encoding="utf-8") as file:
        return json.load(file)


def gate_summary(feature: dict) -> dict:
    longitude, latitude = feature["geometry"]["coordinates"]
    properties = feature.get("properties", {})
    return {
        "id": properties.get("ID", feature.get("id")),
        "name": properties.get("LOCALIZZAZ", "").strip(),
        "reference": properties.get("RIFERIMENT", "").strip(),
        "latitude": latitude,
        "longitude": longitude,
    }


def is_centro_notturna_active(now: datetime) -> bool:
    """Rome night ZTL is commonly active late Friday/Saturday into the night."""
    local_time = now.timetz().replace(tzinfo=None)
    weekday = now.weekday()
    is_friday_or_saturday = weekday in {4, 5}
    return is_friday_or_saturday and (
        local_time >= time(23, 0) or local_time < time(3, 0)
    )


def centro_notturna_summary(now: Optional[datetime] = None) -> dict:
    area = load_geojson("rome_ztl_centro_notturna_area.json")
    gates = load_geojson("rome_ztl_centro_notturna_varchi.json")
    coordinates = area["features"][0]["geometry"]["coordinates"][0]
    longitudes = [point[0] for point in coordinates]
    latitudes = [point[1] for point in coordinates]
    checked_at = now or datetime.now(ROME_TZ)

    return {
        "id": "centro-notturna",
        "name": "ZTL Centro Storico Notturna",
        "city": "Roma",
        "timezone": "Europe/Rome",
        "status": {
            "isActive": is_centro_notturna_active(checked_at),
            "checkedAt": checked_at.isoformat(),
            "note": "Indicative schedule: Friday and Saturday, 23:00-03:00. Always confirm official notices before driving.",
        },
        "summary": {
            "gateCount": len(gates["features"]),
            "polygonPointCount": len(coordinates),
            "bounds": {
                "west": min(longitudes),
                "south": min(latitudes),
                "east": max(longitudes),
                "north": max(latitudes),
            },
        },
    }


def centro_notturna_area() -> dict:
    return load_geojson("rome_ztl_centro_notturna_area.json")


def centro_notturna_gates() -> dict:
    gates = load_geojson("rome_ztl_centro_notturna_varchi.json")
    return {
        "type": gates["type"],
        "features": gates["features"],
        "gates": [gate_summary(feature) for feature in gates["features"]],
    }
