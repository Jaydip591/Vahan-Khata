import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict

from core.schema_types import Name, Phone


class DriverCreateRequest(BaseModel):
    name: Name
    phone: Phone = None
    default_vehicle_id: uuid.UUID | None = None


class DriverUpdateRequest(BaseModel):
    name: Name | None = None
    phone: Phone = None
    default_vehicle_id: uuid.UUID | None = None
    is_active: bool | None = None


class DriverResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    phone: str | None
    default_vehicle_id: uuid.UUID | None
    is_active: bool
    created_at: datetime
