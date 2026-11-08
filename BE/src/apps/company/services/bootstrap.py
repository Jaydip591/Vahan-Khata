"""
apps/company/services/bootstrap.py

First-start setup: if there are no users, create the company and the first
superadmin from the COMPANY_NAME / ADMIN_USERNAME / ADMIN_PASSWORD settings.
Does nothing once a user exists, so it is safe to run on every start.
"""
import asyncio
import logging

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from apps.company.models.company import Company
from apps.user.models.user import ROLE_SUPERADMIN, User
from core.config import settings
from core.security import hash_password

log = logging.getLogger(__name__)


async def bootstrap_admin(db: AsyncSession) -> bool:
    """Return True if the company and admin were created."""
    existing = await db.execute(select(User.id).limit(1))
    if existing.first() is not None:
        return False
    if not settings.ADMIN_USERNAME or not settings.ADMIN_PASSWORD:
        log.warning("No users exist and ADMIN_USERNAME / ADMIN_PASSWORD are not set.")
        return False

    company = Company(name=settings.COMPANY_NAME)
    db.add(company)
    await db.flush()
    admin = User(
        company_id=company.id,
        username=settings.ADMIN_USERNAME.strip().lower(),
        password_hash=await asyncio.to_thread(hash_password, settings.ADMIN_PASSWORD),
        name=settings.ADMIN_NAME,
        role=ROLE_SUPERADMIN,
    )
    db.add(admin)
    await db.commit()
    log.info("Created company %r and admin %r", company.name, admin.username)
    return True
