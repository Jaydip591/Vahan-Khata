import re
from datetime import date

from fastapi import HTTPException, status

_MONTH_RE = re.compile(r"^(\d{4})-(0[1-9]|1[0-2])$")


def month_range(month: str) -> tuple[date, date]:
    """'2026-11' -> (2026-11-01, 2026-12-01). The end is exclusive."""
    m = _MONTH_RE.match(month)
    if not m:
        raise HTTPException(422, "month must look like 2026-11")
    year, mon = int(m.group(1)), int(m.group(2))
    start = date(year, mon, 1)
    end = date(year + (mon == 12), 1 if mon == 12 else mon + 1, 1)
    return start, end
