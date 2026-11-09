import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, Field

from apps.payment.schemas.payment import PaymentMode
from core.briefs import DriverBrief, PartyBrief, PlaceBrief, VehicleBrief
from core.schema_types import Money

TripStatus = Literal["running", "closed"]
PayStatus = Literal["unpaid", "partial", "paid"]


class AdvanceInput(BaseModel):
    """Money received together with the trip. Becomes a payment linked to the trip."""

    amount: Money
    mode: PaymentMode
    account_id: uuid.UUID


class TripCreateRequest(BaseModel):
    # Optional client-made id: lets the app retry a save (e.g. after being offline) without making a duplicate.
    id: uuid.UUID | None = None
    vehicle_id: uuid.UUID
    driver_id: uuid.UUID | None = None
    party_id: uuid.UUID
    from_place_id: uuid.UUID
    to_place_id: uuid.UUID
    trip_date: date
    bhada: Money
    note: str | None = Field(default=None, max_length=500)
    advance: AdvanceInput | None = None


class TripUpdateRequest(BaseModel):
    vehicle_id: uuid.UUID | None = None
    driver_id: uuid.UUID | None = None
    party_id: uuid.UUID | None = None
    from_place_id: uuid.UUID | None = None
    to_place_id: uuid.UUID | None = None
    trip_date: date | None = None
    bhada: Money | None = None
    note: str | None = Field(default=None, max_length=500)
    status: TripStatus | None = None


class TripResponse(BaseModel):
    id: uuid.UUID
    vehicle: VehicleBrief
    driver: DriverBrief | None
    party: PartyBrief
    from_place: PlaceBrief
    to_place: PlaceBrief
    trip_date: date
    bhada: Decimal
    advance: Decimal  # payments linked to this trip
    paid: Decimal  # everything counted against this trip (advance + share of other payments)
    due: Decimal
    pay_status: PayStatus
    status: TripStatus
    note: str | None
    created_at: datetime


class RecentRoute(BaseModel):
    from_place: PlaceBrief
    to_place: PlaceBrief
    trips: int
    last_bhada: Decimal
    last_trip_date: date
