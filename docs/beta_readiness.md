# Beta Readiness

## Supported cities

- Rome
- Milan
- Florence

## Supported zones

Rome:

- Centro Storico diurna
- Centro Storico notturna
- Tridente A1
- Trastevere diurna
- Trastevere notturna
- San Lorenzo notturna
- Testaccio notturna

Milan:

- Area C
- Area B

Florence:

- Sector A
- Sector B
- Sector O
- Sector F
- Sector G
- Summer night ZTL

## Geometry support

- Rome: partial geometry
  - `centro-storico-notturna` area and gates available
  - all other Rome zones are schedule/source support only
- Milan: schedule support only, geometry pending verified official data
- Florence: schedule support only, geometry pending verified official data

## Unsupported or incomplete

- Cities outside Rome, Milan, and Florence
- Any geometry not verified from official or acceptable open data sources
- Turn-by-turn routing or vehicle eligibility decisions

## Source verification status

- Rome:
  official Roma Mobilita / Roma Capitale pages encoded in
  `backend/app/data/rome/zones.json`
- Milan:
  official Comune di Milano Area C / Area B pages encoded in
  `backend/app/data/milan/zones.json`
- Florence:
  official Comune di Firenze mobility ZTL page encoded in
  `backend/app/data/florence/zones.json`

All supported cities and zones include source URLs and `last_verified`
metadata. Verified for this repo update on 2026-05-12.

## Test status

- Backend:
  pytest coverage includes city endpoints, legacy Rome compatibility, Rome /
  Milan / Florence schedule rules, cross-midnight windows, August suspension,
  holiday exclusion, malformed data validation, and source metadata checks
- Frontend:
  parsing, API, and widget tests were updated for the city selector and
  map-first flow
- Flutter tests could not be executed in this local environment because Flutter
  is not installed on `PATH`

## Deployment status

- Backend Dockerfile present
- Local `docker-compose.yml` present for backend
- GitHub Actions CI runs backend lint/tests and frontend pub get / analyze /
  test / web build

## Privacy and security notes

- No authentication yet
- No user account or personal data flow in the current app
- CORS defaults are strict in production unless explicitly configured
- API errors are returned as structured responses without Python stack traces

## Known limitations

- The frontend cannot yet display verified Milan or Florence geometry because
  none is bundled.
- Map fitting is only as strong as the available geometry data.
- Tile availability depends on network access to the configured map tile
  provider.
- Users must still verify official rules before entering any ZTL.

## Before public release

- Re-run `flutter analyze`, `flutter test`, and `flutter build web` on a
  machine with Flutter installed
- Add verified geometry for more Rome zones, Milan, and Florence if official or
  acceptable open data becomes available
- Re-verify all city sources and `last_verified` dates close to deployment
- Set production `ALLOWED_ORIGINS` and production `ZTL_API_BASE_URL`
