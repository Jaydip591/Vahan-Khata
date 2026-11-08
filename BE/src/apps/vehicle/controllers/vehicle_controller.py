from uuid import UUID

from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from apps.user.models.user import User
from apps.vehicle.schemas.vehicle import (
    NameSuggestion,
    VehicleCreateRequest,
    VehicleResponse,
    VehicleType,
    VehicleUpdateRequest,
)
from apps.vehicle.services.vehicle_service import VehicleService
from core.dependencies import get_current_user, get_db

router = APIRouter(prefix="/vehicles", tags=["Vehicles"])


@router.get("", response_model=list[VehicleResponse])
async def list_vehicles(
    include_inactive: bool = False,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await VehicleService.list(db, user.company_id, include_inactive)


@router.get("/suggest-name", response_model=NameSuggestion, summary="Next free name for a vehicle type")
async def suggest_name(
    type: VehicleType = Query(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return NameSuggestion(name=await VehicleService.suggest_name(db, user.company_id, type))


@router.post("", response_model=VehicleResponse, status_code=status.HTTP_201_CREATED)
async def create_vehicle(
    payload: VehicleCreateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await VehicleService.create(db, user, payload)


@router.get("/{vehicle_id}", response_model=VehicleResponse)
async def get_vehicle(
    vehicle_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await VehicleService.get(db, user.company_id, vehicle_id)


@router.patch("/{vehicle_id}", response_model=VehicleResponse)
async def update_vehicle(
    vehicle_id: UUID,
    payload: VehicleUpdateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await VehicleService.update(db, user, vehicle_id, payload)


@router.delete("/{vehicle_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_vehicle(
    vehicle_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await VehicleService.delete(db, user.company_id, vehicle_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
