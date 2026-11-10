import os

# Point the app at the test database BEFORE any app module is imported.
_TEST_URL = os.environ.get(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://{u}:{p}@localhost:{port}/transport_test".format(
        u=os.environ.get("POSTGRES_USER", "transport"),
        p=os.environ.get("POSTGRES_PASSWORD", "transport"),
        port=os.environ.get("DB_PORT", "5432"),
    ),
)
os.environ["DATABASE_URL"] = _TEST_URL
os.environ["APP_ENV"] = "development"
os.environ["COMPANY_NAME"] = "Test Transport"
os.environ["ADMIN_USERNAME"] = "admin"
os.environ["ADMIN_PASSWORD"] = "admin-pass-1"

import pytest  # noqa: E402
import pytest_asyncio  # noqa: E402
from httpx import ASGITransport, AsyncClient  # noqa: E402
from sqlalchemy import text  # noqa: E402

import apps.auth.models  # noqa: E402,F401
import apps.company.models  # noqa: E402,F401
import apps.user.models  # noqa: E402,F401
import apps.vehicle.models  # noqa: E402,F401
import apps.driver.models  # noqa: E402,F401
import apps.party.models  # noqa: E402,F401
import apps.account.models  # noqa: E402,F401
import apps.payee.models  # noqa: E402,F401
import apps.place.models  # noqa: E402,F401
import apps.trip.models  # noqa: E402,F401
import apps.payment.models  # noqa: E402,F401
import apps.expense.models  # noqa: E402,F401
from apps.company.services.bootstrap import bootstrap_admin  # noqa: E402
from core.database import AsyncSessionLocal, Base, engine  # noqa: E402
from main import app  # noqa: E402


@pytest_asyncio.fixture(scope="session", autouse=True)
async def _schema():
    async with engine.begin() as conn:
        await conn.execute(text("DROP SCHEMA public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
        await conn.run_sync(Base.metadata.create_all)
    yield
    await engine.dispose()


@pytest_asyncio.fixture(autouse=True)
async def _clean_db(_schema):
    async with engine.begin() as conn:
        names = ", ".join(t.name for t in Base.metadata.sorted_tables)
        await conn.execute(text(f"TRUNCATE {names} CASCADE"))
    async with AsyncSessionLocal() as db:
        await bootstrap_admin(db)


@pytest_asyncio.fixture
async def client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c


@pytest_asyncio.fixture
async def admin_tokens(client):
    r = await client.post(
        "/api/v1/auth/login", json={"username": "admin", "password": "admin-pass-1"}
    )
    assert r.status_code == 200, r.text
    return r.json()


@pytest.fixture
def auth(admin_tokens):
    return {"Authorization": f"Bearer {admin_tokens['access_token']}"}


@pytest_asyncio.fixture
async def seeded():
    """Load the shared place list (most tests don't need it)."""
    from apps.place.services.place_service import ensure_seed_places

    async with AsyncSessionLocal() as db:
        await ensure_seed_places(db)


@pytest_asyncio.fixture
async def other_auth(client):
    """Login headers for a user of a DIFFERENT company, for isolation tests."""
    from apps.company.models.company import Company
    from apps.user.models.user import User
    from core.security import hash_password

    async with AsyncSessionLocal() as db:
        company = Company(name="Other Co")
        db.add(company)
        await db.flush()
        db.add(
            User(
                company_id=company.id,
                username="other",
                password_hash=hash_password("other-pass-1"),
                name="Other",
            )
        )
        await db.commit()
    r = await client.post("/api/v1/auth/login", json={"username": "other", "password": "other-pass-1"})
    return {"Authorization": f"Bearer {r.json()['access_token']}"}
