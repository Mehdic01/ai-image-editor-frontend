# AI Image Editor — Flutter Web Frontend

This is a Flutter Web frontend for an AI-powered image editing app. Users upload an image, describe how they want it edited, and receive a processed result once the backend job finishes. The app is deployed on Firebase Hosting and communicates with a backend hosted on Render.

Live: https://ai-image-editor-web-app.web.app

## Tech stack
- Flutter 3 (Web)
- Firebase Hosting (static hosting + Service Worker caching)
- Backend API (Render) — configurable via `API_BASE_URL`
- Packages: `http`, `file_picker`, `equatable`

## Project structure
Key folders/files:
- `lib/`
	- `main.dart` — App entry; sets up `MaterialApp` and loads `HomeView`.
	- `ui/views/home_view.dart` — Main screen: upload image, enter prompt, see before/after slider, download.
	- `ui/widgets/` — Reusable UI: `JobsSidebar`, `PromptComposer`, `BeforeAfter`, `LoadingOverlay`.
	- `data/repo/api_client.dart` — HTTP client. Defines `apiBase` from `API_BASE_URL`.
	- `data/repo/jobs_repository.dart` — High-level API calls (create/list/get/delete/retry jobs).
	- `data/entity/job.dart` — Data models (`Job`, `JobListItem`).
- `assets/icons/` — UI icons and backgrounds used by the app.
- `web/` — Flutter web shell (index, manifest, icons). Served through `build/web` after build.
- `firebase.json` — Hosting configuration (public dir, cache headers, SPA rewrites).

## How it works (flow)
1. User uploads an image and enters a prompt.
2. Frontend calls backend `POST /api/jobs` (multipart) with the image and prompt.
3. The app polls `GET /api/jobs/{id}` until `status` becomes `done` or `error`.
4. When done, the result image URL is shown, and the user can download it.
5. The sidebar lists jobs (`GET /api/jobs`) and allows deletion (`DELETE /api/jobs/{id}`) or retry (`POST /api/jobs/{id}/retry`).

Endpoints used (from `lib/data/repo/jobs_repository.dart`):
- `POST /api/jobs` — create job (multipart: fields: `prompt`, file field: `image`)
- `GET /api/jobs` — list jobs
- `GET /api/jobs/{id}` — get job status/details
- `DELETE /api/jobs/{id}` — delete job
- `POST /api/jobs/{id}/retry` — retry job
- `GET /api/jobs/{id}/download` — construct-only helper to download result

## Configuration

### API base URL
The frontend uses an environment value to determine the backend API base.

File: `lib/data/repo/api_client.dart`
```
const String apiBase = String.fromEnvironment(
	'API_BASE_URL',
	defaultValue: 'https://ai-image-editor-backend.onrender.com',
);
```

You can override it at build time:

```powershell
# Windows PowerShell
flutter build web --release --dart-define API_BASE_URL=https://your-backend.onrender.com
```

Or for local runs:

```powershell
flutter run -d chrome --web-port 5000 --dart-define API_BASE_URL=http://localhost:8000
```

### CORS / ALLOWED_ORIGINS (backend on Render)
Set your backend’s allowed origins to the frontend origins you use:
- Production: `https://ai-image-editor-web-app.web.app`
- Optional: `https://ai-image-editor-web-app.firebaseapp.com`
- Local (example): `http://localhost:5000`

Notes:
- Origins must include scheme and (if any) port, no trailing slash (e.g., `http://localhost:5000`).
- Restart/deploy your Render service after changing env vars.

## Local development
Prereqs:
- Flutter SDK 3.x installed

Install deps and run:

```powershell
flutter pub get
flutter run -d chrome --web-port 5000 --dart-define API_BASE_URL=http://localhost:8000
```

Tips:
- Keep a fixed `--web-port` (e.g., 5000) so the origin stays constant for CORS.
- If you change assets under `assets/icons/`, update `pubspec.yaml` or include the whole folder (see below), then run `flutter pub get` and rebuild.


## Build

Release build for web:

```powershell
flutter pub get
flutter build web --release --dart-define API_BASE_URL=https://ai-image-editor-backend.onrender.com
```

Output will be under `build/web`.

## Deploy (Firebase Hosting)

Configuration: `firebase.json`

- `public: build/web` — deploys Flutter’s web output
- Long-term caching for static assets (immutable hashed files)
- SPA rewrite to `/index.html`

Deploy commands:

```powershell
flutter build web --release --dart-define API_BASE_URL=https://ai-image-editor-backend.onrender.com
firebase deploy --only hosting
```

GitHub Actions templates are present under `.github/workflows/` for PR/merge deploys (adjust as needed).

## Troubleshooting

- Images/icons don’t appear on web:
	- Make sure asset paths in code match `pubspec.yaml` (e.g., `assets/icons/...`).
	- Rebuild after asset changes. Hard refresh twice (service worker caches aggressively).

- CORS errors when calling backend:
	- Verify `API_BASE_URL` is correct at build time.
	- Add the frontend origin(s) to backend `ALLOWED_ORIGINS` (Render env) and redeploy.

- Service Worker caching issues (stale UI after deploy):
	- Hard refresh twice or open in incognito.
	- You can also bump the app version by rebuilding; Flutter updates `version.json`/service worker hashes automatically.

- File picker not opening or uploads failing:
	- Ensure browser permissions are OK and that backend accepts `multipart/form-data` with field name `image`.



