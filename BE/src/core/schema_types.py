"""Reusable pydantic field types for request schemas."""
import re
from decimal import Decimal
from typing import Annotated

from pydantic import AfterValidator, Field, StringConstraints

_PHONE_RE = re.compile(r"^\+?[0-9]{7,15}$")


def _clean_phone(value: str | None) -> str | None:
    if value is None:
        return None
    digits = re.sub(r"[\s\-()]", "", value)
    if digits == "":
        return None
    if not _PHONE_RE.match(digits):
        raise ValueError("Enter a valid phone number")
    return digits


def _collapse_spaces(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


# Trimmed, single-spaced, 1-100 chars.
Name = Annotated[
    str,
    StringConstraints(strip_whitespace=True, min_length=1, max_length=100),
    AfterValidator(_collapse_spaces),
]

Phone = Annotated[str | None, AfterValidator(_clean_phone)]

# Positive money with at most 2 decimals, fits Numeric(12,2).
Money = Annotated[Decimal, Field(gt=0, max_digits=12, decimal_places=2)]
