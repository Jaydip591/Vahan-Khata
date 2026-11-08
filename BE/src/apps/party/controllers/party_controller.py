from uuid import UUID

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from apps.party.schemas.party import (
    PartyCreateRequest,
    PartyResponse,
    PartyUpdateRequest,
)
from apps.party.services.party_service import PartyService
from apps.user.models.user import User
from core.dependencies import get_current_user, get_db

router = APIRouter(prefix="/parties", tags=["Partys"])


@router.get("", response_model=list[PartyResponse])
async def list_parties(
    include_inactive: bool = False,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await PartyService.list(db, user.company_id, include_inactive)


@router.post("", response_model=PartyResponse, status_code=status.HTTP_201_CREATED)
async def create_party(
    payload: PartyCreateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await PartyService.create(db, user, payload)


@router.get("/{item_id}", response_model=PartyResponse)
async def get_party(
    item_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await PartyService.get(db, user.company_id, item_id)


@router.patch("/{item_id}", response_model=PartyResponse)
async def update_party(
    item_id: UUID,
    payload: PartyUpdateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await PartyService.update(db, user, item_id, payload)


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_party(
    item_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await PartyService.delete(db, user.company_id, item_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
