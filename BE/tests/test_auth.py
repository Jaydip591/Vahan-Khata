from datetime import datetime, timedelta, timezone

from sqlalchemy import update

from apps.auth.models.refresh_token import RefreshToken
from core.database import AsyncSessionLocal

LOGIN = "/api/v1/auth/login"


async def test_login_success_returns_both_tokens(client):
    r = await client.post(LOGIN, json={"username": "admin", "password": "admin-pass-1"})
    assert r.status_code == 200
    body = r.json()
    assert body["token_type"] == "bearer"
    assert body["access_token"] and body["refresh_token"]
    assert body["expires_in"] > 0


async def test_login_username_is_case_insensitive(client):
    r = await client.post(LOGIN, json={"username": "  ADMIN ", "password": "admin-pass-1"})
    assert r.status_code == 200


async def test_login_wrong_password_and_unknown_user_look_identical(client):
    bad_pw = await client.post(LOGIN, json={"username": "admin", "password": "nope"})
    unknown = await client.post(LOGIN, json={"username": "ghost", "password": "nope"})
    assert bad_pw.status_code == unknown.status_code == 401
    assert bad_pw.json() == unknown.json()


async def test_me_requires_valid_access_token(client, auth):
    assert (await client.get("/api/v1/users/me")).status_code == 401
    assert (
        await client.get("/api/v1/users/me", headers={"Authorization": "Bearer junk"})
    ).status_code == 401
    me = await client.get("/api/v1/users/me", headers=auth)
    assert me.status_code == 200
    assert me.json()["username"] == "admin"
    assert "password_hash" not in me.json()


async def test_refresh_token_is_not_accepted_as_access_token(client, admin_tokens):
    r = await client.get(
        "/api/v1/users/me",
        headers={"Authorization": f"Bearer {admin_tokens['refresh_token']}"},
    )
    assert r.status_code == 401


async def test_refresh_gives_working_access_token(client, admin_tokens):
    r = await client.post(
        "/api/v1/auth/refresh", json={"refresh_token": admin_tokens["refresh_token"]}
    )
    assert r.status_code == 200
    me = await client.get(
        "/api/v1/users/me",
        headers={"Authorization": f"Bearer {r.json()['access_token']}"},
    )
    assert me.status_code == 200


async def test_refresh_extends_session(client, admin_tokens):
    soon = datetime.now(timezone.utc) + timedelta(days=1)
    async with AsyncSessionLocal() as db:
        await db.execute(update(RefreshToken).values(expires_at=soon))
        await db.commit()
    r = await client.post(
        "/api/v1/auth/refresh", json={"refresh_token": admin_tokens["refresh_token"]}
    )
    assert r.status_code == 200
    async with AsyncSessionLocal() as db:
        row = (await db.execute(RefreshToken.__table__.select())).first()
    assert row.expires_at > soon + timedelta(days=30)


async def test_expired_refresh_token_is_rejected(client, admin_tokens):
    async with AsyncSessionLocal() as db:
        await db.execute(
            update(RefreshToken).values(expires_at=datetime.now(timezone.utc) - timedelta(seconds=1))
        )
        await db.commit()
    r = await client.post(
        "/api/v1/auth/refresh", json={"refresh_token": admin_tokens["refresh_token"]}
    )
    assert r.status_code == 401


async def test_unknown_refresh_token_is_rejected(client):
    r = await client.post("/api/v1/auth/refresh", json={"refresh_token": "x" * 40})
    assert r.status_code == 401


async def test_logout_ends_session_and_is_idempotent(client, admin_tokens):
    body = {"refresh_token": admin_tokens["refresh_token"]}
    assert (await client.post("/api/v1/auth/logout", json=body)).status_code == 204
    assert (await client.post("/api/v1/auth/refresh", json=body)).status_code == 401
    assert (await client.post("/api/v1/auth/logout", json=body)).status_code == 204
    assert (
        await client.post("/api/v1/auth/logout", json={"refresh_token": "y" * 40})
    ).status_code == 204


async def test_two_devices_logout_one_keeps_other(client):
    creds = {"username": "admin", "password": "admin-pass-1"}
    a = (await client.post(LOGIN, json=creds)).json()
    b = (await client.post(LOGIN, json=creds)).json()
    await client.post("/api/v1/auth/logout", json={"refresh_token": a["refresh_token"]})
    assert (
        await client.post("/api/v1/auth/refresh", json={"refresh_token": b["refresh_token"]})
    ).status_code == 200


async def test_public_signup_is_gone(client):
    r = await client.post(
        "/api/v1/users/signup", json={"username": "evil", "password": "password1", "name": "E"}
    )
    assert r.status_code in (404, 405)
