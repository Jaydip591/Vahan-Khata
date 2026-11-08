from uuid import UUID

from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from apps.trip.schemas.trip import (
    RecentRoute,
    TripCreateRequest,
    TripResponse,
    TripStatus,
    TripUpdateRequest,
)
from apps.trip.services.trip_service import TripService
from apps.user.models.user import User
from core.dependencies import get_current_user, get_db

router = APIRouter(prefix="/trips", tags=["Trips"])


@router.get("", response_model=list[TripResponse])
async def list_trips(
    vehicle_id: UUID | None = None,
    party_id: UUID | None = None,
    month: str | None = Query(default=None, description="YYYY-MM"),
    status: TripStatus | None = None,
    unpaid_only: bool = False,
    limit: int = Query(default=100, ge=1, le=300),
    offset: int = Query(default=0, ge=0),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await TripService.list(
        db,
        user.company_id,
        vehicle_id=vehicle_id,
        party_id=party_id,
        month=month,
        trip_status=status,
        unpaid_only=unpaid_only,
        limit=limit,
        offset=offset,
    )


@router.get("/routes/recent", response_model=list[RecentRoute], summary="Most used routes with last bhada")
async def recent_routes(
    user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    return await TripService.recent_routes(db, user.company_id)


@router.post("", response_model=TripResponse, status_code=status.HTTP_201_CREATED)
async def create_trip(
    payload: TripCreateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await TripService.create(db, user, payload)


@router.get("/{trip_id}", response_model=TripResponse)
async def get_trip(
    trip_id: UUID, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    return await TripService.get(db, user.company_id, trip_id)


@router.patch("/{trip_id}", response_model=TripResponse)
async def update_trip(
    trip_id: UUID,
    payload: TripUpdateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await TripService.update(db, user, trip_id, payload)


@router.delete("/{trip_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_trip(
    trip_id: UUID, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    await TripService.delete(db, user.company_id, trip_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
