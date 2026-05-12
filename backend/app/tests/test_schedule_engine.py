from datetime import datetime
from zoneinfo import ZoneInfo

from app.services.schedule_engine import ScheduleEngine
from app.services.ztl_repository import ZtlRepository

rome = ZoneInfo("Europe/Rome")
repository = ZtlRepository()
engine = ScheduleEngine()


def _status(zone_id: str, iso_value: str):
    zone = repository.get_zone(zone_id)
    return engine.evaluate(zone, datetime.fromisoformat(iso_value))


def test_friday_2259_is_inactive_for_centro_night() -> None:
    status = _status("centro-storico-notturna", "2026-05-15T22:59:00+02:00")
    assert status.is_active is False


def test_friday_2300_is_active_for_centro_night() -> None:
    status = _status("centro-storico-notturna", "2026-05-15T23:00:00+02:00")
    assert status.is_active is True


def test_saturday_0259_is_active_for_centro_night() -> None:
    status = _status("centro-storico-notturna", "2026-05-16T02:59:00+02:00")
    assert status.is_active is True


def test_saturday_0300_is_inactive_for_centro_night() -> None:
    status = _status("centro-storico-notturna", "2026-05-16T03:00:00+02:00")
    assert status.is_active is False


def test_sunday_0200_belongs_to_saturday_window() -> None:
    status = _status("centro-storico-notturna", "2026-05-17T02:00:00+02:00")
    assert status.is_active is True


def test_august_suspension_disables_centro_night() -> None:
    status = _status("centro-storico-notturna", "2026-08-14T23:30:00+02:00")
    assert status.is_active is False
    assert "month" in status.reason.lower() or "season" in status.reason.lower()


def test_holiday_exclusion_disables_day_rule() -> None:
    status = _status("centro-storico-diurna", "2026-06-02T08:00:00+02:00")
    assert status.is_active is False


def test_timezone_aware_status_for_san_lorenzo_summer_rule() -> None:
    status = _status("san-lorenzo-notturna", "2026-05-13T22:00:00+02:00")
    assert status.is_active is True

