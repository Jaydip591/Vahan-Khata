import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict

from core.schema_types import Name, Phone

PaymentCycle = Literal["daily", "ten_days", "monthly"]


class PartyCreateRequest(BaseModel):
    name: Name
    phone: Phone = None
    payment_cycle: PaymentCycle | None = None


class PartyUpdateRequest(BaseModel):
    name: Name | None = None
    phone: Phone = None
    payment_cycle: PaymentCycle | None = None
    is_active: bool | None = None


class PartyResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    phone: str | None
    payment_cycle: str | None
    is_active: bool
    created_at: datetime
