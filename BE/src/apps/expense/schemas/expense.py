import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, Field

from core.briefs import AccountBrief, PayeeBrief, VehicleBrief
from core.schema_types import Money

ExpenseCategory = Literal["diesel", "petrol", "cng", "toll", "repair", "allowance", "challan", "other"]
FUEL_CATEGORIES = ("diesel", "petrol", "cng")
RepairKind = Literal["tyre", "oil", "engine", "battery", "service", "other"]


class ExpenseCreateRequest(BaseModel):
    # Optional client-made id: lets the app retry a save (e.g. after being offline) without making a duplicate.
    id: uuid.UUID | None = None
    vehicle_id: uuid.UUID
    trip_id: uuid.UUID | None = None
    account_id: uuid.UUID | None = None
    category: ExpenseCategory
    amount: Money
    expense_date: date
    # Only kept for the matching category, ignored otherwise
    liters: Decimal | None = Field(default=None, gt=0, max_digits=10, decimal_places=2)
    rate: Decimal | None = Field(default=None, gt=0, max_digits=10, decimal_places=2)
    odometer: int | None = Field(default=None, ge=0, le=9_999_999)
    repair_kind: RepairKind | None = None
    note: str | None = Field(default=None, max_length=500)
    payee_id: uuid.UUID | None = None
    upi_ref: str | None = Field(default=None, max_length=40)


class ExpenseUpdateRequest(BaseModel):
    vehicle_id: uuid.UUID | None = None
    trip_id: uuid.UUID | None = None
    account_id: uuid.UUID | None = None
    category: ExpenseCategory | None = None
    amount: Money | None = None
    expense_date: date | None = None
    liters: Decimal | None = Field(default=None, gt=0, max_digits=10, decimal_places=2)
    rate: Decimal | None = Field(default=None, gt=0, max_digits=10, decimal_places=2)
    odometer: int | None = Field(default=None, ge=0, le=9_999_999)
    repair_kind: RepairKind | None = None
    note: str | None = Field(default=None, max_length=500)


class ExpenseResponse(BaseModel):
    id: uuid.UUID
    vehicle: VehicleBrief
    trip_id: uuid.UUID | None
    account: AccountBrief | None
    category: str
    amount: Decimal
    expense_date: date
    liters: Decimal | None
    rate: Decimal | None
    odometer: int | None
    repair_kind: str | None
    note: str | None
    payee: PayeeBrief | None = None
    upi_ref: str | None = None
    created_at: datetime
