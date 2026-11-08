"""Small builders used by the trip / payment / expense / ledger tests."""

V = "/api/v1/vehicles"
P = "/api/v1/parties"
A = "/api/v1/accounts"
D = "/api/v1/drivers"
PL = "/api/v1/places"
T = "/api/v1/trips"
PAY = "/api/v1/payments"
EXP = "/api/v1/expenses"
LED = "/api/v1/ledger"


async def make_vehicle(client, auth, name="Eicher 1", number="GJ05 AB 1234"):
    r = await client.post(V, json={"vehicle_type": "eicher", "name": name, "number": number}, headers=auth)
    assert r.status_code == 201, r.text
    return r.json()["id"]


async def make_party(client, auth, name="Khodiyar"):
    r = await client.post(P, json={"name": name}, headers=auth)
    assert r.status_code == 201, r.text
    return r.json()["id"]


async def make_account(client, auth, name="Cash - Jaydip", kind="cash"):
    r = await client.post(A, json={"name": name, "kind": kind}, headers=auth)
    assert r.status_code == 201, r.text
    return r.json()["id"]


async def place_id(client, auth, name_en):
    r = await client.get(PL, params={"q": name_en}, headers=auth)
    return next(p["id"] for p in r.json() if p["name_en"] == name_en)


async def make_world(client, auth):
    """One vehicle, party, account and two seed places. Needs the `seeded` fixture."""
    return {
        "vehicle": await make_vehicle(client, auth),
        "party": await make_party(client, auth),
        "account": await make_account(client, auth),
        "surat": await place_id(client, auth, "Surat"),
        "vapi": await place_id(client, auth, "Vapi"),
        "valsad": await place_id(client, auth, "Valsad"),
    }


def trip_body(w, **over):
    body = {
        "vehicle_id": w["vehicle"],
        "party_id": w["party"],
        "from_place_id": w["surat"],
        "to_place_id": w["vapi"],
        "trip_date": "2026-11-05",
        "bhada": "12000",
    }
    return body | over


async def make_trip(client, auth, w, **over):
    r = await client.post(T, json=trip_body(w, **over), headers=auth)
    assert r.status_code == 201, r.text
    return r.json()


async def make_payment(client, auth, w, amount, paid_on="2026-11-10", **over):
    body = {
        "party_id": w["party"],
        "amount": str(amount),
        "mode": "online",
        "account_id": w["account"],
        "paid_on": paid_on,
    } | over
    r = await client.post(PAY, json=body, headers=auth)
    assert r.status_code == 201, r.text
    return r.json()
