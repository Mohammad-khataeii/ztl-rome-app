from __future__ import annotations

from datetime import date, timedelta
from functools import lru_cache
from typing import Set


class ItalyHolidayCalendar:
    FIXED_HOLIDAYS = {
        (1, 1),
        (1, 6),
        (4, 25),
        (5, 1),
        (6, 2),
        (8, 15),
        (11, 1),
        (12, 8),
        (12, 25),
        (12, 26),
    }

    @classmethod
    @lru_cache(maxsize=64)
    def holidays_for_year(cls, year: int) -> Set[date]:
        holidays = {date(year, month, day) for month, day in cls.FIXED_HOLIDAYS}
        easter_sunday = cls._easter_sunday(year)
        holidays.add(easter_sunday)
        holidays.add(easter_sunday + timedelta(days=1))
        return holidays

    @classmethod
    def is_public_holiday(cls, value: date) -> bool:
        return value in cls.holidays_for_year(value.year)

    @staticmethod
    def _easter_sunday(year: int) -> date:
        """Anonymous Gregorian algorithm."""
        a = year % 19
        b = year // 100
        c = year % 100
        d = b // 4
        e = b % 4
        f = (b + 8) // 25
        g = (b - f + 1) // 3
        h = (19 * a + b - d - g + 15) % 30
        i = c // 4
        k = c % 4
        offset = (32 + 2 * e + 2 * i - h - k) % 7
        m = (a + 11 * h + 22 * offset) // 451
        month = (h + offset - 7 * m + 114) // 31
        day = ((h + offset - 7 * m + 114) % 31) + 1
        return date(year, month, day)
