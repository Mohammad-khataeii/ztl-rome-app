# ZTL Italy

ZTL Italy is a multi-city limited-traffic-zone app with a FastAPI backend and a
Flutter frontend. It currently supports Rome, Milan, and Florence with official
schedule metadata, current-status evaluation, source links, and map-first UI
behavior where geometry is available.

Official rules may change. Always check the official city mobility source
before entering a ZTL.

## Supported cities

- Rome: partial map support
- Milan: schedule support, geometry pending
- Florence: schedule support, geometry pending

## Geometry status

- Rome:
  `centro-storico-notturna` boundary and gates are available in the repo.
- Milan:
  no verified official geometry is bundled yet.
- Florence:
  no verified official geometry is bundled yet.

The app does not invent boundaries or gates. Missing geometry is shown as
unavailable in the product.

## Repository layout

- `backend/` FastAPI API, schedule engine, validated datasets
- `frontend/` Flutter app
- `docs/beta_readiness.md` beta scope and known limitations

## Backend setup

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

Useful endpoints:

- `/api/health`
- `/api/cities`
- `/api/cities/rome/ztl/map`
- `/api/cities/milan/ztl/zones`
- `/api/cities/florence/ztl/zones`
- `/api/ztl/zones` legacy Rome compatibility

## Frontend setup

```bash
cd frontend
flutter pub get
```

Chrome:

```bash
flutter run -d chrome --web-port=3000 --dart-define=ZTL_API_BASE_URL=http://127.0.0.1:8000
```

Android emulator:

```bash
flutter run --dart-define=ZTL_API_BASE_URL=http://10.0.2.2:8000
```

Web build:

```bash
flutter build web --dart-define=ZTL_API_BASE_URL=https://example.com
```

## Environment

Copy `.env.example` and set backend env vars:

- `APP_ENV`
- `API_TITLE`
- `LOG_LEVEL`
- `ALLOWED_ORIGINS`

Frontend build-time config:

- `ZTL_API_BASE_URL`

In debug mode, the Flutter app falls back to `http://127.0.0.1:8000` if no
base URL is provided. Non-debug builds require `ZTL_API_BASE_URL`.

## Tests

Backend:

```bash
cd backend
source .venv/bin/activate
pytest
ruff check .
```

Frontend:

```bash
cd frontend
flutter analyze
flutter test
flutter build web --dart-define=ZTL_API_BASE_URL=https://example.com
```

## Production deployment outline

Backend:

- build from `backend/Dockerfile`
- run `uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 2`
- set `APP_ENV=production`
- set explicit `ALLOWED_ORIGINS`

Frontend:

- build static assets with `flutter build web --dart-define=ZTL_API_BASE_URL=https://api.example.com`
- host on nginx, CDN, or static hosting
- do not ship a production build without a valid API URL

## Official sources

Primary sources currently encoded in the datasets:

- Rome: Roma Mobilita / Roma Capitale pages in `backend/app/data/rome/zones.json`
- Milan: Comune di Milano Area C / Area B pages in `backend/app/data/milan/zones.json`
- Florence: Comune di Firenze mobility ZTL page in `backend/app/data/florence/zones.json`

Each city and zone includes official source URLs and `last_verified` metadata in
the backend dataset.

## Known limitations

- Only one Rome zone currently has bundled geometry.
- Milan and Florence are schedule-first until verified geometry is added.
- Flutter checks require a machine with Flutter installed.
