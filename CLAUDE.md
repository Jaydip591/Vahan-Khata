# Vahan Khata (વાહન ખાતા) — project guide

App name: **Vahan Khata** (Gujarati: વાહન ખાતા). Repo: github.com/Jaydip591/Vahan-Khata (monorepo, BE + FE).

Gujarati-first Android app to run a family transport business: trips, expenses, party ledger (khata),
vehicle-wise profit. Read `PLAN.md` for the phase plan and current progress before starting work (the "Handoff notes for a new session" section lists how to run, build and test, and the rules for phone testing).

## Repo layout
- `BE/` — FastAPI backend (modular apps, async SQLAlchemy, Postgres, Alembic, Docker)
- `FE/` — Flutter app (Android only for now), package `vahan_khata`.
- `PLAN.md` — phases, tasks, done-criteria. Tick items off as they finish.

## Product decisions (final, do not re-ask)
- Mobile only, no web. Android first.
- All users are superadmin for now. Keep a `role` column so roles can come later.
- Vehicles are all owned (no hired/market trucks). Drivers are family: no salary tracking.
- Income is per trip (bhada). Payment arrives later, in parts, cash or online, into different accounts
  (e.g. "Cash - Jaydip", "UPI - Bhai", "Bank - SBI"). Party balance = sum(trip bhada) - sum(payments).
  Never store the balance as a column; compute it.
- 5-7 users and vehicles now, but any number must work.
- Language: Gujarati (default) and English, switchable in More -> Language. Use Flutter l10n (ARB files).
- No photo upload for now. No S3. Self-hosted free backend.
- Login: username + password. Login stays until the user explicitly logs out.
  Only a logged-in user can create other users. No public signup.

## UI principles
- Big fonts (body 18sp, amount 28sp), buttons 56dp high, Gujarati labels, Noto Sans Gujarati bundled in app.
- Selection over typing: chips, pickers, bottom sheets, steppers, custom numeric keypad.
  Defaults: today's date, last used vehicle/party/account, last rate for a route.
- Trip form: vehicle chips, party chips, quick-route chips (fills from, to and last rate in one tap),
  place picker (typing English transliterates to Gujarati: Surat -> સુરત), rate -/+ stepper,
  advance chips (Full / Half / None / Custom) with live balance. Full advance = bhada.
- Expense: category tile -> bottom sheet with vehicle chips + keypad + Save.
- Payment: party chips -> amount chips (All / Half / Custom) -> Cash/Online -> account chip.
- Bottom bar: Home, Trips, Kharcha, Khata, Report. "More" opens from the Home menu icon.
- Colors are semantic: income always emerald, expense and "baaki" always coral.

## Theme: Ink and gold (final)
ink `#12161C`, ink2 `#1E252E`, ink3 `#2C3540`, gold `#C8A24A` (primary action buttons, ink text on top),
ivory background `#F6F3EE`, card white, line `#E8E2D8`, muted `#7A7468`,
income `#1F8A70` (on dark `#5FD0AE`), expense `#D2574A` (on dark `#FF8E80`).
Selected chip: ink fill, white text. Active tab: gold top border.

## Backend conventions (BE/)
- Structure per module: `src/apps/<module>/{controllers,services,models,schemas}`; controllers are thin,
  logic lives in services, models are columns only, request and response schemas are separate classes.
  Register routers in `src/main.py` under `/api/v1`.
- Every business table has: `id` (uuid), `company_id`, `created_by`, `created_at`, `updated_at`, `deleted_at`
  (soft delete; never hard-delete money data). Filter by the current user's `company_id` in every query.
- Money is `Numeric(12,2)`. Never float.
- Migrations with Alembic only (`alembic revision --autogenerate`). Never edit applied migrations.
- First start: if no user exists, create the company and first superadmin from env
  (`COMPANY_NAME`, `ADMIN_USERNAME`, `ADMIN_PASSWORD`).
- Tests with pytest + httpx against a test database.
- Secrets live in `.env` (git-ignored). `.env.example` is the template.
- Auth: short access JWT (30 min) + long refresh token (365 days, sliding, stored hashed in `refresh_tokens`).
  Refresh does not rotate. Logout revokes the refresh token. Deactivating a user or an admin password reset
  revokes that user's sessions.
- Dev DB: `docker compose up -d db` (Postgres on localhost:5432). Tests use database `transport_test`:
  `cd BE && set -a && . ./.env && set +a && .venv/bin/pytest`.
- Shared place list lives in `BE/src/apps/place/seed_data.py` (English, Gujarati, in popularity order). It is
  synced into the database on every start; edit the file to add places or fix spellings.
- Party balance = sum(bhada) - sum(payments). Which trips show as paid comes from `apps/ledger/allocation.py`
  (advance to its own trip first, the rest oldest trip first). Never store paid or balance on a trip.
- Master modules (vehicle, driver, party, account) use the helpers in `core/crud.py`; new master-like modules should too.
- Prod: `docker-compose.prod.yml` (DB not published, API on 127.0.0.1 behind Caddy).

## Flutter conventions (FE/)
- Riverpod (state), go_router (navigation), dio (HTTP), drift (local DB / offline queue),
  flutter_secure_storage (tokens), intl + flutter_localizations, fl_chart, pdf + share_plus.
- Feature-first folders: `lib/features/<feature>/{data,domain,presentation}`, shared UI in `lib/core/ui`.
- Riverpod providers do not auto-retry (`core/provider_retry.dart`): failures show an error with a Retry button.
- Quick entry uses bottom sheets (`showAppSheet`, `showAmountSheet`, `showExpenseSheet`, `showPaymentSheet`);
  amounts are whole rupees from `KeypadPad`; remembered choices live in `core/defaults_store.dart`.
- Offline: saves of new trips, expenses and payments go through `features/outbox` (client-made `id` in the body, backend returns the existing row on a retry). Edits and deletes need internet. GET answers are cached by `core/network/response_cache.dart`.
- Tests use `test/support/fake_api.dart` (in-memory backend over Dio) and `appWith(...)` from `fakes.dart`.
- Reusable entry widgets: `AppChip`, `AppTextField`, `FormShell`, `MasterListScreen`, `showPlacePicker`,
  `VehicleChips`, `PartyChips` (use these in Phase 2 forms instead of new widgets).
- All strings in ARB files (`app_gu.arb`, `app_en.arb`). No hardcoded user-facing text.
- Theme tokens in one file; never hardcode colors in widgets.
- Every entry screen must be usable in 5-6 taps and with one hand.

## Flutter toolchain on this machine
- Flutter SDK: `~/development/flutter` (add `~/development/flutter/bin` to PATH). Android SDK: `~/Android/Sdk`.
- Gradle needs a full JDK: `flutter config --jdk-dir /snap/android-studio/current/jbr` (already set).
- Checks: `cd FE && flutter analyze && flutter test`. Debug APK: `flutter build apk --debug` (first build ~5 min).
- Run on a phone/emulator against the dev API: see `FE/README.md` (`--dart-define=API_BASE_URL=...`).
- Android package id `com.jaydip.vahan_khata`; launcher name comes from `res/values*/strings.xml` (English + Gujarati).

## Working agreement
- One phase (or one feature slice) per session. Finish a slice end to end: table -> API -> test -> screen.
- Commit after each slice. Update `PLAN.md` checkboxes when a task is done.
- Commit messages: plain, no co-author or tool attribution lines (user's instruction).
- Hosting target: Render web service from the Dockerfile + Neon Postgres + a free pinger on `/health` every 13 min + a nightly `pg_dump` job.
  Deploy only after the offline mode and other Phase 4a features are finished. Document expiry notifications come last.
