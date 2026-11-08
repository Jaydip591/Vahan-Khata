import uuid
from decimal import Decimal

from helpers import LED, make_party, make_payment, make_trip, make_world


async def test_party_with_nothing_owes_nothing(client, auth):
    pid = await make_party(client, auth)
    r = await client.get(LED + "/parties", headers=auth)
    assert r.status_code == 200
    assert r.json()["total_due"] in ("0", "0.00") or Decimal(r.json()["total_due"]) == 0
    assert r.json()["parties"][0]["party_id"] == pid and r.json()["parties"][0]["unpaid_trips"] == 0


async def test_balance_is_bhada_minus_payments(client, auth, seeded):
    w = await make_world(client, auth)
    await make_trip(client, auth, w, bhada="12000", trip_date="2026-11-01")
    await make_trip(client, auth, w, bhada="14000", trip_date="2026-11-03")
    await make_payment(client, auth, w, "20000")
    b = (await client.get(LED + "/parties", headers=auth)).json()
    row = b["parties"][0]
    assert Decimal(row["balance"]) == 6000 and Decimal(b["total_due"]) == 6000
    assert row["unpaid_trips"] == 1 and row["oldest_unpaid_date"] == "2026-11-03"


async def test_parties_sorted_oldest_unpaid_first_then_settled(client, auth, seeded):
    w = await make_world(client, auth)
    newer = await make_party(client, auth, "Newer")
    settled = await make_party(client, auth, "Aaa Settled")
    await make_trip(client, auth, w, trip_date="2026-11-08", party_id=newer)
    await make_trip(client, auth, w, trip_date="2026-10-20")  # Khodiyar, oldest
    await make_trip(client, auth, w, trip_date="2026-11-01", party_id=settled)
    await make_payment(client, auth, w, 12000, party_id=settled)
    names = [p["party_name"] for p in (await client.get(LED + "/parties", headers=auth)).json()["parties"]]
    assert names == ["Khodiyar", "Newer", "Aaa Settled"]


async def test_party_ledger_details(client, auth, seeded):
    w = await make_world(client, auth)
    await make_trip(client, auth, w, bhada="12000", trip_date="2026-11-01")
    t2 = await make_trip(
        client, auth, w, bhada="14000", trip_date="2026-11-03", to_place_id=w["valsad"],
        advance={"amount": "4000", "mode": "cash", "account_id": w["account"]},
    )
    await make_payment(client, auth, w, "5000", paid_on="2026-11-09")
    led = (await client.get(f"{LED}/parties/{w['party']}", headers=auth)).json()
    assert led["party"]["name"] == "Khodiyar"
    assert Decimal(led["total_bhada"]) == 26000 and Decimal(led["total_paid"]) == 9000
    assert Decimal(led["balance"]) == 17000
    # newest trip first; its own advance counts for it, the 5000 settles the oldest trip
    assert [t["id"] for t in led["trips"]][0] == t2["id"]
    newest, oldest = led["trips"]
    assert Decimal(newest["paid"]) == 4000 and newest["pay_status"] == "partial"
    assert Decimal(oldest["paid"]) == 5000 and oldest["pay_status"] == "partial"
    assert newest["to_place"]["name_gu"] == "વલસાડ" and newest["vehicle_name"] == "Eicher 1"
    assert [Decimal(p["amount"]) for p in led["payments"]] == [5000, 4000]  # newest first


async def test_overpayment_gives_negative_balance(client, auth, seeded):
    w = await make_world(client, auth)
    await make_trip(client, auth, w, bhada="1000")
    await make_payment(client, auth, w, "1500")
    led = (await client.get(f"{LED}/parties/{w['party']}", headers=auth)).json()
    assert Decimal(led["balance"]) == -500 and led["trips"][0]["pay_status"] == "paid"
    b = (await client.get(LED + "/parties", headers=auth)).json()
    assert Decimal(b["total_due"]) == 0  # credit is not counted as money owed to us


async def test_deleting_a_payment_restores_the_balance(client, auth, seeded):
    w = await make_world(client, auth)
    await make_trip(client, auth, w, bhada="1000")
    p = await make_payment(client, auth, w, "1000")
    await client.delete(f"/api/v1/payments/{p['id']}", headers=auth)
    led = (await client.get(f"{LED}/parties/{w['party']}", headers=auth)).json()
    assert Decimal(led["balance"]) == 1000 and led["trips"][0]["pay_status"] == "unpaid"


async def test_ledger_is_company_isolated(client, auth, other_auth, seeded):
    w = await make_world(client, auth)
    await make_trip(client, auth, w)
    assert (await client.get(LED + "/parties")).status_code == 401
    assert (await client.get(LED + "/parties", headers=other_auth)).json()["parties"] == []
    assert (await client.get(f"{LED}/parties/{w['party']}", headers=other_auth)).status_code == 404
    assert (await client.get(f"{LED}/parties/{uuid.uuid4()}", headers=auth)).status_code == 404
