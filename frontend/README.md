# ZTL Rome

Flutter client for the Rome ZTL dashboard. It connects to the FastAPI backend in
`../backend` and displays the Centro Storico night boundary, access gates, and a
simple active-now status.

## Run locally

Start the backend:

```bash
cd ../backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
```

Start the Flutter app:

```bash
flutter pub get
flutter run
```

The app defaults to `http://127.0.0.1:8000`. If you run Android emulator builds,
use `http://10.0.2.2:8000` in the Backend URL field.
