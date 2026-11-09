import re
import uuid
from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from core.schema_types import Name

VehicleType = Literal["eicher", "bolero", "tata_ace", "truck", "tempo", "other"]

FuelType = Literal["diesel", "petrol", "cng", "cng_petrol"]

_NUMBER_RE = re.compile(r"^[A-Z0-9][A-Z0-9 -]{3,18}[A-Z0-9]$")


def normalize_number(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip().upper())


def _check_number(value: str) -> str:
    value = normalize_number(value)
    if not _NUMBER_RE.match(value):
        raise ValueError("Enter a valid vehicle number, like GJ05 AB 1234")
    return value


class VehicleCreateRequest(BaseModel):
    vehicle_type: VehicleType
    name: Name = Field(max_length=60)
    number: str
    fuel_type: FuelType = "diesel"
    insurance_exp: date | None = None
    puc_exp: date | None = None
    fitness_exp: date | None = None
    permit_exp: date | None = None
    tax_exp: date | None = None

    @field_validator("number")
    @classmethod
    def _number(cls, v: str) -> str:
        return _check_number(v)


class VehicleUpdateRequest(BaseModel):
    vehicle_type: VehicleType | None = None
    name: Name | None = Field(default=None, max_length=60)
    number: str | None = None
    fuel_type: FuelType | None = None
    is_active: bool | None = None
    insurance_exp: date | None = None
    puc_exp: date | None = None
    fitness_exp: date | None = None
    permit_exp: date | None = None
    tax_exp: date | None = None

    @field_validator("number")
    @classmethod
    def _number(cls, v: str | None) -> str | None:
        return None if v is None else _check_number(v)


class VehicleResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    vehicle_type: str
    name: str
    number: str
    fuel_type: str
    is_active: bool
    insurance_exp: date | None
    puc_exp: date | None
    fitness_exp: date | None
    permit_exp: date | None
    tax_exp: date | None
    created_at: datetime


class NameSuggestion(BaseModel):
    name: str
