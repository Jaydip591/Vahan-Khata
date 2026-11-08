# Transport Management — Backend

FastAPI + async SQLAlchemy + PostgreSQL + Alembic. See `../CLAUDE.md` for conventions and `../PLAN.md` for the plan.

## Run (development)
```bash
cp .env.example .env          # then set real values (SECRET_KEY, passwords, ADMIN_*)
docker compose up -d --build  # Postgres + API with hot reload; migrations run on start
```
API: http://localhost:8000 · Swagger: http://localhost:8000/docs

On the first start, if there are no users, the company and the first superadmin are created from
`COMPANY_NAME`, `ADMIN_USERNAME`, `ADMIN_PASSWORD` in `.env`.

## Without Docker for the API
```bash
python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt
docker compose up -d db
PYTHONPATH=src .venv/bin/alembic upgrade head
cd src && ../.venv/bin/uvicorn main:app --reload
```

## Tests
Needs the dev database running and a `transport_test` database:
```bash
docker exec transport_postgres psql -U transport -d postgres -c 'CREATE DATABASE transport_test'
set -a && . ./.env && set +a && .venv/bin/pytest
```

## Migrations
```bash
PYTHONPATH=src .venv/bin/alembic revision --autogenerate -m "describe change"
PYTHONPATH=src .venv/bin/alembic upgrade head
```

## API (Phase 0)
| Method | Path | Auth | |
|---|---|---|---|
| POST | `/api/v1/auth/login` | — | username + password → access + refresh token |
| POST | `/api/v1/auth/refresh` | — | refresh token → new access token (extends session) |
| POST | `/api/v1/auth/logout` | — | revoke the refresh token |
| GET | `/api/v1/users/me` | Bearer | current user |
| GET/POST | `/api/v1/users` | Bearer (superadmin) | list / create users |
| PATCH | `/api/v1/users/{id}` | Bearer (superadmin) | rename, reset password, activate/deactivate |
| GET | `/health` | — | health check |

## Production
`docker compose -f docker-compose.prod.yml up -d --build` with a real `.env`
(`APP_ENV=production` requires a 32+ char `SECRET_KEY`). Put Caddy in front for HTTPS.
