"""
apps/user/controllers/user_controller.py

Thin controller layer: only request/response handling.
All logic is delegated to UserService.
"""
from uuid import UUID

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from apps.user.models.user import User
from apps.company.models.company import Company
from apps.user.schemas.user import (
    MeResponse,
    ProfileUpdateRequest,
    UserCreateRequest,
    UserResponse,
    UserUpdateRequest,
)
from apps.user.services.user_service import UserService
from core.dependencies import get_current_user, get_db, require_superadmin

router = APIRouter(prefix="/users", tags=["Users"])


async def _me(db: AsyncSession, user: User) -> MeResponse:
    company = await db.get(Company, user.company_id)
    return MeResponse(
        **UserResponse.model_validate(user).model_dump(), company_name=company.name if company else ""
    )


@router.get("/me", response_model=MeResponse, summary="Get the logged-in user and their company")
async def get_me(
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
) -> MeResponse:
    return await _me(db, current_user)


@router.patch("/me", response_model=MeResponse, summary="Change your own name or phone")
async def update_me(
    payload: ProfileUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> MeResponse:
    user = await UserService.update_profile(db, current_user, payload)
    return await _me(db, user)


@router.get("", response_model=list[UserResponse], summary="List users of the company")
async def list_users(
    current_user: User = Depends(require_superadmin),
    db: AsyncSession = Depends(get_db),
) -> list[UserResponse]:
    users = await UserService.list_for_company(db, current_user.company_id)
    return [UserResponse.model_validate(u) for u in users]


@router.post(
    "",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a user (superadmin only)",
)
async def create_user(
    payload: UserCreateRequest,
    current_user: User = Depends(require_superadmin),
    db: AsyncSession = Depends(get_db),
) -> UserResponse:
    user = await UserService.create(db, current_user, payload)
    return UserResponse.model_validate(user)


@router.patch("/{user_id}", response_model=UserResponse, summary="Update a user (superadmin only)")
async def update_user(
    user_id: UUID,
    payload: UserUpdateRequest,
    current_user: User = Depends(require_superadmin),
    db: AsyncSession = Depends(get_db),
) -> UserResponse:
    user = await UserService.update(db, current_user, user_id, payload)
    return UserResponse.model_validate(user)
