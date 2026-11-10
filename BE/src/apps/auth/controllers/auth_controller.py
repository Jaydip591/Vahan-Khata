"""
apps/auth/controllers/auth_controller.py

Thin controller: request/response handling only.
"""
from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from apps.auth.schemas.auth import (
    AccessTokenResponse,
    LoginRequest,
    LogoutRequest,
    RefreshRequest,
    TokenResponse,
)
from apps.auth.services.auth_service import AuthService
from apps.user.models.user import User
from apps.user.schemas.user import ChangePasswordRequest
from core.dependencies import get_current_user, get_db

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/login", response_model=TokenResponse, summary="Log in with username and password")
async def login(payload: LoginRequest, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    return await AuthService.login(db, payload)


@router.post("/refresh", response_model=AccessTokenResponse, summary="Get a new access token")
async def refresh(payload: RefreshRequest, db: AsyncSession = Depends(get_db)) -> AccessTokenResponse:
    return await AuthService.refresh(db, payload.refresh_token)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT, summary="End this login session")
async def logout(payload: LogoutRequest, db: AsyncSession = Depends(get_db)) -> Response:
    await AuthService.logout(db, payload.refresh_token)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/change-password",
    response_model=TokenResponse,
    summary="Change your password; other phones are logged out and this one gets a new session",
)
async def change_password(
    payload: ChangePasswordRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    return await AuthService.change_password(db, user, payload)
