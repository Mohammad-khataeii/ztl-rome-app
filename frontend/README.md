# Frontend

## Setup

```bash
cd frontend
flutter pub get
```

## Run

Local backend:

```bash
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

Production-style example:

```bash
flutter build web --dart-define=ZTL_API_BASE_URL=https://api.example.com
```

## Quality checks

```bash
flutter analyze
flutter test
flutter build web --dart-define=ZTL_API_BASE_URL=http://localhost:8000
```

## Notes

- The app does not show a backend URL editor in normal UI.
- In debug mode only, the app falls back to `http://127.0.0.1:8000` when no `ZTL_API_BASE_URL` is provided.
- Release builds require `ZTL_API_BASE_URL`.
