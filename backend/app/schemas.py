from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, ConfigDict, HttpUrl

from app.models import Confidence, SourceReference, ZoneType


class ErrorResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    detail: str


class ZoneStatus(BaseModel):
    model_config = ConfigDict(extra="forbid")

    isActive: bool
    checkedAt: datetime
    reason: str
    nextChangeAt: Optional[datetime]
    confidence: Confidence


class ScheduleRuleResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    labelIt: str
    labelEn: str
    weekdays: List[int]
    startTime: str
    endTime: str
    holidayPolicy: str
    activeMonths: Optional[List[int]]
    excludedMonths: List[int]
    sourceTitles: List[str]


class ScheduleResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    humanReadableIt: str
    humanReadableEn: str
    rules: List[ScheduleRuleResponse]
    exclusions: List[str]


class RestrictionsResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    vehicleClasses: List[str]
    knownExemptions: List[str]
    disabledPermitNote: str
    electricVehicleNote: str
    motorcyclesCiclomotoriNote: str


class GeometryResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    hasArea: bool
    hasGates: bool
    areaEndpoint: Optional[str]
    gatesEndpoint: Optional[str]
    bounds: Optional[Dict[str, float]]


class SourceResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    title: str
    url: HttpUrl
    publisher: str
    lastVerified: str


class ZoneResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    name: str
    city: str
    type: ZoneType
    timezone: str
    currentStatus: ZoneStatus
    schedule: ScheduleResponse
    restrictions: RestrictionsResponse
    geometry: GeometryResponse
    sources: List[SourceResponse]
    disclaimer: str


class HealthResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    status: str
    env: str
    version: str


class ZonesEnvelope(BaseModel):
    model_config = ConfigDict(extra="forbid")

    zones: List[ZoneResponse]


class StatusEnvelope(BaseModel):
    model_config = ConfigDict(extra="forbid")

    checkedAt: datetime
    zones: List[ZoneResponse]


class SourcesEnvelope(BaseModel):
    model_config = ConfigDict(extra="forbid")

    sources: List[SourceReference]


class GeoJsonResponse(BaseModel):
    model_config = ConfigDict(extra="allow")

    type: str
    features: List[Dict[str, Any]]

