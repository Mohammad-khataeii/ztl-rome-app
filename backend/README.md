# Backend

FastAPI backend for the multi-city ZTL Italy app. It serves city metadata,
zone schedules, current-status evaluation, official sources, and merged map
bundles for Rome, Milan, and Florence.

## Setup

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
```

## Run

```bash
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

## Test

```bash
pytest
ruff check .
```

## Environment

Copy `../.env.example` and set:

- `APP_ENV`
- `API_TITLE`
- `LOG_LEVEL`
- `ALLOWED_ORIGINS`

## Notes

- Main city endpoints:
  - `/api/cities`
  - `/api/cities/{city_id}/ztl/zones`
  - `/api/cities/{city_id}/ztl/status`
  - `/api/cities/{city_id}/ztl/map`
- Legacy Rome endpoints under `/api/ztl/...` still work.
- Official schedules come from the city datasets in `app/data/rome/zones.json`,
  `app/data/milan/zones.json`, and `app/data/florence/zones.json`.
- Geometry is currently bundled only for Rome `centro-storico-notturna`.
