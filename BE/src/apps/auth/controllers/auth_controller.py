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
from core.dependencies import get_db

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
