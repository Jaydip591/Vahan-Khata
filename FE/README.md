# Vahan Khata — Flutter app (Android)

See `../CLAUDE.md` for conventions and `../PLAN.md` for the plan.

## Run against the dev backend
1. Start the backend: `cd ../BE && docker compose up -d --build` (API on port 8000).
2. Pick the API address:
   - Android emulator: default `http://10.0.2.2:8000` works as is.
   - Real phone on the same Wi-Fi: use your computer's LAN IP, e.g. `http://192.168.1.10:8000`.
   - Real phone over USB: `adb reverse tcp:8000 tcp:8000`, then use `http://127.0.0.1:8000`.
3. Run:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
   ```
Log in with `ADMIN_USERNAME` / `ADMIN_PASSWORD` from `BE/.env`.

Debug builds allow plain http for local testing. Release builds must talk to an https server.

## Checks
```bash
flutter analyze
flutter test
```

## Structure
- `lib/core/` theme tokens, API client (token refresh), secure token storage, router, shared widgets
- `lib/features/<feature>/` data and presentation per feature (auth, home, more)
- `lib/l10n/` `app_gu.arb` (default) and `app_en.arb`; run `flutter gen-l10n` after editing
- `assets/fonts/` Noto Sans Gujarati (bundled, works offline)
