import uuid
from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from core.schema_types import Name

AccountKind = Literal["cash", "bank", "upi"]


class AccountCreateRequest(BaseModel):
    name: Name
    kind: AccountKind
    opening_balance: Decimal = Field(default=Decimal("0"), ge=0, max_digits=12, decimal_places=2)


class AccountUpdateRequest(BaseModel):
    name: Name | None = None
    kind: AccountKind | None = None
    opening_balance: Decimal | None = Field(default=None, ge=0, max_digits=12, decimal_places=2)
    is_active: bool | None = None


class AccountResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    kind: str
    opening_balance: Decimal
    is_active: bool
    created_at: datetime
