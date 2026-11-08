from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from apps.driver.models.driver import Driver
from apps.driver.schemas.driver import DriverCreateRequest, DriverUpdateRequest
from apps.user.models.user import User
from apps.vehicle.models.vehicle import Vehicle
from core.crud import apply_updates, get_scoped, list_scoped, soft_delete


class DriverService:
    @staticmethod
    async def list(db: AsyncSession, company_id: UUID, include_inactive: bool) -> list[Driver]:
        return await list_scoped(db, Driver, company_id, include_inactive=include_inactive)

    @staticmethod
    async def get(db: AsyncSession, company_id: UUID, driver_id: UUID) -> Driver:
        return await get_scoped(db, Driver, company_id, driver_id, "Driver")

    @staticmethod
    async def _check_vehicle(db: AsyncSession, company_id: UUID, vehicle_id: UUID | None) -> None:
        if vehicle_id is not None:
            await get_scoped(db, Vehicle, company_id, vehicle_id, "Vehicle")

    @classmethod
    async def create(cls, db: AsyncSession, actor: User, payload: DriverCreateRequest) -> Driver:
        await cls._check_vehicle(db, actor.company_id, payload.default_vehicle_id)
        driver = Driver(company_id=actor.company_id, created_by=actor.id, **payload.model_dump())
        db.add(driver)
        await db.commit()
        await db.refresh(driver)
        return driver

    @classmethod
    async def update(
        cls, db: AsyncSession, actor: User, driver_id: UUID, payload: DriverUpdateRequest
    ) -> Driver:
        driver = await cls.get(db, actor.company_id, driver_id)
        data = payload.model_dump(exclude_unset=True)
        for required in ("name", "is_active"):
            if required in data and data[required] is None:
                del data[required]
        if "default_vehicle_id" in data:
            await cls._check_vehicle(db, actor.company_id, data["default_vehicle_id"])
        apply_updates(driver, data)
        await db.commit()
        await db.refresh(driver)
        return driver

    @classmethod
    async def delete(cls, db: AsyncSession, company_id: UUID, driver_id: UUID) -> None:
        await soft_delete(db, await cls.get(db, company_id, driver_id))
