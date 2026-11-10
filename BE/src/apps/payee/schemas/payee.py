import re
import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, field_validator

from core.schema_types import Name

# handle@bank: letters, digits, dot, dash, underscore before the @, letters after it.
_UPI_RE = re.compile(r"^[A-Za-z0-9._-]{1,256}@[A-Za-z][A-Za-z0-9.]{1,63}$")


def _check_upi(v: str) -> str:
    v = v.strip()
    if not _UPI_RE.match(v):
        raise ValueError("UPI id must look like name@bank")
    return v


class PayeeCreateRequest(BaseModel):
    name: Name
    upi_id: str

    @field_validator("upi_id")
    @classmethod
    def _upi(cls, v: str) -> str:
        return _check_upi(v)


class PayeeUpdateRequest(BaseModel):
    name: Name | None = None
    upi_id: str | None = None
    is_active: bool | None = None

    @field_validator("upi_id")
    @classmethod
    def _upi(cls, v: str | None) -> str | None:
        return None if v is None else _check_upi(v)


class PayeeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    upi_id: str
    is_active: bool
    created_at: datetime
