"""
core/crud.py

Small helpers shared by the master-data modules (vehicles, drivers, parties, accounts).
Every helper is company scoped and ignores soft-deleted rows.
"""
from datetime import datetime, timezone
from typing import Any, Sequence, TypeVar
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

T = TypeVar("T")


async def list_scoped(
    db: AsyncSession,
    model: type[T],
    company_id: UUID,
    *,
    include_inactive: bool = False,
    where: Sequence[Any] = (),
    order_by: Sequence[Any] | None = None,
) -> list[T]:
    stmt = select(model).where(
        model.company_id == company_id, model.deleted_at.is_(None), *where
    )
    if not include_inactive and hasattr(model, "is_active"):
        stmt = stmt.where(model.is_active.is_(True))
    stmt = stmt.order_by(*(order_by or (model.created_at,)))
    return list((await db.execute(stmt)).scalars().all())


async def get_scoped(
    db: AsyncSession, model: type[T], company_id: UUID, obj_id: UUID, label: str = "Item"
) -> T:
    result = await db.execute(
        select(model).where(
            model.id == obj_id,
            model.company_id == company_id,
            model.deleted_at.is_(None),
        )
    )
    obj = result.scalars().first()
    if obj is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"{label} not found.")
    return obj


async def ensure_unique(
    db: AsyncSession,
    model: type[T],
    company_id: UUID,
    column: Any,
    value: str,
    *,
    exclude_id: UUID | None = None,
    message: str,
) -> None:
    """Raise 409 if another live row in the company has the same value (case-insensitive)."""
    stmt = select(model.id).where(
        model.company_id == company_id,
        model.deleted_at.is_(None),
        func.lower(column) == value.lower(),
    )
    if exclude_id is not None:
        stmt = stmt.where(model.id != exclude_id)
    if (await db.execute(stmt.limit(1))).first() is not None:
        raise HTTPException(status.HTTP_409_CONFLICT, message)


def apply_updates(obj: Any, data: dict[str, Any]) -> None:
    for key, value in data.items():
        setattr(obj, key, value)


async def soft_delete(db: AsyncSession, obj: Any) -> None:
    obj.deleted_at = datetime.now(timezone.utc)
    await db.commit()


async def fetch_map(db: AsyncSession, model: type[T], ids: Any) -> dict[UUID, T]:
    """Load rows by id into a dict. Ids come from already company-scoped rows."""
    ids = {i for i in ids if i is not None}
    if not ids:
        return {}
    rows = await db.execute(select(model).where(model.id.in_(ids)))
    return {r.id: r for r in rows.scalars().all()}


async def find_by_client_id(db: AsyncSession, model: type[T], company_id: UUID, obj_id: UUID | None) -> T | None:
    """The row a client already created with this id, so a retried save returns it instead of
    making a duplicate. An id that belongs to another company is refused."""
    if obj_id is None:
        return None
    obj = (await db.execute(select(model).where(model.id == obj_id))).scalars().first()
    if obj is None:
        return None
    if obj.company_id != company_id:
        raise HTTPException(status.HTTP_409_CONFLICT, "This id is already used.")
    return obj
