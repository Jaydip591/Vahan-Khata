"""
apps/auth/services/auth_service.py

Login, token refresh and logout.

Sessions: login issues a short-lived access token (JWT) and a long-lived refresh
token (random string, only its hash is stored). The app keeps the refresh token in
secure storage and asks for a new access token whenever needed, so the user stays
logged in until they log out. Each refresh pushes the expiry forward (sliding).
"""
import asyncio
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from apps.auth.models.refresh_token import RefreshToken
from apps.auth.schemas.auth import AccessTokenResponse, LoginRequest, TokenResponse
from apps.user.schemas.user import ChangePasswordRequest
from apps.user.services.user_service import UserService
from core.config import settings
from core.security import (
    DUMMY_HASH,
    create_access_token,
    hash_password,
    hash_token,
    new_refresh_token,
    verify_password,
)

_INVALID_LOGIN = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Incorrect username or password.",
)
_INVALID_REFRESH = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Session expired. Please log in again.",
)


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _refresh_expiry() -> datetime:
    return _now() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)


class AuthService:
    @staticmethod
    async def login(db: AsyncSession, payload: LoginRequest) -> TokenResponse:
        user = await UserService.get_by_username(db, payload.username)
        password_ok = await asyncio.to_thread(
            verify_password, payload.password, user.password_hash if user else DUMMY_HASH
        )
        if user is None or not password_ok:
            raise _INVALID_LOGIN
        if not user.is_active:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "This account is disabled.")

        return await AuthService._issue(db, user.id)

    @staticmethod
    async def _issue(db: AsyncSession, user_id) -> TokenResponse:
        raw, hashed = new_refresh_token()
        db.add(RefreshToken(user_id=user_id, token_hash=hashed, expires_at=_refresh_expiry()))
        await db.commit()
        return TokenResponse(
            access_token=create_access_token(user_id),
            refresh_token=raw,
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        )

    @staticmethod
    async def change_password(db: AsyncSession, user, payload: ChangePasswordRequest) -> TokenResponse:
        """Checks the old password, sets the new one, logs out every other phone and returns a
        fresh session for this one."""
        ok = await asyncio.to_thread(verify_password, payload.old_password, user.password_hash)
        if not ok:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "The current password is wrong.")
        user.password_hash = await asyncio.to_thread(hash_password, payload.new_password)
        await UserService.revoke_sessions(db, user.id)
        return await AuthService._issue(db, user.id)

    @staticmethod
    async def refresh(db: AsyncSession, raw_token: str) -> AccessTokenResponse:
        result = await db.execute(
            select(RefreshToken).where(RefreshToken.token_hash == hash_token(raw_token))
        )
        token = result.scalars().first()
        if token is None or token.revoked_at is not None or token.expires_at <= _now():
            raise _INVALID_REFRESH

        user = await UserService.get_by_id(db, token.user_id)
        if user is None or not user.is_active:
            raise _INVALID_REFRESH

        token.expires_at = _refresh_expiry()
        await db.commit()
        return AccessTokenResponse(
            access_token=create_access_token(user.id),
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        )

    @staticmethod
    async def logout(db: AsyncSession, raw_token: str) -> None:
        """Revoke the session. Always succeeds, so a stale token never blocks logout."""
        result = await db.execute(
            select(RefreshToken).where(RefreshToken.token_hash == hash_token(raw_token))
        )
        token = result.scalars().first()
        if token is not None and token.revoked_at is None:
            token.revoked_at = _now()
            await db.commit()
