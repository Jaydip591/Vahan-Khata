import uuid
from decimal import Decimal

from helpers import EXP, LED, PAY, T, make_vehicle, make_world, trip_body


async def test_retrying_a_trip_with_the_same_id_makes_one_trip_and_one_advance(client, auth, seeded):
    w = await make_world(client, auth)
    tid = str(uuid.uuid4())
    body = trip_body(w, id=tid, advance={"amount": "5000", "mode": "cash", "account_id": w["account"]})
    first = await client.post(T, json=body, headers=auth)
    again = await client.post(T, json=body, headers=auth)
    assert first.status_code == 201 and again.status_code == 201
    assert first.json()["id"] == tid and again.json()["id"] == tid
    assert len((await client.get(T, headers=auth)).json()) == 1
    pays = (await client.get(PAY, headers=auth)).json()
    assert len(pays) == 1 and Decimal(pays[0]["amount"]) == 5000
    assert Decimal((await client.get(LED + "/parties", headers=auth)).json()["total_due"]) == 7000


async def test_retrying_a_payment_makes_one_payment(client, auth, seeded):
    w = await make_world(client, auth)
    pid = str(uuid.uuid4())
    body = {"id": pid, "party_id": w["party"], "amount": "800", "mode": "online",
            "account_id": w["account"], "paid_on": "2026-11-10"}
    assert (await client.post(PAY, json=body, headers=auth)).status_code == 201
    assert (await client.post(PAY, json=body, headers=auth)).json()["id"] == pid
    assert len((await client.get(PAY, headers=auth)).json()) == 1


async def test_retrying_an_expense_makes_one_expense(client, auth):
    v = await make_vehicle(client, auth)
    eid = str(uuid.uuid4())
    body = {"id": eid, "vehicle_id": v, "category": "diesel", "amount": "5000", "expense_date": "2026-11-06",
            "liters": "50", "odometer": 1000}
    assert (await client.post(EXP, json=body, headers=auth)).status_code == 201
    r = await client.post(EXP, json=body, headers=auth)
    assert r.status_code == 201 and r.json()["id"] == eid
    assert len((await client.get(EXP, headers=auth)).json()) == 1


async def test_without_an_id_every_post_is_new(client, auth):
    v = await make_vehicle(client, auth)
    body = {"vehicle_id": v, "category": "toll", "amount": "300", "expense_date": "2026-11-06"}
    await client.post(EXP, json=body, headers=auth)
    await client.post(EXP, json=body, headers=auth)
    assert len((await client.get(EXP, headers=auth)).json()) == 2


async def test_an_id_from_another_company_is_refused(client, auth, other_auth, seeded):
    w = await make_world(client, auth)
    tid = str(uuid.uuid4())
    assert (await client.post(T, json=trip_body(w, id=tid), headers=auth)).status_code == 201
    r = await client.post(T, json=trip_body(w, id=tid), headers=other_auth)
    assert r.status_code == 409
