from helpers import EXP, make_vehicle

PY = "/api/v1/payees"


async def test_payee_crud_and_unique_upi(client, auth):
    r = await client.post(PY, json={"name": "Pump - Kamrej", "upi_id": " kamrejpump@okaxis "}, headers=auth)
    assert r.status_code == 201, r.text
    pid = r.json()["id"]
    assert r.json()["upi_id"] == "kamrejpump@okaxis"
    dup = await client.post(PY, json={"name": "Other", "upi_id": "KAMREJPUMP@okaxis"}, headers=auth)
    assert dup.status_code == 409
    bad = await client.post(PY, json={"name": "Bad", "upi_id": "no-at-sign"}, headers=auth)
    assert bad.status_code == 422
    r = await client.patch(f"{PY}/{pid}", json={"name": "Pump Kamrej"}, headers=auth)
    assert r.json()["name"] == "Pump Kamrej"
    assert [p["name"] for p in (await client.get(PY, headers=auth)).json()] == ["Pump Kamrej"]
    assert (await client.delete(f"{PY}/{pid}", headers=auth)).status_code == 204
    assert (await client.get(PY, headers=auth)).json() == []


async def test_payees_are_company_scoped(client, auth, other_auth):
    pid = (await client.post(PY, json={"name": "Pump", "upi_id": "pump@ybl"}, headers=auth)).json()["id"]
    assert (await client.get(PY, headers=other_auth)).json() == []
    assert (await client.get(f"{PY}/{pid}", headers=other_auth)).status_code == 404


async def test_expense_paid_by_upi_keeps_payee_and_ref(client, auth, other_auth):
    v = await make_vehicle(client, auth)
    pid = (await client.post(PY, json={"name": "Pump", "upi_id": "pump@ybl"}, headers=auth)).json()["id"]
    body = {
        "vehicle_id": v,
        "category": "diesel",
        "amount": "3000",
        "expense_date": "2026-11-10",
        "payee_id": pid,
        "upi_ref": "631234567890",
    }
    r = await client.post(EXP, json=body, headers=auth)
    assert r.status_code == 201, r.text
    assert r.json()["payee"]["name"] == "Pump" and r.json()["upi_ref"] == "631234567890"
    # someone else's payee is refused
    o = await client.post(PY, json={"name": "X", "upi_id": "x@ybl"}, headers=other_auth)
    assert o.status_code == 201, o.text
    other_pid = o.json()["id"]
    r = await client.post(EXP, json=body | {"payee_id": other_pid}, headers=auth)
    assert r.status_code == 404
