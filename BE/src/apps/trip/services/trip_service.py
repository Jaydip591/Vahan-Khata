from collections import defaultdict
from datetime import datetime, timezone
from decimal import Decimal
from uuid import UUID, uuid5

from fastapi import HTTPException, status
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from apps.account.models.account import Account
from apps.driver.models.driver import Driver
from apps.expense.models.expense import Expense
from apps.ledger.allocation import PaymentAmount, TripAmount, allocate, pay_status
from apps.party.models.party import Party
from apps.payment.models.payment import Payment
from apps.place.models.place import Place
from apps.place.services.place_service import PlaceService
from apps.trip.models.trip import STATUS_RUNNING, Trip
from apps.trip.schemas.trip import (
    RecentRoute,
    TripCreateRequest,
    TripResponse,
    TripUpdateRequest,
)
from apps.user.models.user import User
from apps.vehicle.models.vehicle import Vehicle
from core.briefs import DriverBrief, PartyBrief, PlaceBrief, VehicleBrief
from core.crud import fetch_map, find_by_client_id, get_scoped
from core.dates import month_range

ZERO = Decimal("0")


async def party_trips_and_payments(
    db: AsyncSession, company_id: UUID, party_ids: set[UUID]
) -> tuple[dict[UUID, list[Trip]], dict[UUID, list[Payment]]]:
    """All live trips and payments of the given parties, grouped by party."""
    trips_by: dict[UUID, list[Trip]] = defaultdict(list)
    pays_by: dict[UUID, list[Payment]] = defaultdict(list)
    if not party_ids:
        return trips_by, pays_by
    trips = await db.execute(
        select(Trip)
        .where(Trip.company_id == company_id, Trip.deleted_at.is_(None), Trip.party_id.in_(party_ids))
        .order_by(Trip.trip_date, Trip.created_at)
    )
    for t in trips.scalars().all():
        trips_by[t.party_id].append(t)
    pays = await db.execute(
        select(Payment).where(
            Payment.company_id == company_id,
            Payment.deleted_at.is_(None),
            Payment.party_id.in_(party_ids),
        )
    )
    for p in pays.scalars().all():
        pays_by[p.party_id].append(p)
    return trips_by, pays_by


def party_allocation(trips: list[Trip], payments: list[Payment]):
    return allocate(
        [TripAmount(t.id, t.trip_date, i, t.bhada) for i, t in enumerate(trips)],
        [PaymentAmount(p.amount, p.trip_id) for p in payments],
    )


class TripService:
    # ───────────────────────── building responses ─────────────────────────
    @staticmethod
    async def to_responses(db: AsyncSession, company_id: UUID, trips: list[Trip]) -> list[TripResponse]:
        vehicles = await fetch_map(db, Vehicle, [t.vehicle_id for t in trips])
        drivers = await fetch_map(db, Driver, [t.driver_id for t in trips])
        parties = await fetch_map(db, Party, [t.party_id for t in trips])
        places = await fetch_map(
            db, Place, [t.from_place_id for t in trips] + [t.to_place_id for t in trips]
        )
        party_ids = {t.party_id for t in trips}
        trips_by, pays_by = await party_trips_and_payments(db, company_id, party_ids)
        paid: dict[UUID, Decimal] = {}
        for pid in party_ids:
            paid.update(party_allocation(trips_by[pid], pays_by[pid]).paid)
        advance: dict[UUID, Decimal] = defaultdict(lambda: ZERO)
        for plist in pays_by.values():
            for p in plist:
                if p.trip_id is not None:
                    advance[p.trip_id] += p.amount

        out = []
        for t in trips:
            p = paid.get(t.id, ZERO)
            out.append(
                TripResponse(
                    id=t.id,
                    vehicle=VehicleBrief.model_validate(vehicles[t.vehicle_id]),
                    driver=DriverBrief.model_validate(drivers[t.driver_id]) if t.driver_id else None,
                    party=PartyBrief.model_validate(parties[t.party_id]),
                    from_place=PlaceBrief.model_validate(places[t.from_place_id]),
                    to_place=PlaceBrief.model_validate(places[t.to_place_id]),
                    trip_date=t.trip_date,
                    bhada=t.bhada,
                    advance=advance[t.id],
                    paid=p,
                    due=t.bhada - p,
                    pay_status=pay_status(t.bhada, p),
                    status=t.status,
                    note=t.note,
                    created_at=t.created_at,
                )
            )
        return out

    # ───────────────────────── validation ─────────────────────────
    @staticmethod
    async def _check_refs(
        db: AsyncSession,
        company_id: UUID,
        *,
        vehicle_id=None,
        driver_id=None,
        party_id=None,
        place_ids=(),
        account_id=None,
    ) -> None:
        if vehicle_id:
            await get_scoped(db, Vehicle, company_id, vehicle_id, "Vehicle")
        if driver_id:
            await get_scoped(db, Driver, company_id, driver_id, "Driver")
        if party_id:
            await get_scoped(db, Party, company_id, party_id, "Party")
        for pid in place_ids:
            await PlaceService.get_visible(db, company_id, pid)
        if account_id:
            account = await get_scoped(db, Account, company_id, account_id, "Account")
            if not account.is_active:
                raise HTTPException(status.HTTP_400_BAD_REQUEST, "This account is not active.")

    # ───────────────────────── operations ─────────────────────────
    @classmethod
    async def create(cls, db: AsyncSession, actor: User, payload: TripCreateRequest) -> TripResponse:
        existing = await find_by_client_id(db, Trip, actor.company_id, payload.id)
        if existing is not None:  # a retried save: already stored, with its advance
            return (await cls.to_responses(db, actor.company_id, [existing]))[0]
        adv = payload.advance
        await cls._check_refs(
            db,
            actor.company_id,
            vehicle_id=payload.vehicle_id,
            driver_id=payload.driver_id,
            party_id=payload.party_id,
            place_ids=(payload.from_place_id, payload.to_place_id),
            account_id=adv.account_id if adv else None,
        )
        if adv and adv.amount > payload.bhada:
            raise HTTPException(422, "Advance cannot be more than the bhada.")

        trip = Trip(
            company_id=actor.company_id,
            created_by=actor.id,
            **payload.model_dump(exclude={"advance"} | ({"id"} if payload.id is None else set())),
        )
        db.add(trip)
        await db.flush()
        if adv:
            db.add(
                Payment(
                    id=uuid5(trip.id, "advance"),  # fixed id, so a retry can never add a second advance
                    company_id=actor.company_id,
                    created_by=actor.id,
                    received_by=actor.id,
                    party_id=payload.party_id,
                    trip_id=trip.id,
                    account_id=adv.account_id,
                    amount=adv.amount,
                    mode=adv.mode,
                    paid_on=payload.trip_date,
                )
            )
        await db.commit()
        await db.refresh(trip)
        return (await cls.to_responses(db, actor.company_id, [trip]))[0]

    @classmethod
    async def get(cls, db: AsyncSession, company_id: UUID, trip_id: UUID) -> TripResponse:
        trip = await get_scoped(db, Trip, company_id, trip_id, "Trip")
        return (await cls.to_responses(db, company_id, [trip]))[0]

    @classmethod
    async def list(
        cls,
        db: AsyncSession,
        company_id: UUID,
        *,
        vehicle_id: UUID | None = None,
        party_id: UUID | None = None,
        month: str | None = None,
        trip_status: str | None = None,
        unpaid_only: bool = False,
        limit: int = 100,
        offset: int = 0,
    ) -> list[TripResponse]:
        stmt = select(Trip).where(Trip.company_id == company_id, Trip.deleted_at.is_(None))
        if vehicle_id:
            stmt = stmt.where(Trip.vehicle_id == vehicle_id)
        if party_id:
            stmt = stmt.where(Trip.party_id == party_id)
        if trip_status:
            stmt = stmt.where(Trip.status == trip_status)
        if month:
            start, end = month_range(month)
            stmt = stmt.where(Trip.trip_date >= start, Trip.trip_date < end)
        stmt = stmt.order_by(Trip.trip_date.desc(), Trip.created_at.desc())
        if not unpaid_only:
            stmt = stmt.limit(limit).offset(offset)
        trips = list((await db.execute(stmt)).scalars().all())
        out = await cls.to_responses(db, company_id, trips)
        if unpaid_only:
            out = [t for t in out if t.pay_status != "paid"][offset : offset + limit]
        return out

    @classmethod
    async def update(
        cls, db: AsyncSession, actor: User, trip_id: UUID, payload: TripUpdateRequest
    ) -> TripResponse:
        trip = await get_scoped(db, Trip, actor.company_id, trip_id, "Trip")
        data = payload.model_dump(exclude_unset=True)
        for required in ("vehicle_id", "party_id", "from_place_id", "to_place_id", "trip_date", "bhada", "status"):
            if required in data and data[required] is None:
                del data[required]
        await cls._check_refs(
            db,
            actor.company_id,
            vehicle_id=data.get("vehicle_id"),
            driver_id=data.get("driver_id"),
            party_id=data.get("party_id"),
            place_ids=[data[k] for k in ("from_place_id", "to_place_id") if k in data],
        )
        old_party = trip.party_id
        for key, value in data.items():
            setattr(trip, key, value)
        if "party_id" in data and data["party_id"] != old_party:
            # An advance belongs to the party it was received from: keep it consistent.
            await db.execute(
                update(Payment).where(Payment.trip_id == trip.id).values(party_id=trip.party_id)
            )
        await db.commit()
        await db.refresh(trip)
        return (await cls.to_responses(db, actor.company_id, [trip]))[0]

    @staticmethod
    async def delete(db: AsyncSession, company_id: UUID, trip_id: UUID) -> None:
        """Soft delete. Payments and expenses that pointed at the trip are kept, just unlinked."""
        trip = await get_scoped(db, Trip, company_id, trip_id, "Trip")
        trip.deleted_at = datetime.now(timezone.utc)
        await db.execute(update(Payment).where(Payment.trip_id == trip.id).values(trip_id=None))
        await db.execute(update(Expense).where(Expense.trip_id == trip.id).values(trip_id=None))
        await db.commit()

    @staticmethod
    async def recent_routes(db: AsyncSession, company_id: UUID, limit: int = 6) -> "list[RecentRoute]":
        """Most used routes (and the last bhada for each), for the one-tap route chips."""
        rows = await db.execute(
            select(Trip)
            .where(Trip.company_id == company_id, Trip.deleted_at.is_(None))
            .order_by(Trip.trip_date.desc(), Trip.created_at.desc())
            .limit(300)
        )
        trips = list(rows.scalars().all())
        agg: dict[tuple[UUID, UUID], dict] = {}
        for t in trips:  # newest first, so the first sighting holds the latest bhada
            key = (t.from_place_id, t.to_place_id)
            if key not in agg:
                agg[key] = {"count": 0, "bhada": t.bhada, "date": t.trip_date}
            agg[key]["count"] += 1
        top = sorted(agg.items(), key=lambda kv: (-kv[1]["count"], -kv[1]["date"].toordinal()))[:limit]
        places = await fetch_map(db, Place, [pid for (f, t), _ in top for pid in (f, t)])
        return [
            RecentRoute(
                from_place=PlaceBrief.model_validate(places[f]),
                to_place=PlaceBrief.model_validate(places[t]),
                trips=v["count"],
                last_bhada=v["bhada"],
                last_trip_date=v["date"],
            )
            for (f, t), v in top
        ]


__all__ = ["TripService", "party_trips_and_payments", "party_allocation", "STATUS_RUNNING"]
