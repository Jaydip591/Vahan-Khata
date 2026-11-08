from sqlalchemy import func, select

from apps.place.models.place import Place
from apps.place.seed_data import SEED_PLACES
from apps.place.services.place_service import ensure_seed_places
from core.database import AsyncSessionLocal

PL = "/api/v1/places"


async def _names(client, auth, q=None, **params):
    r = await client.get(PL, params={**({"q": q} if q is not None else {}), **params}, headers=auth)
    assert r.status_code == 200, r.text
    return [(p["name_en"], p["name_gu"]) for p in r.json()]


async def test_seed_is_idempotent_and_repairs_spelling():
    async with AsyncSessionLocal() as db:
        assert await ensure_seed_places(db) == len(SEED_PLACES)
        assert await ensure_seed_places(db) == 0
        # a wrong Gujarati spelling in the database is repaired from the list
        place = (await db.execute(select(Place).where(Place.name_en == "Surat"))).scalar_one()
        place.name_gu = "wrong"
        await db.commit()
        assert await ensure_seed_places(db) == 1
        assert (await db.execute(select(Place.name_gu).where(Place.name_en == "Surat"))).scalar_one() == "સુરત"
        assert (await db.execute(select(func.count()).select_from(Place))).scalar_one() == len(SEED_PLACES)


async def test_english_search_finds_gujarati(client, auth, seeded):
    names = await _names(client, auth, "sur")
    assert ("Surat", "સુરત") in names
    assert names[0] == ("Surat", "સુરત")  # prefix match and most popular first


async def test_gujarati_search(client, auth, seeded):
    assert ("Rajkot", "રાજકોટ") in await _names(client, auth, "રાજ")


async def test_search_is_case_insensitive_and_substring(client, auth, seeded):
    assert ("Bharuch", "ભરૂચ") in await _names(client, auth, "BHAR")
    assert ("Vadodara", "વડોદરા") in await _names(client, auth, "dodar")


async def test_no_query_returns_popular_places_first(client, auth, seeded):
    names = await _names(client, auth, limit=5)
    assert names[:3] == [("Surat", "સુરત"), ("Ahmedabad", "અમદાવાદ"), ("Vadodara", "વડોદરા")]


async def test_search_with_wildcards_is_literal(client, auth, seeded):
    assert await _names(client, auth, "%") == []
    assert await _names(client, auth, "_") == []


async def test_unknown_query_returns_nothing(client, auth, seeded):
    assert await _names(client, auth, "qqqzzz") == []


async def test_add_new_place_is_private_to_company(client, auth, other_auth, seeded):
    r = await client.post(PL, json={"name_en": "Mandvi Port", "name_gu": "માંડવી પોર્ટ"}, headers=auth)
    assert r.status_code == 201 and r.json()["is_seed"] is False
    assert ("Mandvi Port", "માંડવી પોર્ટ") in await _names(client, auth, "mandvi")
    assert ("Mandvi Port", "માંડવી પોર્ટ") not in await _names(client, other_auth, "mandvi")
    # own places come before seed places when nothing is typed
    assert (await _names(client, auth))[0][0] == "Mandvi Port"


async def test_adding_existing_name_returns_the_existing_place(client, auth, seeded):
    r = await client.post(PL, json={"name_en": "surat", "name_gu": "સુરત"}, headers=auth)
    assert r.status_code == 200
    assert r.json()["is_seed"] is True and r.json()["name_en"] == "Surat"
    first = await client.post(PL, json={"name_en": "Dahisar", "name_gu": "દહીસર"}, headers=auth)
    again = await client.post(PL, json={"name_en": "DAHISAR", "name_gu": "દહીસર"}, headers=auth)
    assert first.status_code == 201 and again.status_code == 200
    assert first.json()["id"] == again.json()["id"]


async def test_place_validation_and_auth(client, auth):
    assert (await client.post(PL, json={"name_en": " ", "name_gu": "x"}, headers=auth)).status_code == 422
    assert (await client.get(PL)).status_code == 401
    assert (await client.get(f"{PL}/transliterate", params={"text": "surat"})).status_code == 401


async def test_transliterate_endpoint(client, auth, monkeypatch):
    async def fake(text, limit=4):
        return ["સુરત", "સૂરત"] if text == "surat" else []

    monkeypatch.setattr("apps.place.controllers.place_controller.transliterate_gu", fake)
    r = await client.get(f"{PL}/transliterate", params={"text": "surat"}, headers=auth)
    assert r.json() == {"suggestions": ["સુરત", "સૂરત"]}
    r = await client.get(f"{PL}/transliterate", params={"text": "zzz"}, headers=auth)
    assert r.json() == {"suggestions": []}


async def test_transliteration_never_raises_when_google_is_unreachable(monkeypatch):
    import httpx

    from apps.place.services import transliteration

    class Boom:
        def __init__(self, *a, **k): ...
        async def __aenter__(self): raise httpx.ConnectError("offline")
        async def __aexit__(self, *a): ...

    monkeypatch.setattr(transliteration.httpx, "AsyncClient", Boom)
    assert await transliteration.transliterate_gu("surat") == []
    assert await transliteration.transliterate_gu("   ") == []


async def test_transliteration_parses_google_response(monkeypatch):
    from apps.place.services import transliteration

    class Resp:
        def json(self):
            return ["SUCCESS", [["surat", ["સુરત", "સૂરત", "સુરાત"]]]]

    class Client:
        def __init__(self, *a, **k): ...
        async def __aenter__(self): return self
        async def __aexit__(self, *a): ...
        async def get(self, url, params=None): return Resp()

    monkeypatch.setattr(transliteration.httpx, "AsyncClient", Client)
    assert await transliteration.transliterate_gu("surat", limit=2) == ["સુરત", "સૂરત"]
