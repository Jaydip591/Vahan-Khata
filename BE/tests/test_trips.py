import uuid
from decimal import Decimal

from helpers import PAY, T, make_account, make_payment, make_trip, make_vehicle, make_world, trip_body


async def test_create_trip_without_advance(client, auth, seeded):
    w = await make_world(client, auth)
    t = await make_trip(client, auth, w)
    assert t["bhada"] == "12000.00" and Decimal(t["advance"]) == 0
    assert t["due"] == "12000.00" and t["pay_status"] == "unpaid" and t["status"] == "running"
    assert t["from_place"]["name_gu"] == "સુરત" and t["to_place"]["name_gu"] == "વાપી"
    assert t["vehicle"]["number"] == "GJ05 AB 1234" and t["driver"] is None


async def test_full_advance_marks_trip_paid_and_creates_a_linked_payment(client, auth, seeded):
    w = await make_world(client, auth)
    t = await make_trip(
        client, auth, w, advance={"amount": "12000", "mode": "cash", "account_id": w["account"]}
    )
    assert t["pay_status"] == "paid" and Decimal(t["due"]) == 0 and t["advance"] == "12000.00"
    pays = (await client.get(PAY, headers=auth)).json()
    assert len(pays) == 1
    assert pays[0]["trip_id"] == t["id"] and pays[0]["amount"] == "12000.00"
    assert pays[0]["mode"] == "cash" and pays[0]["paid_on"] == "2026-11-05"
    assert pays[0]["account"]["name"] == "Cash - Jaydip"


async def test_half_advance_is_partial(client, auth, seeded):
    w = await make_world(client, auth)
    t = await make_trip(
        client, auth, w, advance={"amount": "6000", "mode": "online", "account_id": w["account"]}
    )
    assert t["pay_status"] == "partial" and t["due"] == "6000.00" and t["paid"] == "6000.00"


async def test_decimal_amounts_stay_exact(client, auth, seeded):
    w = await make_world(client, auth)
    t = await make_trip(
        client, auth, w, bhada="12000.50",
        advance={"amount": "0.10", "mode": "cash", "account_id": w["account"]},
    )
    assert t["bhada"] == "12000.50" and t["advance"] == "0.10" and t["due"] == "12000.40"


async def test_trip_validation(client, auth, seeded):
    w = await make_world(client, auth)
    adv = lambda amt: {"amount": amt, "mode": "cash", "account_id": w["account"]}  # noqa: E731
    cases = [
        trip_body(w, bhada="0"),
        trip_body(w, bhada="-5"),
        trip_body(w, bhada="1.234"),
        trip_body(w, bhada="1000000000000"),
        trip_body(w, trip_date="not-a-date"),
        trip_body(w, bhada="100", advance=adv("101")),  # advance more than bhada
        trip_body(w, advance=adv("0")),
        trip_body(w, advance={"amount": "5", "mode": "cheque", "account_id": w["account"]}),
    ]
    for body in cases:
        r = await client.post(T, json=body, headers=auth)
        assert r.status_code == 422, (body, r.text)
    assert (await client.get(T, headers=auth)).json() == []


async def test_references_must_exist_in_the_company(client, auth, other_auth, seeded):
    w = await make_world(client, auth)
    theirs_vehicle = await make_vehicle(client, other_auth)
    theirs_account = await make_account(client, other_auth)
    ghost = str(uuid.uuid4())
    for field, bad in [
        ("vehicle_id", theirs_vehicle),
        ("vehicle_id", ghost),
        ("party_id", ghost),
        ("from_place_id", ghost),
        ("driver_id", ghost),
    ]:
        r = await client.post(T, json=trip_body(w, **{field: bad}), headers=auth)
        assert r.status_code == 404, (field, r.text)
    r = await client.post(
        T,
        json=trip_body(w, advance={"amount": "5", "mode": "cash", "account_id": theirs_account}),
        headers=auth,
    )
    assert r.status_code == 404
    assert (await client.get(T, headers=auth)).json() == []  # nothing half-saved


async def test_inactive_account_cannot_receive_an_advance(client, auth, seeded):
    w = await make_world(client, auth)
    await client.patch(f"/api/v1/accounts/{w['account']}", json={"is_active": False}, headers=auth)
    r = await client.post(
        T,
        json=trip_body(w, advance={"amount": "5", "mode": "cash", "account_id": w["account"]}),
        headers=auth,
    )
    assert r.status_code == 400


async def test_list_orders_newest_first_and_filters(client, auth, seeded):
    w = await make_world(client, auth)
    other_vehicle = await make_vehicle(client, auth, "Bolero", "GJ05 CD 5678")
    other_party = (await client.post("/api/v1/parties", json={"name": "Ramesh"}, headers=auth)).json()["id"]
    a = await make_trip(client, auth, w, trip_date="2026-10-28")
    b = await make_trip(client, auth, w, trip_date="2026-11-02", vehicle_id=other_vehicle)
    c = await make_trip(client, auth, w, trip_date="2026-11-09", party_id=other_party)

    async def ids(**params):
        r = await client.get(T, params=params, headers=auth)
        assert r.status_code == 200, r.text
        return [t["id"] for t in r.json()]

    assert await ids() == [c["id"], b["id"], a["id"]]
    assert await ids(month="2026-11") == [c["id"], b["id"]]
    assert await ids(month="2026-10") == [a["id"]]
    assert await ids(vehicle_id=other_vehicle) == [b["id"]]
    assert await ids(party_id=other_party) == [c["id"]]
    assert await ids(limit=1) == [c["id"]]
    assert await ids(limit=1, offset=1) == [b["id"]]
    assert (await client.get(T, params={"month": "2026-13"}, headers=auth)).status_code == 422
    assert (await client.get(T, params={"month": "nov"}, headers=auth)).status_code == 422


async def test_unpaid_only_and_status_filters(client, auth, seeded):
    w = await make_world(client, auth)
    paid = await make_trip(
        client, auth, w, trip_date="2026-11-01",
        advance={"amount": "12000", "mode": "cash", "account_id": w["account"]},
    )
    owed = await make_trip(client, auth, w, trip_date="2026-11-02")
    r = await client.get(T, params={"unpaid_only": True}, headers=auth)
    assert [t["id"] for t in r.json()] == [owed["id"]]
    await client.patch(f"{T}/{paid['id']}", json={"status": "closed"}, headers=auth)
    r = await client.get(T, params={"status": "closed"}, headers=auth)
    assert [t["id"] for t in r.json()] == [paid["id"]]


async def test_later_payment_settles_oldest_trip_first(client, auth, seeded):
    w = await make_world(client, auth)
    old = await make_trip(client, auth, w, trip_date="2026-11-01")
    new = await make_trip(client, auth, w, trip_date="2026-11-04")
    await make_payment(client, auth, w, 15000)
    by_id = {t["id"]: t for t in (await client.get(T, headers=auth)).json()}
    assert by_id[old["id"]]["pay_status"] == "paid"
    assert by_id[new["id"]]["pay_status"] == "partial" and by_id[new["id"]]["due"] == "9000.00"


async def test_get_update_and_close(client, auth, seeded):
    w = await make_world(client, auth)
    t = await make_trip(client, auth, w)
    got = await client.get(f"{T}/{t['id']}", headers=auth)
    assert got.status_code == 200 and got.json()["id"] == t["id"]
    upd = await client.patch(
        f"{T}/{t['id']}",
        json={"bhada": "13500", "to_place_id": w["valsad"], "note": "extra load", "status": "closed"},
        headers=auth,
    )
    body = upd.json()
    assert upd.status_code == 200
    assert body["bhada"] == "13500.00" and body["to_place"]["name_en"] == "Valsad"
    assert body["note"] == "extra load" and body["status"] == "closed"
    # required fields cannot be nulled by sending null
    again = await client.patch(f"{T}/{t['id']}", json={"bhada": None, "status": None}, headers=auth)
    assert again.json()["bhada"] == "13500.00" and again.json()["status"] == "closed"
    assert (await client.patch(f"{T}/{t['id']}", json={"bhada": "0"}, headers=auth)).status_code == 422


async def test_changing_the_party_moves_the_advance_with_it(client, auth, seeded):
    w = await make_world(client, auth)
    other = (await client.post("/api/v1/parties", json={"name": "Ramesh"}, headers=auth)).json()["id"]
    t = await make_trip(
        client, auth, w, advance={"amount": "5000", "mode": "cash", "account_id": w["account"]}
    )
    await client.patch(f"{T}/{t['id']}", json={"party_id": other}, headers=auth)
    pays = (await client.get(PAY, headers=auth)).json()
    assert pays[0]["party"]["id"] == other
    again = (await client.get(f"{T}/{t['id']}", headers=auth)).json()
    assert again["party"]["id"] == other and again["advance"] == "5000.00"


async def test_deleting_a_trip_keeps_its_advance_as_party_credit(client, auth, seeded):
    w = await make_world(client, auth)
    t = await make_trip(
        client, auth, w, advance={"amount": "5000", "mode": "cash", "account_id": w["account"]}
    )
    assert (await client.delete(f"{T}/{t['id']}", headers=auth)).status_code == 204
    assert (await client.get(f"{T}/{t['id']}", headers=auth)).status_code == 404
    assert (await client.get(T, headers=auth)).json() == []
    pays = (await client.get(PAY, headers=auth)).json()
    assert len(pays) == 1 and pays[0]["trip_id"] is None  # money is not lost
    led = (await client.get(f"/api/v1/ledger/parties/{w['party']}", headers=auth)).json()
    assert led["balance"] == "-5000.00"  # the party has credit with us


async def test_recent_routes_rank_by_use_and_carry_last_bhada(client, auth, seeded):
    w = await make_world(client, auth)
    await make_trip(client, auth, w, trip_date="2026-11-01", bhada="12000")
    await make_trip(client, auth, w, trip_date="2026-11-03", bhada="12500")
    await make_trip(client, auth, w, trip_date="2026-11-04", to_place_id=w["valsad"], bhada="14000")
    r = await client.get(f"{T}/routes/recent", headers=auth)
    routes = r.json()
    assert r.status_code == 200 and len(routes) == 2
    assert routes[0]["from_place"]["name_en"] == "Surat" and routes[0]["to_place"]["name_en"] == "Vapi"
    assert routes[0]["trips"] == 2 and routes[0]["last_bhada"] == "12500.00"
    assert routes[1]["to_place"]["name_en"] == "Valsad" and routes[1]["trips"] == 1


async def test_trips_require_login_and_are_company_isolated(client, auth, other_auth, seeded):
    w = await make_world(client, auth)
    t = await make_trip(client, auth, w)
    assert (await client.get(T)).status_code == 401
    assert (await client.post(T, json=trip_body(w))).status_code == 401
    assert (await client.get(T, headers=other_auth)).json() == []
    assert (await client.get(f"{T}/{t['id']}", headers=other_auth)).status_code == 404
    assert (await client.patch(f"{T}/{t['id']}", json={"note": "x"}, headers=other_auth)).status_code == 404
    assert (await client.delete(f"{T}/{t['id']}", headers=other_auth)).status_code == 404
    assert (await client.get(f"{T}/routes/recent", headers=other_auth)).json() == []
