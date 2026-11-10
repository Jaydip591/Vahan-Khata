from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from apps.payee.models.payee import Payee
from apps.payee.schemas.payee import PayeeCreateRequest, PayeeUpdateRequest
from apps.user.models.user import User
from core.crud import apply_updates, ensure_unique, get_scoped, list_scoped, soft_delete

_DUP = "This UPI id is already saved."


class PayeeService:
    @staticmethod
    async def list(db: AsyncSession, company_id: UUID, include_inactive: bool) -> list[Payee]:
        return await list_scoped(db, Payee, company_id, include_inactive=include_inactive)

    @staticmethod
    async def get(db: AsyncSession, company_id: UUID, payee_id: UUID) -> Payee:
        return await get_scoped(db, Payee, company_id, payee_id, "Payee")

    @classmethod
    async def create(cls, db: AsyncSession, actor: User, payload: PayeeCreateRequest) -> Payee:
        await ensure_unique(db, Payee, actor.company_id, Payee.upi_id, payload.upi_id, message=_DUP)
        payee = Payee(company_id=actor.company_id, created_by=actor.id, **payload.model_dump())
        db.add(payee)
        await db.commit()
        await db.refresh(payee)
        return payee

    @classmethod
    async def update(cls, db: AsyncSession, actor: User, payee_id: UUID, payload: PayeeUpdateRequest) -> Payee:
        payee = await cls.get(db, actor.company_id, payee_id)
        data = {k: v for k, v in payload.model_dump(exclude_unset=True).items() if v is not None}
        if "upi_id" in data:
            await ensure_unique(
                db, Payee, actor.company_id, Payee.upi_id, data["upi_id"], exclude_id=payee.id, message=_DUP
            )
        apply_updates(payee, data)
        await db.commit()
        await db.refresh(payee)
        return payee

    @classmethod
    async def delete(cls, db: AsyncSession, company_id: UUID, payee_id: UUID) -> None:
        await soft_delete(db, await cls.get(db, company_id, payee_id))
