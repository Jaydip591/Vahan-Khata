"""
apps/user/services/user_service.py

Business logic for users. Every query is scoped to the caller's company.
"""
import asyncio
from datetime import datetime, timezone
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from apps.auth.models.refresh_token import RefreshToken
from apps.user.models.user import ROLE_SUPERADMIN, User
from apps.user.schemas.user import ProfileUpdateRequest, UserCreateRequest, UserUpdateRequest
from core.security import hash_password


class UserService:
    @staticmethod
    async def get_by_id(db: AsyncSession, user_id: UUID) -> User | None:
        result = await db.execute(
            select(User).where(User.id == user_id, User.deleted_at.is_(None))
        )
        return result.scalars().first()

    @staticmethod
    async def get_by_username(db: AsyncSession, username: str) -> User | None:
        result = await db.execute(
            select(User).where(User.username == username, User.deleted_at.is_(None))
        )
        return result.scalars().first()

    @staticmethod
    async def list_for_company(db: AsyncSession, company_id: UUID) -> list[User]:
        result = await db.execute(
            select(User)
            .where(User.company_id == company_id, User.deleted_at.is_(None))
            .order_by(User.created_at)
        )
        return list(result.scalars().all())

    @staticmethod
    async def get_in_company(db: AsyncSession, company_id: UUID, user_id: UUID) -> User:
        result = await db.execute(
            select(User).where(
                User.id == user_id,
                User.company_id == company_id,
                User.deleted_at.is_(None),
            )
        )
        user = result.scalars().first()
        if user is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found.")
        return user

    @classmethod
    async def create(
        cls, db: AsyncSession, actor: User, payload: UserCreateRequest
    ) -> User:
        if await cls.get_by_username(db, payload.username):
            raise HTTPException(status.HTTP_409_CONFLICT, "This username is already taken.")
        user = User(
            company_id=actor.company_id,
            created_by=actor.id,
            username=payload.username,
            password_hash=await asyncio.to_thread(hash_password, payload.password),
            name=payload.name,
            phone=payload.phone,
            role=ROLE_SUPERADMIN,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
        return user

    @classmethod
    async def update(
        cls, db: AsyncSession, actor: User, user_id: UUID, payload: UserUpdateRequest
    ) -> User:
        user = await cls.get_in_company(db, actor.company_id, user_id)
        changed_secret = False

        if payload.name is not None:
            user.name = payload.name
        if payload.phone is not None:
            user.phone = payload.phone or None
        if payload.password is not None:
            user.password_hash = await asyncio.to_thread(hash_password, payload.password)
            changed_secret = user.id != actor.id
        if payload.is_active is not None:
            if user.id == actor.id and payload.is_active is False:
                raise HTTPException(
                    status.HTTP_400_BAD_REQUEST, "You cannot deactivate your own account."
                )
            if payload.is_active is False:
                changed_secret = True
            user.is_active = payload.is_active

        if changed_secret:
            await cls.revoke_sessions(db, user.id)
        await db.commit()
        await db.refresh(user)
        return user

    @staticmethod
    async def update_profile(db: AsyncSession, user: User, payload: ProfileUpdateRequest) -> User:
        if payload.name is not None:
            user.name = payload.name
        if payload.phone is not None:
            user.phone = payload.phone or None
        await db.commit()
        await db.refresh(user)
        return user

    @staticmethod
    async def revoke_sessions(db: AsyncSession, user_id: UUID) -> None:
        await db.execute(
            update(RefreshToken)
            .where(RefreshToken.user_id == user_id, RefreshToken.revoked_at.is_(None))
            .values(revoked_at=datetime.now(timezone.utc))
        )
