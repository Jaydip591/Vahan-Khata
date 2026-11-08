from uuid import UUID

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from apps.account.schemas.account import (
    AccountCreateRequest,
    AccountResponse,
    AccountUpdateRequest,
)
from apps.account.services.account_service import AccountService
from apps.user.models.user import User
from core.dependencies import get_current_user, get_db

router = APIRouter(prefix="/accounts", tags=["Accounts"])


@router.get("", response_model=list[AccountResponse])
async def list_accounts(
    include_inactive: bool = False,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await AccountService.list(db, user.company_id, include_inactive)


@router.post("", response_model=AccountResponse, status_code=status.HTTP_201_CREATED)
async def create_account(
    payload: AccountCreateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await AccountService.create(db, user, payload)


@router.get("/{item_id}", response_model=AccountResponse)
async def get_account(
    item_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await AccountService.get(db, user.company_id, item_id)


@router.patch("/{item_id}", response_model=AccountResponse)
async def update_account(
    item_id: UUID,
    payload: AccountUpdateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await AccountService.update(db, user, item_id, payload)


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(
    item_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await AccountService.delete(db, user.company_id, item_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
