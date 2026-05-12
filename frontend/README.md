# Frontend

The Flutter app is now map-first and city-based. Rome, Milan, and Florence are
available in the city selector. The main screen loads a city map bundle from
the backend, draws any available ZTL areas and gates, and shows a missing
geometry panel when official geometry is not bundled yet.

## Setup

```bash
cd frontend
flutter pub get
```

## Run

Chrome with local backend:

```bash
flutter run -d chrome --web-port=3000 --dart-define=ZTL_API_BASE_URL=http://127.0.0.1:8000
```

Android emulator with local backend:

```bash
flutter run --dart-define=ZTL_API_BASE_URL=http://10.0.2.2:8000
```

Production-style web build:

```bash
flutter build web --dart-define=ZTL_API_BASE_URL=https://api.example.com
```

## Quality checks

```bash
flutter analyze
flutter test
flutter build web --dart-define=ZTL_API_BASE_URL=https://example.com
```

## Notes

- The visible backend URL editor was removed from the normal UI.
- In debug mode only, the app falls back to `http://127.0.0.1:8000` when no
  `ZTL_API_BASE_URL` is provided.
- Release builds require `ZTL_API_BASE_URL`.
- Official rules may change. Users should check the official city source before
  entering.
