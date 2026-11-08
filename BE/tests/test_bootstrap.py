from sqlalchemy import func, select, text

from apps.company.models.company import Company
from apps.company.services.bootstrap import bootstrap_admin
from apps.user.models.user import User
from core.database import AsyncSessionLocal, engine


async def test_bootstrap_is_noop_when_users_exist():
    async with AsyncSessionLocal() as db:
        assert await bootstrap_admin(db) is False
        assert (await db.execute(select(func.count()).select_from(User))).scalar_one() == 1
        assert (await db.execute(select(func.count()).select_from(Company))).scalar_one() == 1


async def test_bootstrap_creates_company_and_admin_when_empty():
    async with engine.begin() as conn:
        await conn.execute(text("TRUNCATE refresh_tokens, users, companies CASCADE"))
    async with AsyncSessionLocal() as db:
        assert await bootstrap_admin(db) is True
        company = (await db.execute(select(Company))).scalar_one()
        admin = (await db.execute(select(User))).scalar_one()
        assert company.name == "Test Transport"
        assert admin.username == "admin"
        assert admin.company_id == company.id
        assert admin.role == "superadmin"
        assert admin.password_hash != "admin-pass-1"
