import re
import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

from core.security import MAX_PASSWORD_BYTES

_USERNAME_RE = re.compile(r"^[a-z0-9._-]{3,32}$")
_PHONE_RE = re.compile(r"^\+?[0-9]{10,14}$")


def _check_phone(value: str | None) -> str | None:
    """Spaces and dashes are dropped; an empty value clears the phone."""
    if value is None:
        return None
    v = re.sub(r"[\s-]", "", value)
    if not v:
        return ""
    if not _PHONE_RE.match(v):
        raise ValueError("Phone must be 10-14 digits")
    return v


def _check_password_bytes(value: str) -> str:
    if len(value.encode()) > MAX_PASSWORD_BYTES:
        raise ValueError("Password is too long")
    return value


# ── Request Schemas ────────────────────────────────────────────────────────────

class UserCreateRequest(BaseModel):
    username: str
    password: str = Field(min_length=6, max_length=72)
    name: str = Field(min_length=1, max_length=100)
    phone: str | None = None

    @field_validator("phone")
    @classmethod
    def _phone(cls, v: str | None) -> str | None:
        return _check_phone(v) or None

    @field_validator("username")
    @classmethod
    def _username(cls, v: str) -> str:
        v = v.strip().lower()
        if not _USERNAME_RE.match(v):
            raise ValueError(
                "Username must be 3-32 characters: letters, digits, dot, dash or underscore"
            )
        return v

    @field_validator("password")
    @classmethod
    def _pw(cls, v: str) -> str:
        return _check_password_bytes(v)


class UserUpdateRequest(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    password: str | None = Field(default=None, min_length=6, max_length=72)
    is_active: bool | None = None
    phone: str | None = None  # "" clears it

    @field_validator("phone")
    @classmethod
    def _phone(cls, v: str | None) -> str | None:
        return _check_phone(v)

    @field_validator("password")
    @classmethod
    def _pw(cls, v: str | None) -> str | None:
        return None if v is None else _check_password_bytes(v)


class ProfileUpdateRequest(BaseModel):
    """What a user may change about themself."""

    name: str | None = Field(default=None, min_length=1, max_length=100)
    phone: str | None = None  # "" clears it

    @field_validator("phone")
    @classmethod
    def _phone(cls, v: str | None) -> str | None:
        return _check_phone(v)


class ChangePasswordRequest(BaseModel):
    old_password: str = Field(min_length=1, max_length=200)
    new_password: str = Field(min_length=6, max_length=72)

    @field_validator("new_password")
    @classmethod
    def _pw(cls, v: str) -> str:
        return _check_password_bytes(v)


# ── Response Schemas ───────────────────────────────────────────────────────────

class UserResponse(BaseModel):
    """Public-facing user representation – never exposes password_hash."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    username: str
    name: str
    role: str
    is_active: bool
    phone: str | None = None
    created_at: datetime


class MeResponse(UserResponse):
    company_name: str
