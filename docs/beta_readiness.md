# Beta Readiness

## Supported zones

- Centro Storico diurna
- Centro Storico notturna
- Tridente A1
- Trastevere diurna
- Trastevere notturna
- San Lorenzo notturna
- Testaccio notturna

## Unsupported zones

- Zones outside the scope above
- Any zone without encoded official schedule data

## Source verification status

- Primary source: Roma Servizi per la Mobilità / Roma Mobilità
- Source URLs and `last_verified` dates stored in `backend/app/data/rome/zones.json`
- Verified in this repo update on 2026-05-12

## Test status

- Backend pytest coverage added for health, API, holidays, August suspension, and midnight-crossing windows
- Flutter tests added for parsing, API client behavior, dashboard/detail widgets, and missing geometry states
- Flutter tests could not be executed in this environment because Flutter is not installed locally

## Deployment status

- Backend Dockerfile added
- Local backend `docker-compose.yml` added
- CI workflow added for backend and frontend

## Privacy and security notes

- No authentication yet
- No user data storage in current app flow
- CORS defaults are strict in production unless explicitly configured

## Known limitations

- Only `centro-storico-notturna` has geometry in the repository today
- Frontend currently uses a custom painter fallback rather than a live basemap
- Electric/hydrogen notes can change quickly, especially around 2026-07-01
- Public beta users must still verify rules on Roma Mobilità before entering
