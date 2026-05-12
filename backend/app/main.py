from __future__ import annotations

import logging
from datetime import datetime
from typing import Optional

from fastapi import FastAPI
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import get_settings
from app.models import ZoneDefinition
from app.schemas import ErrorResponse, HealthResponse, StatusEnvelope, ZonesEnvelope
from app.services.schedule_engine import ScheduleEngine
from app.services.ztl_repository import ZtlRepository

settings = get_settings()
logging.basicConfig(level=getattr(logging, settings.log_level.upper(), logging.INFO))
logger = logging.getLogger("ztl-rome-api")

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


def _zone_response(zone: ZoneDefinition, checked_at: datetime) -> dict:
    status = schedule_engine.evaluate(zone, checked_at)
    bounds = repository.get_bounds(zone.id)
    return {
        "id": zone.id,
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
        "geometry": {
            "hasArea": bool(zone.geometry.area_file),
            "hasGates": bool(zone.geometry.gates_file),
            "areaEndpoint": (
                f"/api/ztl/zones/{zone.id}/area" if zone.geometry.area_file else None
            ),
            "gatesEndpoint": (
                f"/api/ztl/zones/{zone.id}/gates" if zone.geometry.gates_file else None
            ),
            "bounds": bounds,
        },
        "sources": [
            {
                "title": source.title,
                "url": str(source.url),
                "publisher": source.publisher,
                "lastVerified": source.last_verified.isoformat(),
            }
            for source in zone.sources
        ],
        "disclaimer": zone.disclaimer,
    }


def _cacheable_json(content: dict, max_age: int = 300) -> JSONResponse:
    response = JSONResponse(content=jsonable_encoder(content))
    response.headers["Cache-Control"] = f"public, max-age={max_age}"
    return response


@app.get("/api/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(status="ok", env=settings.app_env, version=settings.app_version)


@app.get("/api/ztl/zones", response_model=ZonesEnvelope)
def list_zones(at: Optional[datetime] = None):
    checked_at = at or datetime.now()
    zones = [_zone_response(zone, checked_at) for zone in repository.list_zones()]
    return _cacheable_json({"zones": zones}, max_age=300)


@app.get("/api/ztl/zones/{zone_id}")
def get_zone(zone_id: str, at: Optional[datetime] = None):
    checked_at = at or datetime.now()
    zone = repository.get_zone(zone_id)
    return _cacheable_json(_zone_response(zone, checked_at), max_age=300)


@app.get("/api/ztl/zones/{zone_id}/area")
def get_zone_area(zone_id: str):
    return _cacheable_json(repository.get_area_geojson(zone_id), max_age=3600)


@app.get("/api/ztl/zones/{zone_id}/gates")
def get_zone_gates(zone_id: str):
    return _cacheable_json(repository.get_gates_geojson(zone_id), max_age=3600)


@app.get("/api/ztl/status", response_model=StatusEnvelope)
def get_status(at: Optional[datetime] = None):
    checked_at = at or datetime.now()
    zones = [_zone_response(zone, checked_at) for zone in repository.list_zones()]
    return _cacheable_json({"checkedAt": checked_at.isoformat(), "zones": zones}, max_age=120)


@app.get("/api/ztl/sources")
def get_sources():
    sources = [
        {
            "title": source.title,
            "url": str(source.url),
            "publisher": source.publisher,
            "lastVerified": source.last_verified.isoformat(),
        }
        for source in repository.list_sources()
    ]
    return _cacheable_json({"sources": sources}, max_age=3600)


# Backward-compatible MVP endpoints.
@app.get("/api/ztl/centro-notturna")
def legacy_centro_notturna(at: Optional[datetime] = None):
    return get_zone("centro-storico-notturna", at=at)


@app.get("/api/ztl/centro-notturna/area")
def legacy_centro_notturna_area():
    return get_zone_area("centro-storico-notturna")


@app.get("/api/ztl/centro-notturna/gates")
def legacy_centro_notturna_gates():
    return get_zone_gates("centro-storico-notturna")
