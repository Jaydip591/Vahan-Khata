from uuid import UUID

from fastapi import HTTPException, status

from sqlalchemy import case, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from apps.place.models.place import Place
from apps.place.schemas.place import PlaceCreateRequest
from apps.place.seed_data import SEED_PLACES
from apps.user.models.user import User


def _escape_like(text: str) -> str:
    return text.replace("\\", "\\\\").replace("%", r"\%").replace("_", r"\_")


class PlaceService:
    @staticmethod
    async def search(db: AsyncSession, company_id: UUID, q: str | None, limit: int = 20) -> list[Place]:
        """
        Places visible to the company: shared seed list plus the company's own.
        With no query: the company's own places first, then popular seed places.
        With a query: matches in English or Gujarati, prefix matches first.
        """
        stmt = select(Place).where(
            or_(Place.company_id == company_id, Place.company_id.is_(None)),
            Place.deleted_at.is_(None),
        )
        q = (q or "").strip()
        order = []
        if q:
            like = f"%{_escape_like(q)}%"
            prefix = f"{_escape_like(q)}%"
            stmt = stmt.where(
                or_(Place.name_en.ilike(like, escape="\\"), Place.name_gu.ilike(like, escape="\\"))
            )
            order.append(
                case(
                    (
                        or_(
                            Place.name_en.ilike(prefix, escape="\\"),
                            Place.name_gu.ilike(prefix, escape="\\"),
                        ),
                        0,
                    ),
                    else_=1,
                )
            )
        order += [Place.company_id.is_(None), Place.rank.asc().nulls_last(), Place.name_en]
        result = await db.execute(stmt.order_by(*order).limit(limit))
        return list(result.scalars().all())

    @staticmethod
    async def get_visible(db: AsyncSession, company_id: UUID, place_id: UUID) -> Place:
        """A place the company may use: shared seed place or its own."""
        result = await db.execute(
            select(Place).where(
                Place.id == place_id,
                or_(Place.company_id == company_id, Place.company_id.is_(None)),
                Place.deleted_at.is_(None),
            )
        )
        place = result.scalars().first()
        if place is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Place not found.")
        return place

    @classmethod
    async def create(cls, db: AsyncSession, actor: User, payload: PlaceCreateRequest) -> tuple[Place, bool]:
        """Returns (place, created). If the English name already exists, that place is returned."""
        existing = await db.execute(
            select(Place).where(
                or_(Place.company_id == actor.company_id, Place.company_id.is_(None)),
                Place.deleted_at.is_(None),
                func.lower(Place.name_en) == payload.name_en.lower(),
            )
        )
        found = existing.scalars().first()
        if found is not None:
            return found, False
        place = Place(
            company_id=actor.company_id,
            created_by=actor.id,
            name_en=payload.name_en,
            name_gu=payload.name_gu,
            is_seed=False,
        )
        db.add(place)
        await db.commit()
        await db.refresh(place)
        return place, True


async def ensure_seed_places(db: AsyncSession) -> int:
    """Insert missing shared places and fix spellings/rank of existing ones. Idempotent."""
    rows = await db.execute(select(Place).where(Place.is_seed.is_(True)))
    existing = {p.name_en.lower(): p for p in rows.scalars().all()}
    changed = 0
    for rank, (en, gu) in enumerate(SEED_PLACES):
        place = existing.get(en.lower())
        if place is None:
            db.add(Place(company_id=None, name_en=en, name_gu=gu, is_seed=True, rank=rank))
            changed += 1
        elif place.name_gu != gu or place.rank != rank:
            place.name_gu, place.rank = gu, rank
            changed += 1
    if changed:
        await db.commit()
    return changed
