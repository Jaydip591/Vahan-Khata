from decimal import Decimal
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from apps.ledger.allocation import pay_status
from apps.ledger.schemas.ledger import (
    LedgerParty,
    LedgerTrip,
    PartyBalance,
    PartyBalances,
    PartyLedger,
)
from apps.party.models.party import Party
from apps.payment.services.payment_service import PaymentService
from apps.place.models.place import Place
from apps.trip.services.trip_service import party_allocation, party_trips_and_payments
from apps.vehicle.models.vehicle import Vehicle
from core.briefs import PlaceBrief
from core.crud import fetch_map, get_scoped

ZERO = Decimal("0")


class LedgerService:
    @staticmethod
    async def balances(db: AsyncSession, company_id: UUID) -> PartyBalances:
        """Every party with what they owe, oldest unpaid trip first."""
        parties = list(
            (
                await db.execute(
                    select(Party).where(Party.company_id == company_id, Party.deleted_at.is_(None))
                )
            )
            .scalars()
            .all()
        )
        trips_by, pays_by = await party_trips_and_payments(db, company_id, {p.id for p in parties})
        rows: list[PartyBalance] = []
        for party in parties:
            trips, pays = trips_by[party.id], pays_by[party.id]
            alloc = party_allocation(trips, pays)
            unpaid = [t for t in trips if alloc.paid[t.id] < t.bhada]
            rows.append(
                PartyBalance(
                    party_id=party.id,
                    party_name=party.name,
                    balance=sum((t.bhada for t in trips), ZERO) - sum((p.amount for p in pays), ZERO),
                    unpaid_trips=len(unpaid),
                    oldest_unpaid_date=min((t.trip_date for t in unpaid), default=None),
                )
            )
        # Owing parties first (oldest unpaid on top), then settled ones by name.
        rows.sort(
            key=lambda r: (
                r.balance <= ZERO,
                r.oldest_unpaid_date.toordinal() if r.oldest_unpaid_date else 10**9,
                r.party_name.lower(),
            )
        )
        return PartyBalances(
            total_due=sum((r.balance for r in rows if r.balance > ZERO), ZERO), parties=rows
        )

    @staticmethod
    async def party_ledger(db: AsyncSession, company_id: UUID, party_id: UUID) -> PartyLedger:
        party = await get_scoped(db, Party, company_id, party_id, "Party")
        trips_by, pays_by = await party_trips_and_payments(db, company_id, {party.id})
        trips, pays = trips_by[party.id], pays_by[party.id]
        alloc = party_allocation(trips, pays)
        vehicles = await fetch_map(db, Vehicle, [t.vehicle_id for t in trips])
        places = await fetch_map(db, Place, [t.from_place_id for t in trips] + [t.to_place_id for t in trips])
        total_bhada = sum((t.bhada for t in trips), ZERO)
        total_paid = sum((p.amount for p in pays), ZERO)
        pays_sorted = sorted(pays, key=lambda p: (p.paid_on, p.created_at), reverse=True)
        return PartyLedger(
            party=LedgerParty(id=party.id, name=party.name, phone=party.phone),
            total_bhada=total_bhada,
            total_paid=total_paid,
            balance=total_bhada - total_paid,
            trips=[
                LedgerTrip(
                    id=t.id,
                    trip_date=t.trip_date,
                    from_place=PlaceBrief.model_validate(places[t.from_place_id]),
                    to_place=PlaceBrief.model_validate(places[t.to_place_id]),
                    vehicle_name=vehicles[t.vehicle_id].name,
                    bhada=t.bhada,
                    paid=alloc.paid[t.id],
                    due=t.bhada - alloc.paid[t.id],
                    pay_status=pay_status(t.bhada, alloc.paid[t.id]),
                )
                for t in reversed(trips)  # newest first
            ],
            payments=await PaymentService.to_responses(db, pays_sorted),
        )
