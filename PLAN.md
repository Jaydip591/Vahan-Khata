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
| trips | id, company_id, vehicle_id, driver_id?, party_id, from_place_id, to_place_id, trip_date, bhada, status (running/closed), note (advance = payments linked to the trip) |
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
- [x] vehicles, drivers, parties, accounts: CRUD (soft delete), company scoped
- [x] places: seed list of 193 Gujarat and nearby places (grow it over time; spellings need proofreading) with name_en and name_gu (shared, `company_id` null)
- [x] `GET /places?q=sur` search over English and Gujarati; `POST /places` with auto Gujarati via transliteration
      (Google Input Tools, best effort, user can edit); newly added places saved for the company
- [x] Vehicle auto-name suggestion ("Eicher 1" from type + serial)
- [x] Tests for each module
Frontend
- [x] More menu: Vehicles, Drivers, Accounts, Users, Language, Logout
- [x] Add vehicle: type chips, auto name, number field, optional document dates
- [x] Party add/list, driver add/list, account add/list
- [x] Reusable pickers: vehicle chips, party chips, place picker bottom sheet (type English -> Gujarati)
Done when: add a vehicle in 4 taps; typing "surat" shows સુરત; a new unknown place gets saved and appears next time.

Status: backend (53 tests) and Flutter (45 tests) are done. Still to verify by hand on the phone: add a vehicle in 4 taps, party/driver/account/user forms, place picker (picker widget is built and tested but is first used by the Trip form in Phase 2).

## Phase 2 — Core entries (biggest phase; split across two sessions)
2a Trips
- [x] Trips API: create, list (filters: vehicle, party, month, status), detail, close, soft delete
- [x] Advance on create writes a payment row in the same transaction
- [x] `GET /trips/routes/recent` returns frequent routes with last bhada
- [x] Trip screen: vehicle/party chips, quick-route chips, place picker, rate stepper, advance chips (full/half/none/custom) with live balance
- [x] "Same as last trip" copy button
2b Expenses and payments
- [x] Expenses API (+ diesel extras: liters, rate, odometer) and list/filter
- [x] Payments API; allocation (advance to its own trip first, the rest oldest trip first) shows which trips are settled
- [x] Party ledger API: totals, trip list with paid/unpaid, payments list
- [x] Kharcha screen: category tiles, keypad sheet with vehicle chips and account chip
- [x] Khata screens: party list sorted by oldest unpaid, party detail, payment sheet (All / Half / Custom)
Done when: a trip is saved in 5-6 taps; party balance matches by hand; expense and payment entries are 3-4 taps.

Status: backend (97 tests) and Flutter (93 tests) are done. Decisions made while building:
- The advance is not a column on the trip: it is a payment linked to the trip, created in the same transaction.
- Deleting a trip keeps its advance as a payment without a trip (the party keeps the credit) and unlinks its expenses.
- Amounts in the app are whole rupees (keypad); the server stores exact decimals.
Still to verify by hand on the phone: a full trip entry, a diesel expense, a payment, and the Khata numbers.

## Phase 3 — Reports and dashboard
- [x] Reports API: month summary, vehicle-wise, party-wise, monthly trend, expense-by-category (`/api/v1/reports/*`)
- [x] Home dashboard: month picker, profit hero card, income, expense, received, baaki, quick action tiles, vehicle profit list
- [x] Report screen tabs: Gaadi, Party, Mahino, Kharcha; per-vehicle profit with income/expense bars
- [x] Mileage (km/l) from diesel entries
- [x] Detail screens: vehicle detail (diesel log with date, liters, rate, odometer; trips; other expenses) and month detail (vehicles, trips, all expenses); tap a vehicle or a month to open
- [ ] Account balances report — moved to Phase 4a
Done when: a month's profit and per-vehicle profit match a hand calculation on test data.

Status: backend (110 tests) and Flutter (97 tests) are done. Decisions made while building:
- Income of a month = bhada of trips dated in that month (not money received); "received" is shown separately.
- Profit = bhada - expenses of the month. "Baaki" counts only parties that owe, all time.
- Mileage = (last odometer - first odometer) / liters of the later diesel fills in the month; needs two readings.
- The expense label in Gujarati is "જાવક" so it does not clash with the Kharcha tab name.
Still to verify by hand on the phone: month numbers against your own books, mileage, empty months.

## Phase 4 — Hardening (order decided by the user: finish app features first, deploy last)
4a Features
- [x] Offline queue: new trips, expenses and payments are kept on the phone when there is no internet, shown as "not sent", and sent automatically (app open, app resume, every 30 s, or "Send now") with client-made ids so a retry never duplicates. Kept in SharedPreferences (a few entries, no need for drift). Last GET answers are cached so lists and pickers open offline.
- [x] PDF and Excel export: party statement and month report, shared through the phone's share sheet (WhatsApp etc.); Gujarati PDF is drawn by Flutter as images so shaping is correct
- [ ] Account balances report (opening balance + payments - expenses per account)
- [ ] Anything found in Phase 3 phone testing
- [x] Fuel type per vehicle (diesel, petrol, CNG, CNG+petrol): chosen when adding or editing a vehicle; the Fuel tile on Kharcha preselects the vehicle's fuel (one fuel = only that chip; CNG+petrol = CNG preselected, petrol one tap away; CNG counted in kg). Expense categories are now diesel / petrol / cng. Reports: fuel totals per vehicle; mileage only when one fuel was used (km/l, km/kg for CNG). Existing vehicles became diesel and can be edited.
- [x] Expenses against a trip: trip detail has a "Trip expenses" card (add fuel, toll, food/allowance, repair... for that trip; vehicle and date come from the trip), the list of that trip's expenses, and the trip profit (bhada minus expenses). Kharcha tab marks trip expenses. Account balances report is still pending (done last).
- [x] App feel: haptics (tap, press, save, error, delete; switch in More), press-scale on buttons/chips/cards, fade page and tab transitions, count-up amounts, saved tick, skeleton loading, staggered list entry, pull-to-refresh tick, swipe-left delete on trips and expenses.
- [ ] Payment rows in the party khata should show cash/online and the account
### Next work list (final, decided with the user on 2026-11-10). Do in this order, one commit each.
The user said the app "still feels like something is missing" even after haptics/animations, so the list mixes the two open 4a items, "real app" UX items and three new features.
Show the plan for each item and wait for a yes before editing ("pehle batao, phir karo").

A. Open 4a items
- [x] A1. Account balances report: per account = opening balance + payments received into it - expenses paid from it. Simple; NO account-to-account transfer (user said not needed).
- [x] A2. Khata payment rows show cash/online and the account name.

B. Real-app UX
- [x] B1. App identity: real launcher icon (adaptive, ink background + gold truck/ledger mark; Claude designs the logo, user may swap it later), ink status bar, native splash in ink + gold with the LOGO ONLY (no text: the splash shows before Flutter knows the in-app language). Use flutter_launcher_icons / flutter_native_splash or hand-made Android resources. Launcher name stays as today: Android picks it from the PHONE language (`values/strings.xml` "Vahan Khata", `values-gu/strings.xml` "વાહન ખાતા"); user is fine with that. Do not use the activity-alias trick to follow the in-app language. Today the phone shows the default Flutter icon and a white launch screen.
- [x] B2. Profile and settings
  - Profile screen from the avatar card in More: big initial avatar, name, @username, company name, phone (if present), role (superadmin). Edit own name/phone. Needs `GET/PATCH /api/v1/users/me` (GET exists, check PATCH) and the company name in the response.
  - Change password: new endpoint (old + new password; revoke the user's other sessions; tests).
  - Settings section: language, vibration switch (exists), dark mode switch (B4), app version (package_info_plus), logout. No help/contact line for now (user). Keep the existing More list (vehicles, drivers, parties, accounts, users).
- [x] B3. "Is hafte" (this week) card on Home, simple enough for a driver: trips count, Kamai (bhada), Kharcha, Bacha (profit) for Monday-Sunday of the current week, and 7 small day bars (income per day, today in gold) with fl_chart. Plain words, big numbers. NO 6-month trend and NO per-vehicle chart (user wants it short). Needs a week summary (new `/reports/week` or a date-range variant of the month summary). Works from the offline cache, plain empty state, animates in.
- [x] B4. Polish (NO app lock / PIN / fingerprint):
  - Empty-state illustrations (simple drawn shapes in theme colours, friendly line like "પહેલી ટ્રીપ ઉમેરો") on Trips, Kharcha, Khata, parties/vehicles lists.
  - Dark mode (follow phone setting, plus a switch in settings; tokens in `core/theme`, never hardcode colours; income/expense have "on dark" variants already).
  - Smooth movement: bottom bar with a sliding gold indicator, spring on bottom sheets, predictive back (manifest flag already on).

C. New features
- [x] C1. Launcher shortcuts: long-press the app icon -> "નવી ટ્રીપ" / "ખર્ચ" / "પેમેન્ટ" opening the entry sheet directly (package `quick_actions`, Android App Shortcuts, Android 7.1+). Labels follow the in-app language (set at runtime). Old phones/odd launchers just show no shortcuts. Test on the user's OPPO first.
- [x] C2. Yearly report (financial year April-March): "Saal" option in the Report tab; FY totals (bhada, kharcha, profit, received, baaki), month-by-month table, per-vehicle profit; PDF and Excel export through the existing export code. Backend `/reports/year?fy=2026` (FY start year).
- [x] C3. Pay by UPI from the Kharcha entry (approved by the user; problems below were accepted as small):
  - Flow: category tile -> vehicle chip -> keypad amount -> "UPI થી ચૂકવો" button -> payee chip (saved) or "Scan QR" (first time; camera via `mobile_scanner`) or type a UPI ID -> UPI app opens with the amount filled -> user enters PIN -> back to our app.
  - Result from the UPI app (`Status`, `txnId`, `ApprovalRefNo`/UTR): SUCCESS -> save the expense automatically (account = a UPI account, UTR in a new `upi_ref` field); FAILURE/cancel -> no entry, show "Payment nahi hua"; SUBMITTED/empty/unclear -> ask "Payment થયું?" yes saves, no discards.
  - UPI app choice flag: a CODE CONSTANT in `lib/core/config` (user's choice), `upiOnlyGooglePay = true`; no Settings switch, changing it needs a new APK. true -> intent targets package `com.google.android.apps.nbu.paisa.user` directly; if GPay is not installed, fall back to the chooser. false -> Android chooser lists all UPI apps (GPay, PhonePe, Paytm, BHIM...).
  - Android: `upi://pay?pa=&pn=&am=&cu=INR&tn=&tr=` intent with startActivityForResult (small Kotlin method channel or a maintained plugin), `<queries>` for the `upi` scheme in the manifest (Android 11+ package visibility), CAMERA permission.
  - Backend: `payees` master (name, upi_id, company scoped, `core/crud.py` helpers) + `upi_ref` on expenses (Alembic migration) + tests.
  - Known limits (accepted): GPay/PhonePe sometimes block intent payments to a PERSONAL UPI ID ("security reasons"); merchant/business QR works. The returned status is not bank-verified (hence the confirm). Needs internet; offline expenses stay manual.
  - NOT possible: bank details, balance check or transaction history from GPay/PhonePe. They have no public API; balance is only inside the UPI app with the PIN. (The regulated route is RBI Account Aggregator, not for this app.)

Done when: icon and splash show on the launcher, the app looks right in light and dark on the phone, shortcuts open the entry sheets, a UPI payment saves an expense, and all tests plus new tests (account balances, profile edit, password change, week summary, year report, payees/upi_ref) pass.

Not doing now (user said no): search/filter on lists, WhatsApp "baaki" reminder, account-to-account transfer, app lock, 6-month/per-vehicle charts. Other ideas listed but not chosen: payables khata (pump/mechanic udhaar), vehicle fixed costs (EMI/insurance), bilty/LR PDF, per-ton rate, return trip, km-based service reminder, activity log, recycle bin, full Excel backup.

4b Deploy — ON HOLD (user, 2026-11-10: ignore deploy, expiry notifications and Phase 5 pilot until the next work list is done). Hosting on Render, not Oracle. Database: Neon (free). Keep-awake: a free pinger site (cron-job.org) calls `/health` every 13 minutes so the free web service does not sleep.
- [ ] Render web service from `BE/Dockerfile`, HTTPS included; `DATABASE_URL`, secrets and admin bootstrap as env vars
- [ ] Postgres on Neon (`DATABASE_URL` with SSL); check the async driver URL form
- [ ] Nightly backup with a Render Cron Job running `pg_dump` to Google Drive (rclone) or object storage; tested restore
- [ ] Release APK pointing at the Render URL, signed; install instructions
Later (user's choice, after the above): document expiry notifications (insurance, PUC, fitness, permit, tax)
Done when: entries made in airplane mode appear on the server after reconnect with no duplicates; a backup restore was tested.

## Phase 5 — Pilot
- [ ] Give to 1-2 family drivers for a week; collect issues
- [ ] Fix font sizes, button placement, wording (Gujarati proofreading)
- [ ] Optional later: voice amount input, Play Store release, roles

## Handoff notes for a new session (read this first)
- State on 2026-11-10: Phases 0-3 done; Phase 4a mostly done (offline, fuel type, PDF/Excel, trip expenses, app-feel pass). Next: the "Next work list" in Phase 4 (A1 account balances, A2 khata payment rows, B1-B4 UX, C1 launcher shortcuts, C2 yearly report, C3 UPI pay), in that order. Deploy, notifications and pilot are on hold. Last commit when this was written: "App feel: haptics ...".
- Backend + ngrok on the dev PC: API container `transport_api` and `transport_postgres` (docker compose, restart unless-stopped); ngrok static domain `isocheimenal-windrode-latashia.ngrok-free.dev` -> localhost:8000 (`ngrok http 8000 --url=isocheimenal-windrode-latashia.ngrok-free.dev`). The phone app is built against that URL.
- Build and install on the phone (OPPO/OnePlus CPH2531, adb id PRWWVK8T9XQ8LJ6X; USB debugging on):
  `cd FE && flutter build apk --release --dart-define=API_BASE_URL=https://isocheimenal-windrode-latashia.ngrok-free.dev && adb install -r build/app/outputs/flutter-apk/app-release.apk`
  For hot reload: `flutter run -d PRWWVK8T9XQ8LJ6X --dart-define=API_BASE_URL=...` (hot restart does not pick up manifest changes; do a fresh run).
- Checks: `cd FE && flutter analyze && flutter test` (130 tests); `cd BE && set -a && . ./.env && set +a && .venv/bin/pytest` (119 tests).
- Phone testing rules: never turn Wi-Fi/data off on the phone (user objected); the screen locks itself and cannot be unlocked by us, so ask the user; do not tap on the phone while the user is using it; avoid the BACK key (it can leave the app and a following tap lands on the launcher). Use `adb shell am start -n com.jaydip.vahan_khata/.MainActivity` to reopen the app. Horizontal swipes: use `adb shell input motionevent DOWN/MOVE/UP`.
- Commit messages: plain, no co-author or tool attribution lines (user's instruction). Never run `dart format` on all of `lib` (it reformats 70+ files).
- User talks in Hinglish (Roman Gujarati-Hindi-English mix); answer in the same style, short and concrete. For design/feel work show the plan first and wait for a yes before editing ("pehle batao, phir karo").

## Risks and notes
- Flutter SDK and an Android device or emulator are needed on the dev machine (not installed yet).
- Hosting is Render (user's choice). Free web services sleep after idle, so the first request is slow; free Postgres expires after 30 days.
- Google Input Tools transliteration is unofficial; the seed place list must cover most real use so it stays a fallback.
- Keep every session short and focused: finish a slice, commit, update the checkboxes here.
