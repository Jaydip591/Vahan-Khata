import uuid

import pytest

V = "/api/v1/vehicles"
D = "/api/v1/drivers"
P = "/api/v1/parties"
A = "/api/v1/accounts"

VEHICLE = {"vehicle_type": "eicher", "name": "Eicher 1", "number": "gj05 ab 1234"}


# ───────────────────────── vehicles ─────────────────────────
async def test_vehicle_crud(client, auth):
    r = await client.post(V, json=VEHICLE, headers=auth)
    assert r.status_code == 201
    v = r.json()
    assert v["number"] == "GJ05 AB 1234"  # normalised
    assert v["is_active"] is True and v["insurance_exp"] is None

    got = await client.get(f"{V}/{v['id']}", headers=auth)
    assert got.json()["name"] == "Eicher 1"

    upd = await client.patch(
        f"{V}/{v['id']}", json={"name": "Eicher Red", "insurance_exp": "2027-03-01"}, headers=auth
    )
    assert upd.status_code == 200
    assert upd.json()["name"] == "Eicher Red" and upd.json()["insurance_exp"] == "2027-03-01"

    # a date can be cleared again by sending null
    clr = await client.patch(f"{V}/{v['id']}", json={"insurance_exp": None}, headers=auth)
    assert clr.json()["insurance_exp"] is None

    assert (await client.delete(f"{V}/{v['id']}", headers=auth)).status_code == 204
    assert (await client.get(f"{V}/{v['id']}", headers=auth)).status_code == 404
    assert (await client.get(V, headers=auth)).json() == []


async def test_vehicle_validation(client, auth):
    bad_number = await client.post(V, json=VEHICLE | {"number": "!!"}, headers=auth)
    assert bad_number.status_code == 422
    bad_type = await client.post(V, json=VEHICLE | {"vehicle_type": "rocket"}, headers=auth)
    assert bad_type.status_code == 422
    empty = await client.post(V, json=VEHICLE | {"name": "   "}, headers=auth)
    assert empty.status_code == 422


async def test_vehicle_number_must_be_unique_ignoring_spaces_and_case(client, auth):
    await client.post(V, json=VEHICLE, headers=auth)
    dup = await client.post(V, json=VEHICLE | {"name": "Other", "number": "GJ05AB1234"}, headers=auth)
    assert dup.status_code == 409
    other = await client.post(V, json=VEHICLE | {"name": "Bolero", "vehicle_type": "bolero", "number": "GJ05 CD 5678"}, headers=auth)
    assert other.status_code == 201
    clash = await client.patch(f"{V}/{other.json()['id']}", json={"number": "gj05-ab-1234"}, headers=auth)
    assert clash.status_code == 409


async def test_deleted_vehicle_number_can_be_reused(client, auth):
    vid = (await client.post(V, json=VEHICLE, headers=auth)).json()["id"]
    await client.delete(f"{V}/{vid}", headers=auth)
    assert (await client.post(V, json=VEHICLE, headers=auth)).status_code == 201


async def test_inactive_vehicles_hidden_unless_asked(client, auth):
    vid = (await client.post(V, json=VEHICLE, headers=auth)).json()["id"]
    await client.patch(f"{V}/{vid}", json={"is_active": False}, headers=auth)
    assert (await client.get(V, headers=auth)).json() == []
    assert len((await client.get(V, params={"include_inactive": True}, headers=auth)).json()) == 1


async def test_vehicle_name_suggestion(client, auth):
    s = await client.get(f"{V}/suggest-name", params={"type": "eicher"}, headers=auth)
    assert s.json() == {"name": "Eicher 1"}
    await client.post(V, json=VEHICLE, headers=auth)
    await client.post(V, json=VEHICLE | {"name": "Eicher 2", "number": "GJ05 CD 5678"}, headers=auth)
    assert (await client.get(f"{V}/suggest-name", params={"type": "eicher"}, headers=auth)).json()["name"] == "Eicher 3"
    assert (await client.get(f"{V}/suggest-name", params={"type": "tata_ace"}, headers=auth)).json()["name"] == "Tata Ace 1"
    assert (await client.get(f"{V}/suggest-name", params={"type": "nope"}, headers=auth)).status_code == 422


async def test_suggestion_fills_gaps(client, auth):
    await client.post(V, json=VEHICLE | {"name": "Eicher 2", "number": "GJ05 CD 5678"}, headers=auth)
    assert (await client.get(f"{V}/suggest-name", params={"type": "eicher"}, headers=auth)).json()["name"] == "Eicher 1"


# ───────────────────────── drivers ─────────────────────────
async def test_driver_crud_and_phone_cleaning(client, auth):
    r = await client.post(D, json={"name": "  Ramesh   Bhai ", "phone": "98765 43210"}, headers=auth)
    assert r.status_code == 201
    d = r.json()
    assert d["name"] == "Ramesh Bhai" and d["phone"] == "9876543210"
    upd = await client.patch(f"{D}/{d['id']}", json={"phone": None}, headers=auth)
    assert upd.json()["phone"] is None
    assert (await client.post(D, json={"name": "X", "phone": "abc"}, headers=auth)).status_code == 422
    assert (await client.delete(f"{D}/{d['id']}", headers=auth)).status_code == 204
    assert (await client.get(D, headers=auth)).json() == []


async def test_driver_default_vehicle_must_exist_in_company(client, auth, other_auth):
    vid = (await client.post(V, json=VEHICLE, headers=other_auth)).json()["id"]
    cross = await client.post(D, json={"name": "A", "default_vehicle_id": vid}, headers=auth)
    assert cross.status_code == 404
    mine = (await client.post(V, json=VEHICLE, headers=auth)).json()["id"]
    ok = await client.post(D, json={"name": "A", "default_vehicle_id": mine}, headers=auth)
    assert ok.status_code == 201 and ok.json()["default_vehicle_id"] == mine
    assert (await client.patch(f"{D}/{ok.json()['id']}", json={"default_vehicle_id": str(uuid.uuid4())}, headers=auth)).status_code == 404


# ───────────────────────── parties ─────────────────────────
async def test_party_crud_unique_name_and_cycle(client, auth):
    r = await client.post(P, json={"name": "ખોડિયાર ટ્રેડર્સ", "payment_cycle": "ten_days"}, headers=auth)
    assert r.status_code == 201 and r.json()["payment_cycle"] == "ten_days"
    assert (await client.post(P, json={"name": "ખોડિયાર ટ્રેડર્સ"}, headers=auth)).status_code == 409
    b = await client.post(P, json={"name": "Ramesh"}, headers=auth)
    assert (await client.post(P, json={"name": "RAMESH"}, headers=auth)).status_code == 409
    assert (await client.patch(f"{P}/{b.json()['id']}", json={"name": "ખોડિયાર ટ્રેડર્સ"}, headers=auth)).status_code == 409
    assert (await client.post(P, json={"name": "Z", "payment_cycle": "weekly"}, headers=auth)).status_code == 422
    names = [p["name"] for p in (await client.get(P, headers=auth)).json()]
    assert names == sorted(names)


async def test_party_name_reusable_after_delete(client, auth):
    pid = (await client.post(P, json={"name": "ABC"}, headers=auth)).json()["id"]
    await client.delete(f"{P}/{pid}", headers=auth)
    assert (await client.post(P, json={"name": "ABC"}, headers=auth)).status_code == 201


# ───────────────────────── accounts ─────────────────────────
async def test_account_crud_and_money_rules(client, auth):
    r = await client.post(A, json={"name": "Cash - Jaydip", "kind": "cash", "opening_balance": "1500.50"}, headers=auth)
    assert r.status_code == 201
    assert r.json()["opening_balance"] == "1500.50"  # exact decimal string, no float noise
    assert (await client.post(A, json={"name": "cash - jaydip", "kind": "cash"}, headers=auth)).status_code == 409
    assert (await client.post(A, json={"name": "X", "kind": "crypto"}, headers=auth)).status_code == 422
    assert (await client.post(A, json={"name": "Y", "kind": "bank", "opening_balance": "-5"}, headers=auth)).status_code == 422
    assert (await client.post(A, json={"name": "Y", "kind": "bank", "opening_balance": "1.234"}, headers=auth)).status_code == 422
    upd = await client.patch(f"{A}/{r.json()['id']}", json={"kind": "bank"}, headers=auth)
    assert upd.json()["kind"] == "bank" and upd.json()["name"] == "Cash - Jaydip"


# ───────────────────────── shared behaviour ─────────────────────────
@pytest.mark.parametrize(
    "url,body",
    [
        (V, VEHICLE),
        (D, {"name": "Ramesh"}),
        (P, {"name": "ABC Plastic"}),
        (A, {"name": "UPI - Bhai", "kind": "upi"}),
    ],
)
async def test_masters_require_login_and_are_company_isolated(client, auth, other_auth, url, body):
    assert (await client.get(url)).status_code == 401
    assert (await client.post(url, json=body)).status_code == 401

    item = (await client.post(url, json=body, headers=auth)).json()
    # Another company sees nothing and cannot read, change or delete it
    assert (await client.get(url, headers=other_auth)).json() == []
    assert (await client.get(f"{url}/{item['id']}", headers=other_auth)).status_code == 404
    assert (await client.patch(f"{url}/{item['id']}", json={"is_active": False}, headers=other_auth)).status_code == 404
    assert (await client.delete(f"{url}/{item['id']}", headers=other_auth)).status_code == 404
    # Same data can exist in both companies without a uniqueness clash
    assert (await client.post(url, json=body, headers=other_auth)).status_code == 201
    # and the original is untouched
    assert (await client.get(f"{url}/{item['id']}", headers=auth)).json()["id"] == item["id"]


async def test_vehicle_fuel_type_defaults_to_diesel_and_can_change(client, auth):
    r = await client.post(V, json=VEHICLE, headers=auth)
    assert r.json()["fuel_type"] == "diesel"
    vid = r.json()["id"]
    r = await client.patch(f"{V}/{vid}", json={"fuel_type": "cng_petrol"}, headers=auth)
    assert r.status_code == 200 and r.json()["fuel_type"] == "cng_petrol"
    made = await client.post(V, json=VEHICLE | {"name": "Carry", "number": "GJ05 CD 5678", "fuel_type": "cng"}, headers=auth)
    assert made.json()["fuel_type"] == "cng"
    bad = await client.post(V, json=VEHICLE | {"name": "X", "number": "GJ05 EF 9999", "fuel_type": "water"}, headers=auth)
    assert bad.status_code == 422
