import os
from dataclasses import dataclass
from functools import lru_cache
from typing import List

APP_VERSION = "0.2.0-beta"
DEFAULT_DEV_ORIGINS = [
    "http://127.0.0.1:8000",
    "http://localhost:8000",
    "http://127.0.0.1:3000",
    "http://localhost:3000",
    "http://127.0.0.1:8080",
    "http://localhost:8080",
]


@dataclass(frozen=True)
class Settings:
    app_env: str
    api_title: str
    log_level: str
    allowed_origins: List[str]
    app_version: str = APP_VERSION

    @property
    def is_production(self) -> bool:
        return self.app_env.lower() == "production"


def _parse_allowed_origins(raw_value: str, app_env: str) -> List[str]:
    if raw_value.strip():
        return [origin.strip() for origin in raw_value.split(",") if origin.strip()]
    if app_env.lower() == "development":
        return DEFAULT_DEV_ORIGINS
    return []


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    app_env = os.getenv("APP_ENV", "development")
    return Settings(
        app_env=app_env,
        api_title=os.getenv("API_TITLE", "ZTL Rome API"),
        log_level=os.getenv("LOG_LEVEL", "INFO"),
        allowed_origins=_parse_allowed_origins(
            os.getenv("ALLOWED_ORIGINS", ""),
            app_env,
        ),
    )
