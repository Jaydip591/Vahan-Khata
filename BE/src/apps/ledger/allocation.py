"""
apps/ledger/allocation.py

Pure functions (no database) that work out how much of each trip has been paid.

Rules
1. A payment linked to a trip (an advance) goes to that trip first. If it is more
   than the trip's bhada, the extra joins the pool.
2. Every other payment joins the pool.
3. The pool pays trips oldest first (by trip date, then by creation order).

The party balance is simply total bhada minus total payments, so it never depends
on these rules; they only decide which trips show as paid, partly paid or unpaid.
"""
from dataclasses import dataclass
from datetime import date
from decimal import Decimal
from typing import Hashable, Sequence

ZERO = Decimal("0")


@dataclass(frozen=True)
class TripAmount:
    id: Hashable
    trip_date: date
    order: int  # tie-breaker for trips on the same date (e.g. creation order)
    bhada: Decimal


@dataclass(frozen=True)
class PaymentAmount:
    amount: Decimal
    trip_id: Hashable | None = None


@dataclass(frozen=True)
class Allocation:
    paid: dict[Hashable, Decimal]  # trip id -> amount paid
    credit: Decimal  # money left over after every trip is fully paid


def allocate(trips: Sequence[TripAmount], payments: Sequence[PaymentAmount]) -> Allocation:
    paid: dict[Hashable, Decimal] = {t.id: ZERO for t in trips}
    bhada = {t.id: t.bhada for t in trips}
    pool = ZERO

    for p in payments:
        if p.trip_id in paid:
            room = bhada[p.trip_id] - paid[p.trip_id]
            used = min(p.amount, room)
            paid[p.trip_id] += used
            pool += p.amount - used
        else:
            pool += p.amount

    for t in sorted(trips, key=lambda t: (t.trip_date, t.order)):
        if pool <= ZERO:
            break
        room = bhada[t.id] - paid[t.id]
        take = min(pool, room)
        paid[t.id] += take
        pool -= take

    return Allocation(paid=paid, credit=pool)


def pay_status(bhada: Decimal, paid: Decimal) -> str:
    if paid <= ZERO:
        return "unpaid"
    if paid >= bhada:
        return "paid"
    return "partial"
