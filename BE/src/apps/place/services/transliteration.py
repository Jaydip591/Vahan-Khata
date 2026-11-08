"""
Best-effort English -> Gujarati transliteration using Google Input Tools
(unofficial, free). Returns [] on any problem so the caller can fall back to
letting the user type the Gujarati name.
"""
import logging

import httpx

log = logging.getLogger(__name__)

_URL = "https://inputtools.google.com/request"


async def transliterate_gu(text: str, limit: int = 4) -> list[str]:
    text = text.strip()
    if not text:
        return []
    params = {
        "text": text,
        "itc": "gu-t-i0-und",
        "num": str(limit),
        "cp": "0",
        "cs": "1",
        "ie": "utf-8",
        "oe": "utf-8",
        "app": "vahan-khata",
    }
    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            r = await client.get(_URL, params=params)
        data = r.json()
        if data[0] != "SUCCESS":
            return []
        return [s for s in data[1][0][1] if isinstance(s, str)][:limit]
    except Exception as exc:  # network, JSON, shape: never break the request
        log.warning("Transliteration failed for %r: %s", text, exc)
        return []
