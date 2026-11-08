from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from apps.party.models.party import Party
from apps.party.schemas.party import PartyCreateRequest, PartyUpdateRequest
from apps.user.models.user import User
from core.crud import apply_updates, ensure_unique, get_scoped, list_scoped, soft_delete

_DUP = "A party with this name already exists."


class PartyService:
    @staticmethod
    async def list(db: AsyncSession, company_id: UUID, include_inactive: bool) -> list[Party]:
        return await list_scoped(
            db, Party, company_id, include_inactive=include_inactive, order_by=(Party.name,)
        )

    @staticmethod
    async def get(db: AsyncSession, company_id: UUID, party_id: UUID) -> Party:
        return await get_scoped(db, Party, company_id, party_id, "Party")

    @classmethod
    async def create(cls, db: AsyncSession, actor: User, payload: PartyCreateRequest) -> Party:
        await ensure_unique(db, Party, actor.company_id, Party.name, payload.name, message=_DUP)
        party = Party(company_id=actor.company_id, created_by=actor.id, **payload.model_dump())
        db.add(party)
        await db.commit()
        await db.refresh(party)
        return party

    @classmethod
    async def update(
        cls, db: AsyncSession, actor: User, party_id: UUID, payload: PartyUpdateRequest
    ) -> Party:
        party = await cls.get(db, actor.company_id, party_id)
        data = payload.model_dump(exclude_unset=True)
        for required in ("name", "is_active"):
            if required in data and data[required] is None:
                del data[required]
        if "name" in data:
            await ensure_unique(
                db, Party, actor.company_id, Party.name, data["name"], exclude_id=party.id, message=_DUP
            )
        apply_updates(party, data)
        await db.commit()
        await db.refresh(party)
        return party

    @classmethod
    async def delete(cls, db: AsyncSession, company_id: UUID, party_id: UUID) -> None:
        await soft_delete(db, await cls.get(db, company_id, party_id))
