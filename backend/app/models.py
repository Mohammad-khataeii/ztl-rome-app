from __future__ import annotations

from datetime import date, time
from typing import List, Literal, Optional

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    HttpUrl,
    field_validator,
    model_validator,
)

ZoneType = Literal[
    "daytime",
    "nighttime",
    "environmental",
    "logistics",
    "tourist_bus",
    "unknown",
]
Confidence = Literal["official", "derived", "missing_data"]
HolidayPolicy = Literal["exclude", "include"]


class SourceReference(BaseModel):
    model_config = ConfigDict(extra="forbid")

    title: str
    url: HttpUrl
    publisher: str
    last_verified: date


class DateOverride(BaseModel):
    model_config = ConfigDict(extra="forbid")

    date: date
    is_active: bool
    reason: str


class ScheduleRule(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    label_it: str
    label_en: str
    weekdays: List[int] = Field(description="0=Monday ... 6=Sunday")
    start_time: time
    end_time: time
    holiday_policy: HolidayPolicy = "include"
    active_months: Optional[List[int]] = None
    excluded_months: List[int] = Field(default_factory=list)
    source_titles: List[str] = Field(default_factory=list)

    @field_validator("weekdays")
    @classmethod
    def validate_weekdays(cls, value: List[int]) -> List[int]:
        if not value:
            raise ValueError("weekdays must not be empty")
        if any(day < 0 or day > 6 for day in value):
            raise ValueError("weekday values must be in range 0..6")
        return value

    @field_validator("active_months")
    @classmethod
    def validate_active_months(cls, value: Optional[List[int]]) -> Optional[List[int]]:
        if value is None:
            return value
        if not value:
            raise ValueError("active_months must not be empty when provided")
        if any(month < 1 or month > 12 for month in value):
            raise ValueError("month values must be in range 1..12")
        return value

    @field_validator("excluded_months")
    @classmethod
    def validate_excluded_months(cls, value: List[int]) -> List[int]:
        if any(month < 1 or month > 12 for month in value):
            raise ValueError("month values must be in range 1..12")
        return value


class Restrictions(BaseModel):
    model_config = ConfigDict(extra="forbid")

    vehicle_classes: List[str]
    known_exemptions: List[str]
    disabled_permit_note: str
    electric_vehicle_note: str
    motorcycles_note: str


class GeometryReference(BaseModel):
    model_config = ConfigDict(extra="forbid")

    area_file: Optional[str] = None
    gates_file: Optional[str] = None


class ZoneDefinition(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    name: str
    city: str
    type: ZoneType
    timezone: str
    human_readable_it: str
    human_readable_en: str
    rules: List[ScheduleRule]
    exclusions: List[str]
    restrictions: Restrictions
    geometry: GeometryReference = Field(default_factory=GeometryReference)
    sources: List[SourceReference]
    disclaimer: str
    overrides: List[DateOverride] = Field(default_factory=list)
    confidence: Confidence = "official"

    @model_validator(mode="after")
    def validate_source_titles(self) -> "ZoneDefinition":
        source_titles = {source.title for source in self.sources}
        for rule in self.rules:
            missing = [title for title in rule.source_titles if title not in source_titles]
            if missing:
                raise ValueError(
                    f"Rule {rule.id} references missing source titles: {', '.join(missing)}"
                )
        return self


class ZoneDataset(BaseModel):
    model_config = ConfigDict(extra="forbid")

    zones: List[ZoneDefinition]
