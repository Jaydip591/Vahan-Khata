from decimal import Decimal

from helpers import EXP, make_account, make_party, make_payment, make_trip, make_vehicle, make_world

R = "/api/v1/reports"


async def spend(client, auth, vehicle, amount, day="2026-11-06", **over):
    body = {"vehicle_id": vehicle, "category": "toll", "amount": str(amount), "expense_date": day} | over
    r = await client.post(EXP, json=body, headers=auth)
    assert r.status_code == 201, r.text


async def test_summary_matches_hand_calculation(client, auth, seeded):
    w = await make_world(client, auth)
    await make_trip(client, auth, w, bhada="12000", trip_date="2026-11-01")
    await make_trip(client, auth, w, bhada="8000", trip_date="2026-11-20")
    await make_trip(client, auth, w, bhada="5000", trip_date="2026-10-15")
    await spend(client, auth, w["vehicle"], 1500)
    await spend(client, auth, w["vehicle"], 700, day="2026-10-20")
    await make_payment(client, auth, w, "9000", paid_on="2026-11-10")
    s = (await client.get(R + "/summary", params={"month": "2026-11"}, headers=auth)).json()
    assert Decimal(s["income"]) == 20000 and Decimal(s["expense"]) == 1500
    assert Decimal(s["profit"]) == 18500 and s["trips"] == 2
    assert Decimal(s["collected"]) == 9000
    assert Decimal(s["total_due"]) == 16000  # 25000 bhada - 9000 paid
    assert Decimal(s["prev_profit"]) == 4300  # 5000 - 700


async def test_empty_month_is_all_zero(client, auth):
    s = (await client.get(R + "/summary", params={"month": "2026-01"}, headers=auth)).json()
    assert Decimal(s["profit"]) == 0 and s["trips"] == 0


async def test_bad_month_is_rejected(client, auth):
    assert (await client.get(R + "/summary", params={"month": "nov"}, headers=auth)).status_code == 422


async def test_vehicle_report_profit(client, auth, seeded):
    w = await make_world(client, auth)
    other = await make_vehicle(client, auth, "Tempo 2", "GJ05 CD 5678")
    await make_trip(client, auth, w, bhada="10000")
    await make_trip(client, auth, w, bhada="6000", vehicle_id=other)
    await spend(client, auth, w["vehicle"], 4000)
    await spend(client, auth, other, 500)
    rows = (await client.get(R + "/vehicles", params={"month": "2026-11"}, headers=auth)).json()["vehicles"]
    by = {r["name"]: r for r in rows}
    assert Decimal(by["Eicher 1"]["profit"]) == 6000 and Decimal(by["Tempo 2"]["profit"]) == 5500
    assert by["Eicher 1"]["trips"] == 1 and Decimal(by["Eicher 1"]["expense"]) == 4000


async def test_vehicle_report_sorted_by_profit(client, auth, seeded):
    w = await make_world(client, auth)
    other = await make_vehicle(client, auth, "Tempo 2", "GJ05 CD 5678")
    await make_trip(client, auth, w, bhada="10000")
    await make_trip(client, auth, w, bhada="6000", vehicle_id=other)
    rows = (await client.get(R + "/vehicles", params={"month": "2026-11"}, headers=auth)).json()["vehicles"]
    assert [r["name"] for r in rows] == ["Eicher 1", "Tempo 2"]


async def test_mileage_from_diesel_odometer(client, auth):
    v = await make_vehicle(client, auth)
    await spend(client, auth, v, 5000, "2026-11-01", category="diesel", liters="50", rate="100", odometer=1000)
    await spend(client, auth, v, 4000, "2026-11-10", category="diesel", liters="40", rate="100", odometer=1300)
    await spend(client, auth, v, 4000, "2026-11-20", category="diesel", liters="40", rate="100", odometer=1600)
    row = (await client.get(R + "/vehicles", params={"month": "2026-11"}, headers=auth)).json()["vehicles"][0]
    # 600 km over the 80 liters burned after the first fill
    assert row["km"] == 600 and Decimal(row["mileage"]) == Decimal("7.5")
    assert [(f["category"], Decimal(f["quantity"]), f["entries"]) for f in row["fuels"]] == [("diesel", 130, 3)]


async def test_mileage_needs_two_readings(client, auth):
    v = await make_vehicle(client, auth)
    await spend(client, auth, v, 5000, category="diesel", liters="50", odometer=1000)
    row = (await client.get(R + "/vehicles", params={"month": "2026-11"}, headers=auth)).json()["vehicles"][0]
    assert row["km"] is None and row["mileage"] is None


async def test_party_report(client, auth, seeded):
    w = await make_world(client, auth)
    quiet = await make_party(client, auth, "Quiet")
    await make_trip(client, auth, w, bhada="12000")
    await make_payment(client, auth, w, "5000")
    rows = (await client.get(R + "/parties", params={"month": "2026-11"}, headers=auth)).json()["parties"]
    assert [r["name"] for r in rows] == ["Khodiyar"]  # Quiet has nothing, so it is left out
    assert quiet not in [r["party_id"] for r in rows]
    r = rows[0]
    assert Decimal(r["bhada"]) == 12000 and Decimal(r["received"]) == 5000 and Decimal(r["balance"]) == 7000


async def test_trend_covers_months_in_order(client, auth, seeded):
    w = await make_world(client, auth)
    await make_trip(client, auth, w, bhada="1000", trip_date="2026-09-05")
    await make_trip(client, auth, w, bhada="3000", trip_date="2026-11-05")
    await spend(client, auth, w["vehicle"], 400, day="2026-11-06")
    pts = (await client.get(R + "/trend", params={"month": "2026-11", "months": 4}, headers=auth)).json()["points"]
    assert [p["month"] for p in pts] == ["2026-08", "2026-09", "2026-10", "2026-11"]
    assert [Decimal(p["profit"]) for p in pts] == [0, 1000, 0, 2600]


async def test_trend_crosses_year_boundary(client, auth):
    pts = (await client.get(R + "/trend", params={"month": "2026-02", "months": 3}, headers=auth)).json()["points"]
    assert [p["month"] for p in pts] == ["2025-12", "2026-01", "2026-02"]


async def test_expense_report_by_category(client, auth):
    v = await make_vehicle(client, auth)
    v2 = await make_vehicle(client, auth, "Tempo 2", "GJ05 CD 5678")
    await spend(client, auth, v, 5000, category="diesel", liters="50")
    await spend(client, auth, v, 300)
    await spend(client, auth, v, 200)
    await spend(client, auth, v2, 1000, category="repair")
    r = (await client.get(R + "/expenses", params={"month": "2026-11"}, headers=auth)).json()
    assert Decimal(r["total"]) == 6500
    assert [(c["category"], Decimal(c["amount"]), c["count"]) for c in r["categories"]] == [
        ("diesel", 5000, 1), ("repair", 1000, 1), ("toll", 500, 2)]
    one = (await client.get(R + "/expenses", params={"month": "2026-11", "vehicle_id": v2}, headers=auth)).json()
    assert Decimal(one["total"]) == 1000


async def test_reports_are_company_isolated(client, auth, other_auth, seeded):
    w = await make_world(client, auth)
    await make_trip(client, auth, w, bhada="9000")
    await spend(client, auth, w["vehicle"], 100)
    s = (await client.get(R + "/summary", params={"month": "2026-11"}, headers=other_auth)).json()
    assert Decimal(s["income"]) == 0 and Decimal(s["expense"]) == 0 and Decimal(s["total_due"]) == 0
    assert (await client.get(R + "/vehicles", params={"month": "2026-11"}, headers=other_auth)).json()["vehicles"] == []
    assert (await client.get(R + "/parties", params={"month": "2026-11"}, headers=other_auth)).json()["parties"] == []


async def test_reports_need_login(client):
    assert (await client.get(R + "/summary")).status_code in (401, 403)


async def test_cng_and_petrol_are_fuel_too(client, auth):
    v = await make_vehicle(client, auth)
    await spend(client, auth, v, 800, "2026-11-01", category="cng", liters="10", odometer=2000)
    await spend(client, auth, v, 1000, "2026-11-10", category="cng", liters="12", odometer=2120)
    row = (await client.get(R + "/vehicles", params={"month": "2026-11"}, headers=auth)).json()["vehicles"][0]
    assert row["km"] == 120 and Decimal(row["mileage"]) == 10  # 120 km on the 12 kg of the second fill
    assert [(f["category"], Decimal(f["amount"])) for f in row["fuels"]] == [("cng", 1800)]


async def test_two_fuels_give_totals_but_no_mileage(client, auth):
    v = await make_vehicle(client, auth)
    await spend(client, auth, v, 800, "2026-11-01", category="cng", liters="10", odometer=2000)
    await spend(client, auth, v, 1000, "2026-11-05", category="petrol", liters="10", odometer=2100)
    await spend(client, auth, v, 900, "2026-11-10", category="cng", liters="11", odometer=2200)
    row = (await client.get(R + "/vehicles", params={"month": "2026-11"}, headers=auth)).json()["vehicles"][0]
    assert row["km"] == 200 and row["mileage"] is None
    assert [(f["category"], Decimal(f["amount"]), f["entries"]) for f in row["fuels"]] == [
        ("cng", 1700, 2), ("petrol", 1000, 1)]


async def test_account_balances(client, auth, seeded):
    w = await make_world(client, auth)  # "Cash - Jaydip", opening 0
    bank = (
        await client.post(
            "/api/v1/accounts", json={"name": "Bank - SBI", "kind": "bank", "opening_balance": "10000"}, headers=auth
        )
    ).json()["id"]
    await make_trip(client, auth, w, bhada="12000")
    await make_payment(client, auth, w, "5000")
    await make_payment(client, auth, w, "3000", account_id=bank)
    await spend(client, auth, w["vehicle"], 1200, account_id=w["account"])
    await spend(client, auth, w["vehicle"], 2000, account_id=bank)
    await spend(client, auth, w["vehicle"], 400)  # no account
    r = (await client.get(R + "/accounts", headers=auth)).json()
    by = {a["name"]: a for a in r["accounts"]}
    assert Decimal(by["Cash - Jaydip"]["balance"]) == 3800  # 0 + 5000 - 1200
    assert Decimal(by["Bank - SBI"]["balance"]) == 11000  # 10000 + 3000 - 2000
    assert Decimal(by["Bank - SBI"]["received"]) == 3000 and Decimal(by["Bank - SBI"]["spent"]) == 2000
    assert Decimal(r["total"]) == 14800 and Decimal(r["unassigned_spent"]) == 400
    assert [a["name"] for a in r["accounts"]] == ["Bank - SBI", "Cash - Jaydip"]


async def test_account_balances_company_scoped(client, auth, other_auth):
    await make_account(client, auth)
    r = (await client.get(R + "/accounts", headers=other_auth)).json()
    assert r["accounts"] == [] and Decimal(r["total"]) == 0
