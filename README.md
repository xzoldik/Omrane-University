# Omrane University

Full-stack monorepo for a simple University Management System:

- Backend: Node.js/Express REST API with session auth and JSON file storage
- Frontend: Flutter app (mobile, web, and desktop) using Dio with cookie-based sessions


## Repository structure

```
Omrane-University/
├─ OmraneBackend/       # Node/Express API + JSON storage
└─ omranefront/         # Flutter application
```


## Prerequisites

- Node.js 18+ and npm
- Flutter SDK (3.22+ recommended), plus:
  - Android Studio / SDK for Android
  - Xcode for iOS (macOS only)
  - Chrome for Web
  - Windows desktop tooling (on Windows)


## Quick start (Windows PowerShell)

Open two terminals: one for the backend and one for the Flutter app.

1) Backend API

```powershell
cd OmraneBackend
npm install
npm start
# API will listen on http://localhost:3000 and 0.0.0.0:3000
# Health check: http://localhost:3000/api/health
```

2) Flutter app

```powershell
cd omranefront
flutter pub get
flutter run
# Or choose a device explicitly, for example:
# flutter run -d windows
# flutter run -d chrome
# flutter run -d emulator-5554
```


## Configure frontend API URL

The app uses cookie-based sessions with the API. Base URL is configured in `omranefront/lib/core/config.dart` via `AppConfig.baseUrl`.

- For simulators/desktop/web on the same machine: default `http://localhost:3000/api` works out-of-the-box.
- For a physical device on the same LAN, set your PC’s LAN IP in `AppConfig.hostOverride`:

```dart
// omranefront/lib/core/config.dart
static const String hostOverride = 'YOUR_PC_LAN_IP'; // e.g., '192.168.1.33'
```

Then restart the Flutter app. Make sure Windows Firewall allows inbound connections for Node.js on port 3000.


## Default accounts (seed data)

The backend persists data in JSON files under `OmraneBackend/data/`. Initial users include:

- Admin
  - Email: `admin@university.edu`
  - Password: `admin123`

- Sample students (from `users.json`)
  - `hocinehaddalene@gmail.com` / `thebigshow1`
  - `amine@gmail.com` / `thebigshow1`
  - `ahmed@gmail.com` / `ahmed123`
  - `aek@gmail.com` / `thebigshpw1`


## API overview

Base URL: `http://localhost:3000/api` (or `http://<LAN-IP>:3000/api`)

- Auth: `POST /auth/login`, `POST /auth/logout`, `GET /auth/me`, `POST /auth/register` (admin), `POST /auth/self-register`
- Students (admin): `GET /students`, `GET /students/:id`, `PUT /students/:id`, `DELETE /students/:id`, `GET /students/:id/enrollments`
- Courses: `GET /courses`, `GET /courses/:id`, `POST /courses` (admin), `PUT /courses/:id` (admin), `DELETE /courses/:id` (admin), `GET /courses/:id/students` (admin)
- Enrollments: `GET /enrollments` (admin), `POST /enrollments`, `GET /enrollments/my-courses`, `DELETE /enrollments/:enrollmentId`, `PUT /enrollments/:enrollmentId` (admin)
- Payments: `GET /payments` (admin), `GET /payments/my-payments`, `GET /payments/my-fees`, `POST /payments`, `GET /payments/:id`, `PUT /payments/:id` (admin)

For detailed request/response examples and data models, see `OmraneBackend/README.md`.


## Data and session model

- Storage: JSON files in `OmraneBackend/data/` (`users.json`, `courses.json`, `enrollments.json`, `payments.json`)
- Sessions: Express-session stored in memory for development. Sessions reset when the server restarts.
- CORS: Enabled with credentials; the Flutter app uses a cookie jar to keep the session.


## Troubleshooting

- Physical device cannot log in:
  - Ensure `AppConfig.hostOverride` is set to your PC’s LAN IP
  - Ensure both device and PC are on the same network
  - Allow Node.js through Windows Firewall (port 3000)

- Android emulator can’t reach localhost:
  - The app already maps Android to `http://10.0.2.2:3000/api`. Make sure the backend runs on your PC.

- 401/403 errors from API:
  - Session cookies must be sent; don’t block third‑party cookies in the browser. In Flutter, Dio + cookie manager handles this automatically.

- Port 3000 already in use:
  - Stop the conflicting process or set `PORT=XXXX` before starting the server.


## Development notes

- Express binds to `0.0.0.0` so emulators/devices on LAN can connect.
- Course numbers can auto-generate (e.g., `CRS-0001`) if not provided.
- This stack is suitable for demos and coursework; for production, replace file storage and in‑memory sessions with a database and persistent session store.


## License

This project is provided as-is for educational purposes.
