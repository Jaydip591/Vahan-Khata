from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from apps.user.models.user import User
from apps.vehicle.models.vehicle import Vehicle
from apps.vehicle.schemas.vehicle import VehicleCreateRequest, VehicleUpdateRequest
from core.crud import apply_updates, get_scoped, list_scoped, soft_delete

TYPE_LABELS = {
    "eicher": "Eicher",
    "bolero": "Bolero",
    "tata_ace": "Tata Ace",
    "truck": "Truck",
    "tempo": "Tempo",
    "other": "Vehicle",
}


class VehicleService:
    @staticmethod
    async def list(db: AsyncSession, company_id: UUID, include_inactive: bool) -> list[Vehicle]:
        return await list_scoped(db, Vehicle, company_id, include_inactive=include_inactive)

    @staticmethod
    async def get(db: AsyncSession, company_id: UUID, vehicle_id: UUID) -> Vehicle:
        return await get_scoped(db, Vehicle, company_id, vehicle_id, "Vehicle")

    @staticmethod
    async def _ensure_number_free(
        db: AsyncSession, company_id: UUID, number: str, exclude_id: UUID | None = None
    ) -> None:
        key = number.replace(" ", "").replace("-", "")
        stmt = select(Vehicle.id).where(
            Vehicle.company_id == company_id,
            Vehicle.deleted_at.is_(None),
            func.replace(func.replace(Vehicle.number, " ", ""), "-", "") == key,
        )
        if exclude_id is not None:
            stmt = stmt.where(Vehicle.id != exclude_id)
        if (await db.execute(stmt.limit(1))).first() is not None:
            raise HTTPException(status.HTTP_409_CONFLICT, "A vehicle with this number already exists.")

    @classmethod
    async def create(cls, db: AsyncSession, actor: User, payload: VehicleCreateRequest) -> Vehicle:
        await cls._ensure_number_free(db, actor.company_id, payload.number)
        vehicle = Vehicle(company_id=actor.company_id, created_by=actor.id, **payload.model_dump())
        db.add(vehicle)
        await db.commit()
        await db.refresh(vehicle)
        return vehicle

    @classmethod
    async def update(
        cls, db: AsyncSession, actor: User, vehicle_id: UUID, payload: VehicleUpdateRequest
    ) -> Vehicle:
        vehicle = await cls.get(db, actor.company_id, vehicle_id)
        data = payload.model_dump(exclude_unset=True)
        # name / number / type / is_active can't be cleared; dates can.
        for required in ("vehicle_type", "name", "number", "is_active"):
            if required in data and data[required] is None:
                del data[required]
        if "number" in data:
            await cls._ensure_number_free(db, actor.company_id, data["number"], vehicle.id)
        apply_updates(vehicle, data)
        await db.commit()
        await db.refresh(vehicle)
        return vehicle

    @classmethod
    async def delete(cls, db: AsyncSession, company_id: UUID, vehicle_id: UUID) -> None:
        await soft_delete(db, await cls.get(db, company_id, vehicle_id))

    @staticmethod
    async def suggest_name(db: AsyncSession, company_id: UUID, vehicle_type: str) -> str:
        """Next free name for a type: 'Eicher 1', 'Eicher 2', ..."""
        label = TYPE_LABELS.get(vehicle_type, "Vehicle")
        rows = await db.execute(
            select(Vehicle.name).where(
                Vehicle.company_id == company_id, Vehicle.deleted_at.is_(None)
            )
        )
        used = {n.lower() for (n,) in rows.all()}
        n = 1
        while f"{label} {n}".lower() in used:
            n += 1
        return f"{label} {n}"
