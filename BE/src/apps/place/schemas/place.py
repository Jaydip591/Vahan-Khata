import re
import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


def _clean(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


class PlaceCreateRequest(BaseModel):
    name_en: str = Field(min_length=1, max_length=100)
    name_gu: str = Field(min_length=1, max_length=100)

    @field_validator("name_en", "name_gu")
    @classmethod
    def _strip(cls, v: str) -> str:
        v = _clean(v)
        if not v:
            raise ValueError("Name cannot be empty")
        return v


class PlaceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name_en: str
    name_gu: str
    is_seed: bool
    created_at: datetime


class TransliterationResponse(BaseModel):
    suggestions: list[str]
