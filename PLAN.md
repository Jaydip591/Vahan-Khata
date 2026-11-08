# Transport Management — Build Plan

Rule: one phase per session. Tick boxes as work finishes. See `CLAUDE.md` for decisions and conventions.

## Data model (target)

| Table | Key columns |
|---|---|
| companies | id, name |
| users | id, company_id, username (unique), password_hash, name, role, is_active |
| refresh_tokens | id, user_id, token_hash, expires_at, revoked_at |
| vehicles | id, company_id, vehicle_type, name, number, fuel_type?, is_active, insurance_exp?, puc_exp?, fitness_exp?, permit_exp?, tax_exp? |
| drivers | id, company_id, name, phone, default_vehicle_id? |
| parties | id, company_id, name, phone?, payment_cycle? (daily/10d/monthly) |
| places | id, company_id?, name_en, name_gu, is_seed (company_id null = shared seed list) |
| accounts | id, company_id, name, kind (cash/bank/upi), opening_balance |
| trips | id, company_id, vehicle_id, driver_id?, party_id, from_place_id, to_place_id, trip_date, bhada, advance, advance_account_id?, status (running/closed), note |
| payments | id, company_id, party_id, amount, mode (cash/online), account_id, paid_on, received_by, trip_id? (set only for an advance given with a trip) |
| expenses | id, company_id, vehicle_id, trip_id?, category (diesel/toll/repair/allowance/challan/other), amount, expense_date, account_id?, liters?, rate?, odometer?, note, repair_kind? |

Derived, never stored: party balance, vehicle profit, account balance, mileage (km/l).
Advance on a trip creates a `payments` row, so the ledger stays a single source of truth.

## Phase 0 — Setup and login
Backend
- [x] Remove leftovers: `BE/controller.py`, `db.py`, `schemas.py`, `service.py`, `__init__.py` at BE root
- [x] Update `requirements.txt` (fastapi, sqlalchemy, asyncpg, alembic, pydantic-settings, PyJWT, bcrypt); drop python-jose and email-validator
- [x] `companies` table; `users` gets username, name, role, company_id; drop email
- [x] `/auth/login` (username + password) returns access token (short) + refresh token (long, stored hashed, revocable)
- [x] `/auth/refresh`, `/auth/logout`
- [x] Remove public signup. `POST /users` for logged-in superadmin; `GET /users`, `PATCH /users/{id}`
- [x] First-start bootstrap: create company + admin from env if no users
- [x] Base model mixin (id, company_id, created_by, timestamps, soft delete); `get_current_user` returns company scope
- [x] Docker: dev compose + production compose (DB port closed, no reload)
- [x] Tests: login, refresh, logout, create user, company isolation
Frontend
- [x] Install Flutter SDK + Android toolchain (not installed on this machine yet), create `FE/` project
- [x] Theme (ink and gold tokens), Noto Sans Gujarati font, ARB files gu + en, language switch
- [x] Dio client with token refresh interceptor, secure token storage, go_router with auth guard
- [x] Login screen; stays logged in until Logout (More screen)
Done when: login works from the phone, app reopens still logged in, logout clears it, `/docs` shows the new auth API.

Status: backend and Flutter code are done and covered by tests (BE 24, FE 15) and a debug APK builds.
Still to verify by hand: log in from a real phone against the running backend (see FE/README.md).

## Phase 1 — Masters
Backend
- [ ] vehicles, drivers, parties, accounts: CRUD (soft delete), company scoped
- [ ] places: seed list of ~300-500 Gujarat cities/towns with name_en and name_gu (shared, `company_id` null)
- [ ] `GET /places?q=sur` search over English and Gujarati; `POST /places` with auto Gujarati via transliteration
      (Google Input Tools, best effort, user can edit); newly added places saved for the company
- [ ] Vehicle auto-name suggestion ("Eicher 1" from type + serial)
- [ ] Tests for each module
Frontend
- [ ] More menu: Vehicles, Drivers, Accounts, Users, Language, Logout
- [ ] Add vehicle: type chips, auto name, number field, optional document dates
- [ ] Party add/list, driver add/list, account add/list
- [ ] Reusable pickers: vehicle chips, party chips, place picker bottom sheet (type English -> Gujarati)
Done when: add a vehicle in 4 taps; typing "surat" shows સુરત; a new unknown place gets saved and appears next time.

## Phase 2 — Core entries (biggest phase; split across two sessions)
2a Trips
- [ ] Trips API: create, list (filters: vehicle, party, month, status), detail, close, soft delete
- [ ] Advance on create writes a payment row in the same transaction
- [ ] `GET /trips/routes/recent` returns frequent routes with last bhada
- [ ] Trip screen: vehicle/party chips, quick-route chips, place picker, rate stepper, advance chips (full/half/none/custom) with live balance
- [ ] "Same as last trip" copy button
2b Expenses and payments
- [ ] Expenses API (+ diesel extras: liters, rate, odometer) and list/filter
- [ ] Payments API; optional allocation view (oldest trip first) for showing which trips are settled
- [ ] Party ledger API: totals, trip list with paid/unpaid, payments list
- [ ] Kharcha screen: category tiles, keypad sheet with vehicle chips and account chip
- [ ] Khata screens: party list sorted by oldest unpaid, party detail, payment sheet (All / Half / Custom)
Done when: a trip is saved in 5-6 taps; party balance matches by hand; expense and payment entries are 3-4 taps.

## Phase 3 — Reports and dashboard
- [ ] Reports API: month summary, vehicle-wise, party-wise, monthly trend, expense-by-category, account balances
- [ ] Home dashboard: month picker, profit hero card, income, expense, baaki, quick action tiles, vehicle list with status
- [ ] Report screen tabs: Gaadi, Party, Mahino, Kharcha; per-vehicle profit with income/expense bars
- [ ] Mileage (km/l) from diesel entries
Done when: a month's profit and per-vehicle profit match a hand calculation on test data.

## Phase 4 — Hardening
- [ ] Offline queue (drift): entries saved locally, synced when online, safe retry with client-generated ids (no duplicates)
- [ ] Document expiry local notifications (insurance, PUC, fitness, permit, tax)
- [ ] PDF and Excel export; share party statement on WhatsApp
- [ ] Production deploy on Oracle free VM: Docker compose, Caddy HTTPS, DuckDNS domain
- [ ] Nightly `pg_dump` to Google Drive (rclone), tested restore
- [ ] Release APK build and signing; install instructions
Done when: entries made in airplane mode appear on the server after reconnect with no duplicates; a backup restore was tested.

## Phase 5 — Pilot
- [ ] Give to 1-2 family drivers for a week; collect issues
- [ ] Fix font sizes, button placement, wording (Gujarati proofreading)
- [ ] Optional later: voice amount input, Play Store release, roles

## Risks and notes
- Flutter SDK and an Android device or emulator are needed on the dev machine (not installed yet).
- Oracle free tier signup needs a card for verification and can be rejected; fallback is a home PC with Cloudflare Tunnel.
- Google Input Tools transliteration is unofficial; the seed place list must cover most real use so it stays a fallback.
- Keep every session short and focused: finish a slice, commit, update the checkboxes here.
