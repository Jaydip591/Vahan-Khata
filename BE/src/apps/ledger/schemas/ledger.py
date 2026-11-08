import uuid
from datetime import date
from decimal import Decimal

from pydantic import BaseModel

from apps.payment.schemas.payment import PaymentResponse
from apps.trip.schemas.trip import PayStatus
from core.briefs import PlaceBrief


class PartyBalance(BaseModel):
    party_id: uuid.UUID
    party_name: str
    balance: Decimal  # positive = the party owes us
    unpaid_trips: int
    oldest_unpaid_date: date | None


class PartyBalances(BaseModel):
    total_due: Decimal  # sum of all positive balances
    parties: list[PartyBalance]


class LedgerTrip(BaseModel):
    id: uuid.UUID
    trip_date: date
    from_place: PlaceBrief
    to_place: PlaceBrief
    vehicle_name: str
    bhada: Decimal
    paid: Decimal
    due: Decimal
    pay_status: PayStatus


class LedgerParty(BaseModel):
    id: uuid.UUID
    name: str
    phone: str | None


class PartyLedger(BaseModel):
    party: LedgerParty
    total_bhada: Decimal
    total_paid: Decimal
    balance: Decimal
    trips: list[LedgerTrip]
    payments: list[PaymentResponse]
