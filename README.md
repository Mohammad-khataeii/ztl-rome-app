# ZTL Rome App

Rome ZTL status app for public beta use. The backend serves validated Rome ZTL
zone data and schedule evaluation. The Flutter frontend shows whether a zone is
active now, when it changes next, the official source links, and geometry when
the repository has it.

Official rules may change. Always check Roma Mobilità before entering a ZTL.

## What it covers

Supported zones:

- Centro Storico diurna
- Centro Storico notturna
- Tridente A1
- Trastevere diurna
- Trastevere notturna
- San Lorenzo notturna
- Testaccio notturna

Current geometry support:

- `centro-storico-notturna`: boundary and gates available
- other supported zones: schedule/source support is present, geometry may be unavailable

## Repository layout

- `backend/`
- `frontend/`
- `docs/beta_readiness.md`

## Environment

Copy `.env.example` and adjust it for your deployment.

Backend env vars:

- `APP_ENV`
- `API_TITLE`
- `LOG_LEVEL`
- `ALLOWED_ORIGINS`

Frontend build-time config:

- `ZTL_API_BASE_URL`

## Backend setup

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
uvicorn app.main:app --reload
```

## Frontend setup

```bash
cd frontend
flutter pub get
flutter run --dart-define=ZTL_API_BASE_URL=http://127.0.0.1:8000
```

Chrome:

```bash
flutter run -d chrome --dart-define=ZTL_API_BASE_URL=http://127.0.0.1:8000
```

Android emulator:

```bash
flutter run --dart-define=ZTL_API_BASE_URL=http://10.0.2.2:8000
```

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
flutter test
flutter analyze
flutter build web --dart-define=ZTL_API_BASE_URL=http://localhost:8000
```

## Deployment outline

Backend:

- build `backend/Dockerfile`
- run with `uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 2`
- set `APP_ENV=production`
- set explicit `ALLOWED_ORIGINS`

Frontend:

- build static web assets with `flutter build web --dart-define=ZTL_API_BASE_URL=https://api.example.com`
- host behind nginx, CDN, or static hosting
- do not ship production builds without `ZTL_API_BASE_URL`

## Official source disclaimer

Source links and last-verified dates are stored in
`backend/app/data/rome/zones.json`.
Roma Mobilità and Roma Capitale remain the source of truth.

## Known limitations

- Only one zone currently has geometry in the repository.
- The Flutter toolchain is not installed in this local environment, so Flutter checks must be run on a machine with Flutter available.
