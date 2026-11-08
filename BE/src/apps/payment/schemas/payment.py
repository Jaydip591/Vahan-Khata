import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, Field

from core.briefs import AccountBrief, PartyBrief
from core.schema_types import Money

PaymentMode = Literal["cash", "online"]


class PaymentCreateRequest(BaseModel):
    party_id: uuid.UUID
    amount: Money
    mode: PaymentMode
    account_id: uuid.UUID
    paid_on: date
    note: str | None = Field(default=None, max_length=500)


class PaymentResponse(BaseModel):
    id: uuid.UUID
    party: PartyBrief
    trip_id: uuid.UUID | None
    account: AccountBrief
    amount: Decimal
    mode: str
    paid_on: date
    note: str | None
    created_at: datetime
