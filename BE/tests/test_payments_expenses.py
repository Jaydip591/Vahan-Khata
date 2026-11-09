import uuid

from helpers import (
    EXP, PAY, T, make_account, make_party, make_payment, make_trip, make_vehicle, make_world,
)


# ───────────────────────── payments ─────────────────────────
async def test_payment_create_list_delete(client, auth, seeded):
    w = await make_world(client, auth)
    p = await make_payment(client, auth, w, "20000.50", paid_on="2026-11-04", note="UPI")
    assert p["amount"] == "20000.50" and p["mode"] == "online" and p["trip_id"] is None
    assert p["party"]["name"] == "Khodiyar" and p["account"]["name"] == "Cash - Jaydip"
    assert len((await client.get(PAY, headers=auth)).json()) == 1
    assert (await client.delete(f"{PAY}/{p['id']}", headers=auth)).status_code == 204
    assert (await client.get(PAY, headers=auth)).json() == []
    assert (await client.delete(f"{PAY}/{p['id']}", headers=auth)).status_code == 404


async def test_payment_validation(client, auth, seeded):
    w = await make_world(client, auth)
    base = {"party_id": w["party"], "amount": "100", "mode": "cash", "account_id": w["account"], "paid_on": "2026-11-04"}
    for bad in [
        {"amount": "0"}, {"amount": "-1"}, {"amount": "1.999"}, {"mode": "cheque"},
        {"paid_on": "yesterday"}, {"party_id": "nope"},
    ]:
        assert (await client.post(PAY, json=base | bad, headers=auth)).status_code == 422, bad
    assert (await client.post(PAY, json=base | {"party_id": str(uuid.uuid4())}, headers=auth)).status_code == 404
    assert (await client.post(PAY, json=base | {"account_id": str(uuid.uuid4())}, headers=auth)).status_code == 404
    await client.patch(f"/api/v1/accounts/{w['account']}", json={"is_active": False}, headers=auth)
    assert (await client.post(PAY, json=base, headers=auth)).status_code == 400
    assert (await client.get(PAY, headers=auth)).json() == []


async def test_payment_filters(client, auth, seeded):
    w = await make_world(client, auth)
    other = await make_party(client, auth, "Ramesh")
    a = await make_payment(client, auth, w, 100, paid_on="2026-10-30")
    b = await make_payment(client, auth, w, 200, paid_on="2026-11-02")
    c = await make_payment(client, auth, w, 300, paid_on="2026-11-08", party_id=other)

    async def ids(**params):
        return [p["id"] for p in (await client.get(PAY, params=params, headers=auth)).json()]

    assert await ids() == [c["id"], b["id"], a["id"]]
    assert await ids(month="2026-11") == [c["id"], b["id"]]
    assert await ids(party_id=w["party"]) == [b["id"], a["id"]]
    assert await ids(party_id=w["party"], month="2026-10") == [a["id"]]


async def test_payments_are_company_isolated(client, auth, other_auth, seeded):
    w = await make_world(client, auth)
    p = await make_payment(client, auth, w, 100)
    assert (await client.get(PAY, headers=other_auth)).json() == []
    assert (await client.delete(f"{PAY}/{p['id']}", headers=other_auth)).status_code == 404
    assert (await client.get(PAY)).status_code == 401
    r = await client.post(
        PAY,
        json={"party_id": w["party"], "amount": "5", "mode": "cash", "account_id": w["account"], "paid_on": "2026-11-04"},
        headers=other_auth,
    )
    assert r.status_code == 404


# ───────────────────────── expenses ─────────────────────────
def exp_body(vehicle, **over):
    return {"vehicle_id": vehicle, "category": "toll", "amount": "340", "expense_date": "2026-11-06"} | over


async def test_diesel_expense_keeps_liters_rate_odometer(client, auth):
    v = await make_vehicle(client, auth)
    r = await client.post(
        EXP,
        json=exp_body(v, category="diesel", amount="5520", liters="60", rate="92", odometer=124350),
        headers=auth,
    )
    assert r.status_code == 201
    e = r.json()
    assert e["category"] == "diesel" and e["amount"] == "5520.00"
    assert e["liters"] == "60.00" and e["rate"] == "92.00" and e["odometer"] == 124350
    assert e["vehicle"]["name"] == "Eicher 1" and e["account"] is None


async def test_irrelevant_details_are_dropped(client, auth):
    v = await make_vehicle(client, auth)
    toll = (await client.post(
        EXP, json=exp_body(v, liters="10", rate="90", odometer=5, repair_kind="tyre"), headers=auth
    )).json()
    assert toll["liters"] is None and toll["rate"] is None and toll["odometer"] is None
    assert toll["repair_kind"] is None
    repair = (await client.post(
        EXP, json=exp_body(v, category="repair", amount="4000", repair_kind="tyre"), headers=auth
    )).json()
    assert repair["repair_kind"] == "tyre"


async def test_changing_category_clears_details_that_no_longer_apply(client, auth):
    v = await make_vehicle(client, auth)
    e = (await client.post(
        EXP, json=exp_body(v, category="diesel", amount="5000", liters="50", rate="100"), headers=auth
    )).json()
    upd = await client.patch(f"{EXP}/{e['id']}", json={"category": "other", "amount": "5200"}, headers=auth)
    assert upd.status_code == 200
    body = upd.json()
    assert body["category"] == "other" and body["amount"] == "5200.00"
    assert body["liters"] is None and body["rate"] is None


async def test_expense_validation(client, auth):
    v = await make_vehicle(client, auth)
    for bad in [
        {"amount": "0"}, {"amount": "-5"}, {"category": "party"}, {"expense_date": "x"},
        {"category": "diesel", "liters": "0"}, {"category": "diesel", "odometer": -1},
        {"category": "repair", "repair_kind": "wheel"},
    ]:
        assert (await client.post(EXP, json=exp_body(v, **bad), headers=auth)).status_code == 422, bad
    assert (await client.post(EXP, json=exp_body(str(uuid.uuid4())), headers=auth)).status_code == 404
    assert (await client.get(EXP, headers=auth)).json() == []


async def test_expense_links_to_trip_and_account_of_the_company(client, auth, other_auth, seeded):
    w = await make_world(client, auth)
    trip = await make_trip(client, auth, w)
    ok = await client.post(
        EXP, json=exp_body(w["vehicle"], trip_id=trip["id"], account_id=w["account"]), headers=auth
    )
    assert ok.status_code == 201 and ok.json()["trip_id"] == trip["id"]
    assert ok.json()["account"]["name"] == "Cash - Jaydip"
    theirs = await make_account(client, other_auth)
    assert (await client.post(EXP, json=exp_body(w["vehicle"], account_id=theirs), headers=auth)).status_code == 404
    assert (await client.post(EXP, json=exp_body(w["vehicle"], trip_id=str(uuid.uuid4())), headers=auth)).status_code == 404


async def test_expense_filters_update_delete(client, auth):
    v1 = await make_vehicle(client, auth)
    v2 = await make_vehicle(client, auth, "Bolero", "GJ05 CD 5678")
    a = (await client.post(EXP, json=exp_body(v1, expense_date="2026-10-31"), headers=auth)).json()
    b = (await client.post(EXP, json=exp_body(v1, category="diesel", amount="900", expense_date="2026-11-02"), headers=auth)).json()
    c = (await client.post(EXP, json=exp_body(v2, expense_date="2026-11-07"), headers=auth)).json()

    async def ids(**params):
        r = await client.get(EXP, params=params, headers=auth)
        assert r.status_code == 200, r.text
        return [e["id"] for e in r.json()]

    assert await ids() == [c["id"], b["id"], a["id"]]
    assert await ids(month="2026-11") == [c["id"], b["id"]]
    assert await ids(vehicle_id=v1) == [b["id"], a["id"]]
    assert await ids(category="diesel") == [b["id"]]
    assert await ids(vehicle_id=v2, month="2026-11", category="toll") == [c["id"]]

    got = await client.get(f"{EXP}/{a['id']}", headers=auth)
    assert got.json()["id"] == a["id"]
    assert (await client.delete(f"{EXP}/{a['id']}", headers=auth)).status_code == 204
    assert (await client.get(f"{EXP}/{a['id']}", headers=auth)).status_code == 404
    assert await ids() == [c["id"], b["id"]]


async def test_deleting_a_trip_unlinks_its_expenses(client, auth, seeded):
    w = await make_world(client, auth)
    trip = await make_trip(client, auth, w)
    e = (await client.post(EXP, json=exp_body(w["vehicle"], trip_id=trip["id"]), headers=auth)).json()
    await client.delete(f"{T}/{trip['id']}", headers=auth)
    again = (await client.get(f"{EXP}/{e['id']}", headers=auth)).json()
    assert again["trip_id"] is None and again["amount"] == "340.00"


async def test_expenses_are_company_isolated(client, auth, other_auth):
    v = await make_vehicle(client, auth)
    e = (await client.post(EXP, json=exp_body(v), headers=auth)).json()
    assert (await client.get(EXP)).status_code == 401
    assert (await client.get(EXP, headers=other_auth)).json() == []
    assert (await client.get(f"{EXP}/{e['id']}", headers=other_auth)).status_code == 404
    assert (await client.patch(f"{EXP}/{e['id']}", json={"amount": "1"}, headers=other_auth)).status_code == 404
    assert (await client.delete(f"{EXP}/{e['id']}", headers=other_auth)).status_code == 404
    assert (await client.post(EXP, json=exp_body(v), headers=other_auth)).status_code == 404


async def test_petrol_and_cng_keep_fuel_details_other_categories_drop_them(client, auth):
    v = await make_vehicle(client, auth)
    for cat in ("petrol", "cng"):
        r = await client.post(EXP, json=exp_body(v, category=cat, amount="900", liters="9", rate="100", odometer=500), headers=auth)
        assert r.status_code == 201 and r.json()["liters"] == "9.00" and r.json()["odometer"] == 500
    r = await client.post(EXP, json=exp_body(v, category="toll", liters="9", odometer=500), headers=auth)
    assert r.json()["liters"] is None and r.json()["odometer"] is None
