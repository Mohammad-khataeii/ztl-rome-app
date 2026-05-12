from datetime import datetime

from app.services.schedule_engine import ScheduleEngine
from app.services.ztl_repository import ZtlRepository

repository = ZtlRepository()
engine = ScheduleEngine()


def _status(city_id: str, zone_id: str, iso_value: str):
    zone = repository.get_zone(city_id, zone_id)
    return engine.evaluate(zone, datetime.fromisoformat(iso_value))


def test_rome_centro_notturna_friday_2300_is_active() -> None:
    assert _status("rome", "centro-storico-notturna", "2026-05-15T23:00:00+02:00").is_active


def test_rome_centro_notturna_august_suspension() -> None:
    assert not _status(
        "rome",
        "centro-storico-notturna",
        "2026-08-14T23:30:00+02:00",
    ).is_active


def test_milan_area_c_monday_0800_is_active() -> None:
    assert _status("milan", "milan-area-c", "2026-05-11T08:00:00+02:00").is_active


def test_milan_area_c_monday_2000_is_inactive() -> None:
    assert not _status("milan", "milan-area-c", "2026-05-11T20:00:00+02:00").is_active


def test_milan_area_c_holiday_is_inactive() -> None:
    assert not _status("milan", "milan-area-c", "2026-06-02T08:00:00+02:00").is_active


def test_milan_area_b_monday_0800_is_active() -> None:
    assert _status("milan", "milan-area-b", "2026-05-11T08:00:00+02:00").is_active


def test_florence_sector_a_friday_0800_is_active() -> None:
    assert _status("florence", "florence-sector-a", "2026-05-15T08:00:00+02:00").is_active


def test_florence_sector_a_friday_2100_is_inactive() -> None:
    assert not _status(
        "florence",
        "florence-sector-a",
        "2026-05-15T21:00:00+02:00",
    ).is_active


def test_florence_summer_night_thursday_2330_is_active() -> None:
    assert _status(
        "florence",
        "florence-summer-night-ztl",
        "2026-05-14T23:30:00+02:00",
    ).is_active


def test_florence_cross_midnight_friday_0230_is_active_from_thursday() -> None:
    assert _status(
        "florence",
        "florence-summer-night-ztl",
        "2026-05-15T02:30:00+02:00",
    ).is_active
