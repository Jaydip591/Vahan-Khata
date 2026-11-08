from typing import AsyncGenerator

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from core.database import AsyncSessionLocal
from core.security import decode_access_token

bearer_scheme = HTTPBearer(auto_error=False)


# ── Database session dependency ────────────────────────────────────────────────
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Yield an async DB session; roll back on error, always close."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


# ── Current user ───────────────────────────────────────────────────────────────
async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
):
    """Decode the access token and return the matching active User."""
    # Imported here to avoid circular imports.
    from apps.user.services.user_service import UserService

    unauthorized = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if credentials is None:
        raise unauthorized
    user_id = decode_access_token(credentials.credentials)
    if user_id is None:
        raise unauthorized
    user = await UserService.get_by_id(db, user_id)
    if user is None or not user.is_active:
        raise unauthorized
    return user


async def require_superadmin(user=Depends(get_current_user)):
    from apps.user.models.user import ROLE_SUPERADMIN

    if user.role != ROLE_SUPERADMIN:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not allowed.")
    return user
