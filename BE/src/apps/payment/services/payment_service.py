from datetime import datetime, timezone
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from apps.account.models.account import Account
from apps.party.models.party import Party
from apps.payment.models.payment import Payment
from apps.payment.schemas.payment import PaymentCreateRequest, PaymentResponse
from apps.user.models.user import User
from core.briefs import AccountBrief, PartyBrief
from core.crud import fetch_map, find_by_client_id, get_scoped
from core.dates import month_range


class PaymentService:
    @staticmethod
    async def to_responses(db: AsyncSession, payments: list[Payment]) -> list[PaymentResponse]:
        parties = await fetch_map(db, Party, [p.party_id for p in payments])
        accounts = await fetch_map(db, Account, [p.account_id for p in payments])
        return [
            PaymentResponse(
                id=p.id,
                party=PartyBrief.model_validate(parties[p.party_id]),
                trip_id=p.trip_id,
                account=AccountBrief.model_validate(accounts[p.account_id]),
                amount=p.amount,
                mode=p.mode,
                paid_on=p.paid_on,
                note=p.note,
                created_at=p.created_at,
            )
            for p in payments
        ]

    @classmethod
    async def create(cls, db: AsyncSession, actor: User, payload: PaymentCreateRequest) -> PaymentResponse:
        existing = await find_by_client_id(db, Payment, actor.company_id, payload.id)
        if existing is not None:
            return (await cls.to_responses(db, [existing]))[0]
        await get_scoped(db, Party, actor.company_id, payload.party_id, "Party")
        account = await get_scoped(db, Account, actor.company_id, payload.account_id, "Account")
        if not account.is_active:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "This account is not active.")
        payment = Payment(
            company_id=actor.company_id,
            created_by=actor.id,
            received_by=actor.id,
            **payload.model_dump(exclude={"id"} if payload.id is None else set()),
        )
        db.add(payment)
        await db.commit()
        await db.refresh(payment)
        return (await cls.to_responses(db, [payment]))[0]

    @classmethod
    async def list(
        cls,
        db: AsyncSession,
        company_id: UUID,
        *,
        party_id: UUID | None = None,
        month: str | None = None,
        limit: int = 100,
        offset: int = 0,
    ) -> list[PaymentResponse]:
        stmt = select(Payment).where(Payment.company_id == company_id, Payment.deleted_at.is_(None))
        if party_id:
            stmt = stmt.where(Payment.party_id == party_id)
        if month:
            start, end = month_range(month)
            stmt = stmt.where(Payment.paid_on >= start, Payment.paid_on < end)
        stmt = stmt.order_by(Payment.paid_on.desc(), Payment.created_at.desc()).limit(limit).offset(offset)
        rows = list((await db.execute(stmt)).scalars().all())
        return await cls.to_responses(db, rows)

    @staticmethod
    async def delete(db: AsyncSession, company_id: UUID, payment_id: UUID) -> None:
        payment = await get_scoped(db, Payment, company_id, payment_id, "Payment")
        payment.deleted_at = datetime.now(timezone.utc)
        await db.commit()

