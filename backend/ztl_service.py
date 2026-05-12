from __future__ import annotations

from datetime import datetime
from typing import Optional

from app.main import repository, schedule_engine


def centro_notturna_summary(now: Optional[datetime] = None) -> dict:
    zone = repository.get_zone("rome", "centro-storico-notturna")
    status = schedule_engine.evaluate(zone, now or datetime.now())
    return {
        "id": zone.id,
        "name": zone.name,
        "city": zone.city,
        "timezone": zone.timezone,
        "status": {
            "isActive": status.is_active,
            "checkedAt": status.checked_at.isoformat(),
            "reason": status.reason,
            "nextChangeAt": (
                status.next_change_at.isoformat() if status.next_change_at else None
            ),
            "confidence": status.confidence,
        },
        "summary": {
            "gateCount": len(
                repository.get_gates_geojson("rome", zone.id).get("features", []),
            ),
            "polygonPointCount": len(
                repository.get_area_geojson("rome", zone.id).get("features", [])[0][
                    "geometry"
                ]["coordinates"][0]
            ),
            "bounds": repository.get_bounds("rome", zone.id),
        },
    }
