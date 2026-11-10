from uuid import UUID

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from apps.payee.schemas.payee import (
    PayeeCreateRequest,
    PayeeResponse,
    PayeeUpdateRequest,
)
from apps.payee.services.payee_service import PayeeService
from apps.user.models.user import User
from core.dependencies import get_current_user, get_db

router = APIRouter(prefix="/payees", tags=["UPI payees"])


@router.get("", response_model=list[PayeeResponse])
async def list_payees(
    include_inactive: bool = False,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await PayeeService.list(db, user.company_id, include_inactive)


@router.post("", response_model=PayeeResponse, status_code=status.HTTP_201_CREATED)
async def create_payee(
    payload: PayeeCreateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await PayeeService.create(db, user, payload)


@router.get("/{item_id}", response_model=PayeeResponse)
async def get_payee(
    item_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await PayeeService.get(db, user.company_id, item_id)


@router.patch("/{item_id}", response_model=PayeeResponse)
async def update_payee(
    item_id: UUID,
    payload: PayeeUpdateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await PayeeService.update(db, user, item_id, payload)


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_payee(
    item_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await PayeeService.delete(db, user.company_id, item_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
