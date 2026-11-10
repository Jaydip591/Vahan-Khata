import uuid

from sqlalchemy import select

from apps.company.models.company import Company
from apps.user.models.user import User
from core.database import AsyncSessionLocal
from core.security import hash_password

USERS = "/api/v1/users"
LOGIN = "/api/v1/auth/login"


async def _create(client, auth, **over):
    body = {"username": "ramesh", "password": "secret12", "name": "Ramesh"} | over
    return await client.post(USERS, json=body, headers=auth)


async def test_admin_creates_user_who_can_log_in(client, auth):
    r = await _create(client, auth)
    assert r.status_code == 201
    assert r.json()["username"] == "ramesh"
    assert r.json()["role"] == "superadmin"
    login = await client.post(LOGIN, json={"username": "Ramesh", "password": "secret12"})
    assert login.status_code == 200


async def test_create_user_requires_login(client):
    r = await client.post(USERS, json={"username": "abc", "password": "secret12", "name": "A"})
    assert r.status_code == 401


async def test_duplicate_username_conflicts(client, auth):
    await _create(client, auth)
    assert (await _create(client, auth, username="RAMESH")).status_code == 409


async def test_username_and_password_validation(client, auth):
    assert (await _create(client, auth, username="a b")).status_code == 422
    assert (await _create(client, auth, username="ab")).status_code == 422
    assert (await _create(client, auth, password="123")).status_code == 422
    # 30 Gujarati characters are > 72 bytes in UTF-8
    assert (await _create(client, auth, password="ક" * 30)).status_code == 422


async def test_list_users(client, auth):
    await _create(client, auth)
    r = await client.get(USERS, headers=auth)
    assert r.status_code == 200
    assert {u["username"] for u in r.json()} == {"admin", "ramesh"}


async def test_deactivating_user_kills_sessions(client, auth):
    uid = (await _create(client, auth)).json()["id"]
    tokens = (await client.post(LOGIN, json={"username": "ramesh", "password": "secret12"})).json()
    r = await client.patch(f"{USERS}/{uid}", json={"is_active": False}, headers=auth)
    assert r.status_code == 200 and r.json()["is_active"] is False
    me = await client.get(USERS + "/me", headers={"Authorization": f"Bearer {tokens['access_token']}"})
    assert me.status_code == 401
    assert (
        await client.post("/api/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    ).status_code == 401
    assert (
        await client.post(LOGIN, json={"username": "ramesh", "password": "secret12"})
    ).status_code == 403


async def test_admin_cannot_deactivate_self(client, auth):
    me = (await client.get(USERS + "/me", headers=auth)).json()
    r = await client.patch(f"{USERS}/{me['id']}", json={"is_active": False}, headers=auth)
    assert r.status_code == 400


async def test_password_reset_by_admin_logs_user_out_everywhere(client, auth):
    uid = (await _create(client, auth)).json()["id"]
    tokens = (await client.post(LOGIN, json={"username": "ramesh", "password": "secret12"})).json()
    await client.patch(f"{USERS}/{uid}", json={"password": "newsecret1"}, headers=auth)
    assert (
        await client.post("/api/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    ).status_code == 401
    assert (
        await client.post(LOGIN, json={"username": "ramesh", "password": "newsecret1"})
    ).status_code == 200


async def test_changing_own_password_keeps_own_session(client, auth, admin_tokens):
    me = (await client.get(USERS + "/me", headers=auth)).json()
    await client.patch(f"{USERS}/{me['id']}", json={"password": "another-pass"}, headers=auth)
    assert (
        await client.post(
            "/api/v1/auth/refresh", json={"refresh_token": admin_tokens["refresh_token"]}
        )
    ).status_code == 200


async def test_company_isolation(client, auth):
    async with AsyncSessionLocal() as db:
        other = Company(name="Other Co")
        db.add(other)
        await db.flush()
        stranger = User(
            company_id=other.id,
            username="stranger",
            password_hash=hash_password("strangerpass"),
            name="Stranger",
        )
        db.add(stranger)
        await db.commit()
        stranger_id = stranger.id

    listed = (await client.get(USERS, headers=auth)).json()
    assert "stranger" not in {u["username"] for u in listed}
    assert (
        await client.patch(f"{USERS}/{stranger_id}", json={"name": "Hacked"}, headers=auth)
    ).status_code == 404
    assert (
        await client.patch(f"{USERS}/{uuid.uuid4()}", json={"name": "X"}, headers=auth)
    ).status_code == 404
    async with AsyncSessionLocal() as db:
        s = (await db.execute(select(User).where(User.username == "stranger"))).scalar_one()
        assert s.name == "Stranger"


async def test_me_has_company_and_phone(client, auth):
    r = await client.get("/api/v1/users/me", headers=auth)
    assert r.status_code == 200
    assert r.json()["company_name"] == "Test Transport" and r.json()["phone"] is None


async def test_edit_own_profile(client, auth):
    r = await client.patch("/api/v1/users/me", json={"name": "Jaydip", "phone": "98250 12345"}, headers=auth)
    assert r.status_code == 200, r.text
    assert r.json()["name"] == "Jaydip" and r.json()["phone"] == "9825012345"
    r = await client.patch("/api/v1/users/me", json={"phone": ""}, headers=auth)
    assert r.json()["phone"] is None and r.json()["name"] == "Jaydip"
    assert (await client.patch("/api/v1/users/me", json={"phone": "12ab"}, headers=auth)).status_code == 422


async def test_change_password(client, auth, admin_tokens):
    url = "/api/v1/auth/change-password"
    bad = await client.post(url, json={"old_password": "nope", "new_password": "new-pass-1"}, headers=auth)
    assert bad.status_code == 400
    r = await client.post(url, json={"old_password": "admin-pass-1", "new_password": "new-pass-1"}, headers=auth)
    assert r.status_code == 200, r.text
    fresh = r.json()
    # the old session (other phones) is logged out, the new one works
    old = await client.post("/api/v1/auth/refresh", json={"refresh_token": admin_tokens["refresh_token"]})
    assert old.status_code == 401
    ok = await client.post("/api/v1/auth/refresh", json={"refresh_token": fresh["refresh_token"]})
    assert ok.status_code == 200
    login_old = await client.post("/api/v1/auth/login", json={"username": "admin", "password": "admin-pass-1"})
    assert login_old.status_code == 401
    login_new = await client.post("/api/v1/auth/login", json={"username": "admin", "password": "new-pass-1"})
    assert login_new.status_code == 200


async def test_short_new_password_rejected(client, auth):
    r = await client.post(
        "/api/v1/auth/change-password", json={"old_password": "admin-pass-1", "new_password": "123"}, headers=auth
    )
    assert r.status_code == 422
