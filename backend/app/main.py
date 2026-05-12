from __future__ import annotations

import logging
from datetime import datetime
from typing import List, Optional
from zoneinfo import ZoneInfo

from fastapi import FastAPI
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import get_settings
from app.models import CityDefinition, ZoneDefinition
from app.schemas import ErrorResponse, HealthResponse
from app.services.schedule_engine import ScheduleEngine
from app.services.ztl_repository import ZtlRepository

settings = get_settings()
logging.basicConfig(level=getattr(logging, settings.log_level.upper(), logging.INFO))
logger = logging.getLogger("ztl-italy-api")

app = FastAPI(title=settings.api_title)
repository = ZtlRepository()
schedule_engine = ScheduleEngine()

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=False,
    allow_methods=["GET"],
    allow_headers=["*"],
)


@app.exception_handler(RequestValidationError)
async def request_validation_exception_handler(request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content=ErrorResponse(detail="Invalid request parameters.").model_dump(),
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request, exc: Exception):
    logger.exception("Unhandled API error", exc_info=exc)
    return JSONResponse(
        status_code=500,
        content=ErrorResponse(detail="Internal server error.").model_dump(),
    )


def _cacheable_json(content: dict, max_age: int = 300) -> JSONResponse:
    response = JSONResponse(content=jsonable_encoder(content))
    response.headers["Cache-Control"] = f"public, max-age={max_age}"
    return response


def _city_response(city: CityDefinition) -> dict:
    return {
        "id": city.id,
        "name": city.name,
        "country": city.country,
        "timezone": city.timezone,
        "center": {
            "latitude": city.center.latitude,
            "longitude": city.center.longitude,
        },
        "defaultZoom": city.default_zoom,
        "enabled": city.enabled,
        "supportedStatus": city.supported_status,
        "sourceSummary": city.source_summary,
        "lastVerified": city.last_verified.isoformat(),
        "geometryStatus": {
            "hasAnyGeometry": city.geometry_status.has_any_geometry,
            "missingGeometryReason": city.geometry_status.missing_geometry_reason,
        },
    }


def _zone_response(city_id: str, zone: ZoneDefinition, checked_at: datetime) -> dict:
    status = schedule_engine.evaluate(zone, checked_at)
    bounds = repository.get_bounds(city_id, zone.zone_id)
    primary_source = zone.sources[0]
    return {
        "id": zone.id,
        "zoneId": zone.zone_id,
        "cityId": zone.city_id,
        "name": zone.name,
        "city": zone.city,
        "type": zone.type,
        "timezone": zone.timezone,
        "currentStatus": {
            "isActive": status.is_active,
            "checkedAt": status.checked_at,
            "reason": status.reason,
            "nextChangeAt": status.next_change_at,
            "confidence": status.confidence,
        },
        "schedule": {
            "humanReadableIt": zone.human_readable_it,
            "humanReadableEn": zone.human_readable_en,
            "rules": [
                {
                    "id": rule.id,
                    "labelIt": rule.label_it,
                    "labelEn": rule.label_en,
                    "weekdays": rule.weekdays,
                    "startTime": rule.start_time.strftime("%H:%M"),
                    "endTime": rule.end_time.strftime("%H:%M"),
                    "holidayPolicy": rule.holiday_policy,
                    "activeMonths": rule.active_months,
                    "excludedMonths": rule.excluded_months,
                    "season": (
                        {
                            "start": rule.season.start.model_dump(),
                            "end": rule.season.end.model_dump(),
                        }
                        if rule.season
                        else None
                    ),
                    "sourceTitles": rule.source_titles,
                }
                for rule in zone.rules
            ],
            "exclusions": zone.exclusions,
        },
        "restrictions": {
            "vehicleClasses": zone.restrictions.vehicle_classes,
            "knownExemptions": zone.restrictions.known_exemptions,
            "disabledPermitNote": zone.restrictions.disabled_permit_note,
            "electricVehicleNote": zone.restrictions.electric_vehicle_note,
            "motorcyclesCiclomotoriNote": zone.restrictions.motorcycles_note,
        },
        "mapStyle": {
            "fillColorKey": zone.map_style.fill_color_key,
            "strokeColorKey": zone.map_style.stroke_color_key,
            "priority": zone.map_style.priority,
            "visibleByDefault": zone.map_style.visible_by_default,
        },
        "geometry": {
            "hasArea": bool(zone.geometry.area_file),
            "hasGates": bool(zone.geometry.gates_file),
            "areaFile": zone.geometry.area_file,
            "gatesFile": zone.geometry.gates_file,
            "areaEndpoint": (
                f"/api/cities/{city_id}/ztl/zones/{zone.zone_id}/area"
                if zone.geometry.area_file
                else None
            ),
            "gatesEndpoint": (
                f"/api/cities/{city_id}/ztl/zones/{zone.zone_id}/gates"
                if zone.geometry.gates_file
                else None
            ),
            "geometrySource": zone.geometry.geometry_source,
            "lastVerified": (
                zone.geometry.last_verified.isoformat()
                if zone.geometry.last_verified
                else None
            ),
            "quality": zone.geometry.quality,
            "bounds": bounds,
        },
        "sources": [
            {
                "title": source.title,
                "url": str(source.url),
                "publisher": source.publisher,
                "lastVerified": source.last_verified.isoformat(),
                "confidence": source.confidence,
                "warningText": source.warning_text,
            }
            for source in zone.sources
        ],
        "disclaimer": zone.disclaimer,
        "sourceTitle": primary_source.title,
        "sourceUrl": str(primary_source.url),
    }


def _checked_at_for_city(city_id: str, at: Optional[datetime]) -> datetime:
    if at is not None:
        return at
    city = repository.get_city(city_id)
    return datetime.now(ZoneInfo(city.timezone))


def _normalized_features(
    city_id: str,
    zone_payload: dict,
    geometry: dict,
    *,
    is_gate: bool,
) -> List[dict]:
    features = []
    for feature in geometry.get("features", []):
        properties = dict(feature.get("properties") or {})
        properties.update(
            {
                "cityId": city_id,
                "zoneId": zone_payload["zoneId"],
                "zoneName": zone_payload["name"],
                "statusIsActive": zone_payload["currentStatus"]["isActive"],
                "statusReason": zone_payload["currentStatus"]["reason"],
                "nextChangeAt": zone_payload["currentStatus"]["nextChangeAt"],
                "type": zone_payload["type"],
                "sourceTitle": zone_payload["sourceTitle"],
                "sourceUrl": zone_payload["sourceUrl"],
                "fillColorKey": zone_payload["mapStyle"]["fillColorKey"],
                "strokeColorKey": zone_payload["mapStyle"]["strokeColorKey"],
                "priority": zone_payload["mapStyle"]["priority"],
                "isGate": is_gate,
                "gateName": properties.get("LOCALIZZAZ"),
                "gateReference": properties.get("RIFERIMENT"),
            }
        )
        features.append(
            {
                "type": feature.get("type", "Feature"),
                "id": feature.get("id"),
                "geometry": feature.get("geometry"),
                "properties": properties,
            }
        )
    return features


@app.get("/api/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(status="ok", env=settings.app_env, version=settings.app_version)


@app.get("/api/cities")
def list_cities():
    return _cacheable_json({"cities": [_city_response(city) for city in repository.list_cities()]})


@app.get("/api/cities/{city_id}")
def get_city(city_id: str):
    return _cacheable_json(_city_response(repository.get_city(city_id)))


@app.get("/api/cities/{city_id}/ztl/zones")
def list_city_zones(city_id: str, at: Optional[datetime] = None):
    checked_at = _checked_at_for_city(city_id, at)
    zones = [_zone_response(city_id, zone, checked_at) for zone in repository.list_zones(city_id)]
    return _cacheable_json({"zones": zones}, max_age=300)


@app.get("/api/cities/{city_id}/ztl/zones/{zone_id}")
def get_city_zone(city_id: str, zone_id: str, at: Optional[datetime] = None):
    checked_at = _checked_at_for_city(city_id, at)
    zone = repository.get_zone(city_id, zone_id)
    return _cacheable_json(_zone_response(city_id, zone, checked_at), max_age=300)


@app.get("/api/cities/{city_id}/ztl/status")
def get_city_status(city_id: str, at: Optional[datetime] = None):
    checked_at = _checked_at_for_city(city_id, at)
    zones = [_zone_response(city_id, zone, checked_at) for zone in repository.list_zones(city_id)]
    return _cacheable_json({"checkedAt": checked_at.isoformat(), "zones": zones}, max_age=120)


@app.get("/api/cities/{city_id}/ztl/map")
def get_city_map(city_id: str, at: Optional[datetime] = None):
    checked_at = _checked_at_for_city(city_id, at)
    city = repository.get_city(city_id)
    areas = []
    gates = []
    missing_geometry = []
    zones = []

    for zone in repository.list_zones(city_id):
        zone_payload = _zone_response(city_id, zone, checked_at)
        zones.append(zone_payload)
        if zone.geometry.area_file:
            geometry = repository.get_area_geojson(city_id, zone.zone_id)
            areas.extend(_normalized_features(city_id, zone_payload, geometry, is_gate=False))
        elif zone.geometry.gates_file:
            missing_geometry.append(
                {
                    "zoneId": zone.zone_id,
                    "name": zone.name,
                    "reason": "Area geometry unavailable.",
                }
            )
        else:
            missing_geometry.append(
                {
                    "zoneId": zone.zone_id,
                    "name": zone.name,
                    "reason": "Geometry unavailable.",
                }
            )

        if zone.geometry.gates_file:
            geometry = repository.get_gates_geojson(city_id, zone.zone_id)
            gates.extend(_normalized_features(city_id, zone_payload, geometry, is_gate=True))

    return _cacheable_json(
        {
            "city": _city_response(city),
            "zones": zones,
            "areas": {"type": "FeatureCollection", "features": areas},
            "gates": {"type": "FeatureCollection", "features": gates},
            "missingGeometryZones": missing_geometry,
        },
        max_age=120,
    )


@app.get("/api/cities/{city_id}/ztl/zones/{zone_id}/area")
def get_city_zone_area(city_id: str, zone_id: str):
    return _cacheable_json(repository.get_area_geojson(city_id, zone_id), max_age=3600)


@app.get("/api/cities/{city_id}/ztl/zones/{zone_id}/gates")
def get_city_zone_gates(city_id: str, zone_id: str):
    return _cacheable_json(repository.get_gates_geojson(city_id, zone_id), max_age=3600)


@app.get("/api/cities/{city_id}/ztl/sources")
def get_city_sources(city_id: str):
    sources = [
        {
            "title": source.title,
            "url": str(source.url),
            "publisher": source.publisher,
            "lastVerified": source.last_verified.isoformat(),
            "confidence": source.confidence,
            "warningText": source.warning_text,
        }
        for source in repository.list_sources(city_id)
    ]
    return _cacheable_json({"sources": sources}, max_age=3600)


# Backward-compatible Rome endpoints.
@app.get("/api/ztl/zones")
def legacy_list_rome_zones(at: Optional[datetime] = None):
    return list_city_zones("rome", at=at)


@app.get("/api/ztl/zones/{zone_id}")
def legacy_get_rome_zone(zone_id: str, at: Optional[datetime] = None):
    return get_city_zone("rome", zone_id, at=at)


@app.get("/api/ztl/zones/{zone_id}/area")
def legacy_get_rome_zone_area(zone_id: str):
    return get_city_zone_area("rome", zone_id)


@app.get("/api/ztl/zones/{zone_id}/gates")
def legacy_get_rome_zone_gates(zone_id: str):
    return get_city_zone_gates("rome", zone_id)


@app.get("/api/ztl/status")
def legacy_get_rome_status(at: Optional[datetime] = None):
    return get_city_status("rome", at=at)


@app.get("/api/ztl/centro-notturna")
def legacy_centro_notturna(at: Optional[datetime] = None):
    return get_city_zone("rome", "centro-storico-notturna", at=at)


@app.get("/api/ztl/centro-notturna/area")
def legacy_centro_notturna_area():
    return get_city_zone_area("rome", "centro-storico-notturna")


@app.get("/api/ztl/centro-notturna/gates")
def legacy_centro_notturna_gates():
    return get_city_zone_gates("rome", "centro-storico-notturna")
