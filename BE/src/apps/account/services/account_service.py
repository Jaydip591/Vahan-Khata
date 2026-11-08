from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from apps.account.models.account import Account
from apps.account.schemas.account import AccountCreateRequest, AccountUpdateRequest
from apps.user.models.user import User
from core.crud import apply_updates, ensure_unique, get_scoped, list_scoped, soft_delete

_DUP = "An account with this name already exists."


class AccountService:
    @staticmethod
    async def list(db: AsyncSession, company_id: UUID, include_inactive: bool) -> list[Account]:
        return await list_scoped(db, Account, company_id, include_inactive=include_inactive)

    @staticmethod
    async def get(db: AsyncSession, company_id: UUID, account_id: UUID) -> Account:
        return await get_scoped(db, Account, company_id, account_id, "Account")

    @classmethod
    async def create(cls, db: AsyncSession, actor: User, payload: AccountCreateRequest) -> Account:
        await ensure_unique(db, Account, actor.company_id, Account.name, payload.name, message=_DUP)
        account = Account(company_id=actor.company_id, created_by=actor.id, **payload.model_dump())
        db.add(account)
        await db.commit()
        await db.refresh(account)
        return account

    @classmethod
    async def update(
        cls, db: AsyncSession, actor: User, account_id: UUID, payload: AccountUpdateRequest
    ) -> Account:
        account = await cls.get(db, actor.company_id, account_id)
        data = payload.model_dump(exclude_unset=True)
        for required in ("name", "kind", "opening_balance", "is_active"):
            if required in data and data[required] is None:
                del data[required]
        if "name" in data:
            await ensure_unique(
                db, Account, actor.company_id, Account.name, data["name"], exclude_id=account.id, message=_DUP
            )
        apply_updates(account, data)
        await db.commit()
        await db.refresh(account)
        return account

    @classmethod
    async def delete(cls, db: AsyncSession, company_id: UUID, account_id: UUID) -> None:
        await soft_delete(db, await cls.get(db, company_id, account_id))
