from datetime import datetime, timezone
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from apps.account.models.account import Account
from apps.expense.models.expense import Expense
from apps.expense.schemas.expense import (
    ExpenseCreateRequest,
    ExpenseResponse,
    ExpenseUpdateRequest,
)
from apps.trip.models.trip import Trip
from apps.user.models.user import User
from apps.vehicle.models.vehicle import Vehicle
from core.briefs import AccountBrief, VehicleBrief
from core.crud import fetch_map, find_by_client_id, get_scoped
from core.dates import month_range


def _drop_irrelevant(data: dict) -> dict:
    """Diesel details only belong to diesel, repair kind only to repair."""
    category = data.get("category")
    if category is not None and category != "diesel":
        data["liters"] = data["rate"] = data["odometer"] = None
    if category is not None and category != "repair":
        data["repair_kind"] = None
    return data


class ExpenseService:
    @staticmethod
    async def to_responses(db: AsyncSession, expenses: list[Expense]) -> list[ExpenseResponse]:
        vehicles = await fetch_map(db, Vehicle, [e.vehicle_id for e in expenses])
        accounts = await fetch_map(db, Account, [e.account_id for e in expenses])
        return [
            ExpenseResponse(
                id=e.id,
                vehicle=VehicleBrief.model_validate(vehicles[e.vehicle_id]),
                trip_id=e.trip_id,
                account=AccountBrief.model_validate(accounts[e.account_id]) if e.account_id else None,
                category=e.category,
                amount=e.amount,
                expense_date=e.expense_date,
                liters=e.liters,
                rate=e.rate,
                odometer=e.odometer,
                repair_kind=e.repair_kind,
                note=e.note,
                created_at=e.created_at,
            )
            for e in expenses
        ]

    @staticmethod
    async def _check_refs(db, company_id, *, vehicle_id=None, trip_id=None, account_id=None) -> None:
        if vehicle_id:
            await get_scoped(db, Vehicle, company_id, vehicle_id, "Vehicle")
        if trip_id:
            await get_scoped(db, Trip, company_id, trip_id, "Trip")
        if account_id:
            account = await get_scoped(db, Account, company_id, account_id, "Account")
            if not account.is_active:
                raise HTTPException(status.HTTP_400_BAD_REQUEST, "This account is not active.")

    @classmethod
    async def create(cls, db: AsyncSession, actor: User, payload: ExpenseCreateRequest) -> ExpenseResponse:
        existing = await find_by_client_id(db, Expense, actor.company_id, payload.id)
        if existing is not None:
            return (await cls.to_responses(db, [existing]))[0]
        await cls._check_refs(
            db,
            actor.company_id,
            vehicle_id=payload.vehicle_id,
            trip_id=payload.trip_id,
            account_id=payload.account_id,
        )
        data = _drop_irrelevant(payload.model_dump(exclude={"id"} if payload.id is None else set()))
        expense = Expense(company_id=actor.company_id, created_by=actor.id, **data)
        db.add(expense)
        await db.commit()
        await db.refresh(expense)
        return (await cls.to_responses(db, [expense]))[0]

    @classmethod
    async def get(cls, db: AsyncSession, company_id: UUID, expense_id: UUID) -> ExpenseResponse:
        expense = await get_scoped(db, Expense, company_id, expense_id, "Expense")
        return (await cls.to_responses(db, [expense]))[0]

    @classmethod
    async def list(
        cls,
        db: AsyncSession,
        company_id: UUID,
        *,
        vehicle_id: UUID | None = None,
        trip_id: UUID | None = None,
        category: str | None = None,
        month: str | None = None,
        limit: int = 100,
        offset: int = 0,
    ) -> list[ExpenseResponse]:
        stmt = select(Expense).where(Expense.company_id == company_id, Expense.deleted_at.is_(None))
        if vehicle_id:
            stmt = stmt.where(Expense.vehicle_id == vehicle_id)
        if trip_id:
            stmt = stmt.where(Expense.trip_id == trip_id)
        if category:
            stmt = stmt.where(Expense.category == category)
        if month:
            start, end = month_range(month)
            stmt = stmt.where(Expense.expense_date >= start, Expense.expense_date < end)
        stmt = stmt.order_by(Expense.expense_date.desc(), Expense.created_at.desc()).limit(limit).offset(offset)
        rows = list((await db.execute(stmt)).scalars().all())
        return await cls.to_responses(db, rows)

    @classmethod
    async def update(
        cls, db: AsyncSession, actor: User, expense_id: UUID, payload: ExpenseUpdateRequest
    ) -> ExpenseResponse:
        expense = await get_scoped(db, Expense, actor.company_id, expense_id, "Expense")
        data = payload.model_dump(exclude_unset=True)
        for required in ("vehicle_id", "category", "amount", "expense_date"):
            if required in data and data[required] is None:
                del data[required]
        await cls._check_refs(
            db,
            actor.company_id,
            vehicle_id=data.get("vehicle_id"),
            trip_id=data.get("trip_id"),
            account_id=data.get("account_id"),
        )
        # When the category changes, details that no longer apply are cleared.
        data = _drop_irrelevant(data)
        for key, value in data.items():
            setattr(expense, key, value)
        await db.commit()
        await db.refresh(expense)
        return (await cls.to_responses(db, [expense]))[0]

    @staticmethod
    async def delete(db: AsyncSession, company_id: UUID, expense_id: UUID) -> None:
        expense = await get_scoped(db, Expense, company_id, expense_id, "Expense")
        expense.deleted_at = datetime.now(timezone.utc)
        await db.commit()
