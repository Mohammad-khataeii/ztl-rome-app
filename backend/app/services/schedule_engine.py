from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime, time, timedelta
from typing import Optional, Sequence, Tuple
from zoneinfo import ZoneInfo

from app.models import DateOverride, ScheduleRule, SeasonBoundary, ZoneDefinition
from app.services.holiday_calendar import ItalyHolidayCalendar


@dataclass(frozen=True)
class EvaluatedStatus:
    is_active: bool
    checked_at: datetime
    reason: str
    next_change_at: Optional[datetime]
    confidence: str


class ScheduleEngine:
    def evaluate(self, zone: ZoneDefinition, at: datetime) -> EvaluatedStatus:
        local_at = self._normalize_datetime(zone, at)
        override_status = self._evaluate_overrides(zone.overrides, local_at)
        if override_status is not None:
            return EvaluatedStatus(
                is_active=override_status[0],
                checked_at=local_at,
                reason=override_status[1],
                next_change_at=self._next_change(zone, local_at),
                confidence=zone.confidence,
            )

        for rule in zone.rules:
            if self._rule_matches(rule, local_at):
                return EvaluatedStatus(
                    is_active=True,
                    checked_at=local_at,
                    reason=rule.label_en,
                    next_change_at=self._next_change(zone, local_at),
                    confidence=zone.confidence,
                )

        return EvaluatedStatus(
            is_active=False,
            checked_at=local_at,
            reason=self._inactive_reason(zone, local_at),
            next_change_at=self._next_change(zone, local_at),
            confidence=zone.confidence,
        )

    def _inactive_reason(self, zone: ZoneDefinition, at: datetime) -> str:
        for rule in zone.rules:
            start_date = self._candidate_start_date(rule, at)
            if start_date is None:
                continue
            if not self._season_allowed(rule, start_date):
                return "Inactive this season."
            if rule.holiday_policy == "exclude" and ItalyHolidayCalendar.is_public_holiday(
                start_date
            ):
                return "Inactive on Italian public holidays."
            if start_date.month in rule.excluded_months:
                return "Inactive this month."
            if rule.active_months is not None and start_date.month not in rule.active_months:
                return "Inactive this month."
        return "Outside scheduled hours."

    def _candidate_start_date(self, rule: ScheduleRule, at: datetime) -> Optional[date]:
        if self._crosses_midnight(rule.start_time, rule.end_time) and at.time() < rule.end_time:
            start_date = at.date() - timedelta(days=1)
        else:
            start_date = at.date()
        if start_date.weekday() not in rule.weekdays:
            return None
        return start_date

    def _rule_matches(self, rule: ScheduleRule, at: datetime) -> bool:
        if self._crosses_midnight(rule.start_time, rule.end_time):
            return self._matches_cross_midnight(rule, at)
        return self._matches_same_day(rule, at)

    def _matches_same_day(self, rule: ScheduleRule, at: datetime) -> bool:
        start_date = at.date()
        if start_date.weekday() not in rule.weekdays:
            return False
        if not self._date_allowed(rule, start_date):
            return False
        return rule.start_time <= at.time() < rule.end_time

    def _matches_cross_midnight(self, rule: ScheduleRule, at: datetime) -> bool:
        candidates = (at.date(), at.date() - timedelta(days=1))
        for candidate in candidates:
            if candidate.weekday() not in rule.weekdays:
                continue
            if not self._date_allowed(rule, candidate):
                continue
            start_dt, end_dt = self._window_for_date(
                at.tzinfo,
                candidate,
                rule.start_time,
                rule.end_time,
            )
            if start_dt <= at < end_dt:
                return True
        return False

    def _date_allowed(self, rule: ScheduleRule, start_date: date) -> bool:
        if not self._season_allowed(rule, start_date):
            return False
        if rule.active_months is not None and start_date.month not in rule.active_months:
            return False
        if start_date.month in rule.excluded_months:
            return False
        if rule.holiday_policy == "exclude" and ItalyHolidayCalendar.is_public_holiday(start_date):
            return False
        return True

    def _season_allowed(self, rule: ScheduleRule, start_date: date) -> bool:
        if rule.season is None:
            return True
        year = start_date.year
        season_start = self._season_boundary_date(year, rule.season.start)
        season_end = self._season_boundary_date(year, rule.season.end)
        return season_start <= start_date <= season_end

    def _season_boundary_date(self, year: int, boundary: SeasonBoundary) -> date:
        first_of_month = date(year, boundary.month, 1)
        offset = (boundary.weekday - first_of_month.weekday()) % 7
        day = 1 + offset + (boundary.nth_week - 1) * 7
        return date(year, boundary.month, day)

    def _evaluate_overrides(
        self,
        overrides: Sequence[DateOverride],
        at: datetime,
    ) -> Optional[Tuple[bool, str]]:
        for override in overrides:
            if override.date == at.date():
                return override.is_active, override.reason
        return None

    def _next_change(self, zone: ZoneDefinition, at: datetime) -> Optional[datetime]:
        boundaries = []
        start_date = at.date() - timedelta(days=1)
        for day_offset in range(0, 400):
            current_date = start_date + timedelta(days=day_offset)
            for rule in zone.rules:
                if current_date.weekday() not in rule.weekdays:
                    continue
                if not self._date_allowed(rule, current_date):
                    continue
                start_dt, end_dt = self._window_for_date(
                    at.tzinfo,
                    current_date,
                    rule.start_time,
                    rule.end_time,
                )
                boundaries.extend([start_dt, end_dt])
        for boundary in sorted({boundary for boundary in boundaries if boundary > at}):
            before = boundary - timedelta(seconds=1)
            if self._is_active_without_next(zone, before) != self._is_active_without_next(
                zone,
                boundary,
            ):
                return boundary
        return None

    def _is_active_without_next(self, zone: ZoneDefinition, at: datetime) -> bool:
        override_status = self._evaluate_overrides(zone.overrides, at)
        if override_status is not None:
            return override_status[0]
        return any(self._rule_matches(rule, at) for rule in zone.rules)

    @staticmethod
    def _window_for_date(
        tzinfo: Optional[ZoneInfo],
        start_date: date,
        start_time: time,
        end_time: time,
    ) -> Tuple[datetime, datetime]:
        start_dt = datetime.combine(start_date, start_time, tzinfo=tzinfo)
        end_date = start_date if end_time > start_time else start_date + timedelta(days=1)
        end_dt = datetime.combine(end_date, end_time, tzinfo=tzinfo)
        return start_dt, end_dt

    @staticmethod
    def _crosses_midnight(start_time: time, end_time: time) -> bool:
        return end_time <= start_time

    @staticmethod
    def _normalize_datetime(zone: ZoneDefinition, value: datetime) -> datetime:
        timezone = ZoneInfo(zone.timezone)
        if value.tzinfo is None:
            return value.replace(tzinfo=timezone)
        return value.astimezone(timezone)
