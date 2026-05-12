# Backend

## Setup

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
```

## Run

```bash
uvicorn app.main:app --reload
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

- Official schedules come from Roma Mobilità / Roma Capitale pages listed in `app/data/rome/zones.json`.
- Geometry is currently available only for `centro-storico-notturna`.
