from uuid import UUID

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from apps.driver.schemas.driver import (
    DriverCreateRequest,
    DriverResponse,
    DriverUpdateRequest,
)
from apps.driver.services.driver_service import DriverService
from apps.user.models.user import User
from core.dependencies import get_current_user, get_db

router = APIRouter(prefix="/drivers", tags=["Drivers"])


@router.get("", response_model=list[DriverResponse])
async def list_drivers(
    include_inactive: bool = False,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await DriverService.list(db, user.company_id, include_inactive)


@router.post("", response_model=DriverResponse, status_code=status.HTTP_201_CREATED)
async def create_driver(
    payload: DriverCreateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await DriverService.create(db, user, payload)


@router.get("/{item_id}", response_model=DriverResponse)
async def get_driver(
    item_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await DriverService.get(db, user.company_id, item_id)


@router.patch("/{item_id}", response_model=DriverResponse)
async def update_driver(
    item_id: UUID,
    payload: DriverUpdateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await DriverService.update(db, user, item_id, payload)


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_driver(
    item_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await DriverService.delete(db, user.company_id, item_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
